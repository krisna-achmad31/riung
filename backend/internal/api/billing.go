package api

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// Billing log events (docs/backend-api-spec.md §6.4).
const (
	eventPurchaseVerified = "purchase_verified"
	eventPurchaseRejected = "purchase_rejected"
	eventRTDNReceived     = "rtdn_received"
	eventRTDNRejected     = "rtdn_rejected"
	eventRefundApplied    = "refund_applied"
)

// maxRestoreItems caps POST /v1/billing/restore.
const maxRestoreItems = 20

// restoreBudget keeps a restore inside the server's 15 s write timeout; the
// app retries a 503 and already-verified tokens answer from the database.
const restoreBudget = 12 * time.Second

var tokenPattern = regexp.MustCompile(`^[A-Za-z0-9._:-]{10,512}$`)

func tokenTail(t string) string {
	if len(t) <= 6 {
		return t
	}
	return t[len(t)-6:]
}

var (
	errPurchaseInvalid = httpx.NewError(http.StatusConflict, httpx.CodePurchaseInvalid, "Google Play does not confirm this purchase for your account")
	errBillingOff      = httpx.NewError(http.StatusServiceUnavailable, httpx.CodeUnavailable, "billing is not available right now")
	errWebhookLimited  = httpx.NewError(http.StatusTooManyRequests, httpx.CodeRateLimited, "too many requests")
)

func (s *Server) billingError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, billing.ErrInvalidPurchase):
		httpx.WriteError(w, r, errPurchaseInvalid)
	case errors.Is(err, billing.ErrUnknownProduct):
		httpx.WriteError(w, r, invalid("unknown productId", "productId"))
	case errors.Is(err, billing.ErrNotConfigured):
		httpx.WriteError(w, r, errBillingOff)
	case errors.Is(err, billing.ErrAppStoreUnavailable):
		s.Logger.LogAttrs(r.Context(), slog.LevelError, "app store unavailable",
			slog.String(logx.KeyEvent, logx.EventDependencyError),
			slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
			slog.String("dependency", "app_store"), slog.String("error", err.Error()))
		httpx.WriteError(w, r, httpx.ErrUnavailable)
	case errors.Is(err, billing.ErrPlayUnavailable), errors.Is(err, context.DeadlineExceeded):
		s.Logger.LogAttrs(r.Context(), slog.LevelError, "google play unavailable",
			slog.String(logx.KeyEvent, logx.EventDependencyError),
			slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
			slog.String("dependency", "google_play"), slog.String("error", err.Error()))
		httpx.WriteError(w, r, httpx.ErrUnavailable)
	default:
		s.internalError(w, r, "billing", err)
	}
}

type purchaseRef struct {
	ProductID     string `json:"productId"`
	PurchaseToken string `json:"purchaseToken"`
}

func (p purchaseRef) valid() bool {
	return idPatternAPI.MatchString(p.ProductID) && tokenPattern.MatchString(p.PurchaseToken)
}

var idPatternAPI = regexp.MustCompile(`^[a-z0-9_.]{1,64}$`)

func (s *Server) logPurchase(r *http.Request, userID string, ref purchaseRef, res billing.Result, err error) {
	attrs := []slog.Attr{
		slog.String(logx.KeyUser, s.Hasher.User(userID)),
		slog.String("productId", ref.ProductID),
		slog.String("tokenTail", tokenTail(ref.PurchaseToken)),
	}
	if err != nil {
		reason := "error"
		switch {
		case errors.Is(err, billing.ErrInvalidPurchase):
			reason = "not_valid_for_account"
		case errors.Is(err, billing.ErrUnknownProduct):
			reason = "unknown_product"
		case errors.Is(err, billing.ErrNotConfigured), errors.Is(err, billing.ErrPlayUnavailable),
			errors.Is(err, billing.ErrAppStoreUnavailable):
			return // logged as dependency errors
		}
		s.logWarn(r, eventPurchaseRejected, "purchase rejected", append(attrs, slog.String("reason", reason))...)
		return
	}
	s.logInfo(r, eventPurchaseVerified, "purchase verified", append(attrs,
		slog.String("status", res.Status), slog.Int("coins", res.CoinsGranted), slog.Bool("test", res.Test))...)
	if res.CoinsGranted > 0 {
		s.logInfo(r, eventWalletMutation, "coins credited", slog.String(logx.KeyUser, s.Hasher.User(userID)),
			slog.String("type", "purchase"), slog.String("kind", ref.ProductID), slog.Int("amount", res.CoinsGranted))
	}
}

// --- POST /v1/billing/verify ---------------------------------------------------------

func (s *Server) postBillingVerify(w http.ResponseWriter, r *http.Request) {
	var ref purchaseRef
	if apiErr := httpx.DecodeJSON(r, &ref); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if !ref.valid() {
		httpx.WriteError(w, r, invalid("productId and purchaseToken are required", "productId", "purchaseToken"))
		return
	}
	c := callerFrom(r.Context())
	res, wallet, err := s.billingSvc.Verify(r.Context(), *c.User, ref.ProductID, ref.PurchaseToken)
	s.logPurchase(r, c.User.ID, ref, res, err)
	if err != nil {
		s.billingError(w, r, err)
		return
	}
	sub, err := s.billingSvc.Subscription(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "subscription", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"result": res, "wallet": walletOut(wallet), "premium": s.premiumJSON(sub, s.now()),
	})
}

// --- POST /v1/billing/restore --------------------------------------------------------

type restoreRequest struct {
	Purchases []purchaseRef `json:"purchases"`
}

// restoreItem is one row of POST /v1/billing/restore, in request order. It
// echoes the purchaseToken so the app matches rows by token, not position.
type restoreItem struct {
	ProductID     string          `json:"productId"`
	PurchaseToken string          `json:"purchaseToken"`
	OK            bool            `json:"ok"`
	Result        *billing.Result `json:"result,omitempty"`
	Error         *batchError     `json:"error,omitempty"`
}

func (s *Server) postBillingRestore(w http.ResponseWriter, r *http.Request) {
	var req restoreRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(req.Purchases) == 0 || len(req.Purchases) > maxRestoreItems {
		httpx.WriteError(w, r, invalid("purchases must contain 1–20 items", "purchases"))
		return
	}
	c := callerFrom(r.Context())
	ctx, cancel := context.WithTimeout(r.Context(), restoreBudget)
	defer cancel()
	items := make([]restoreItem, 0, len(req.Purchases))
	for _, ref := range req.Purchases {
		if !ref.valid() {
			items = append(items, restoreItem{ProductID: ref.ProductID, PurchaseToken: ref.PurchaseToken, Error: &batchError{Code: httpx.CodeInvalidRequest, Message: "invalid purchase reference"}})
			continue
		}
		res, _, err := s.billingSvc.Verify(ctx, *c.User, ref.ProductID, ref.PurchaseToken)
		s.logPurchase(r, c.User.ID, ref, res, err)
		switch {
		case err == nil:
			items = append(items, restoreItem{ProductID: ref.ProductID, PurchaseToken: ref.PurchaseToken, OK: true, Result: &res})
		case errors.Is(err, billing.ErrInvalidPurchase):
			items = append(items, restoreItem{ProductID: ref.ProductID, PurchaseToken: ref.PurchaseToken, Error: &batchError{Code: httpx.CodePurchaseInvalid, Message: "not confirmed by Google Play"}})
		case errors.Is(err, billing.ErrUnknownProduct):
			items = append(items, restoreItem{ProductID: ref.ProductID, PurchaseToken: ref.PurchaseToken, Error: &batchError{Code: httpx.CodeInvalidRequest, Message: "unknown product"}})
		default:
			s.billingError(w, r, err) // Play/DB down: let the app retry the whole restore
			return
		}
	}
	wallet, err := s.Store.Wallet(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "wallet", err)
		return
	}
	sub, err := s.billingSvc.Subscription(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "subscription", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"results": items, "wallet": walletOut(wallet), "premium": s.premiumJSON(sub, s.now())})
}

// --- GET /v1/billing/subscription -----------------------------------------------------

func (s *Server) getSubscription(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	sub, err := s.billingSvc.Subscription(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "subscription", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"premium": s.premiumJSON(sub, s.now())})
}

// --- POST /v1/webhooks/google-play -----------------------------------------------------

// postPlayWebhook receives RTDN pushes. Answers: 204 handled, duplicate, or
// undecodable (a retry would never succeed, so it is acknowledged and logged),
// 401 bad push token, 429/503/500 transient failure so Pub/Sub retries.
func (s *Server) postPlayWebhook(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	// Per source IP before authentication, global after it: unauthenticated
	// floods cannot use up the budget of Google's (many-IP) pushes.
	if ok, _ := s.Limiter.Allow(rlWebhookIP, s.Hasher.IP(httpx.ClientIPFrom(ctx), s.now())); !ok {
		httpx.WriteError(w, r, errWebhookLimited)
		return
	}
	if s.Push == nil || !s.Config.BillingEnabled() || s.billingSvc.Publisher == nil {
		// No Pub/Sub subscription exists while billing is off: answer like a
		// missing route, not 503 — a public 5xx would let anyone fill the logs
		// with ERROR lines (and trip the server-error alert).
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	if err := s.Push.Verify(ctx, bearerToken(r)); err != nil {
		s.logWarn(r, eventRTDNRejected, "rtdn push rejected", slog.String("reason", "auth"))
		httpx.WriteError(w, r, errUnauthenticated)
		return
	}
	if ok, _ := s.Limiter.Allow(rlWebhook, "global"); !ok {
		s.logWarn(r, logx.EventRateLimited, "rate limited", slog.String("limit", rlWebhook.Name), slog.String("scope", "global"))
		httpx.WriteError(w, r, errWebhookLimited)
		return
	}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		httpx.WriteError(w, r, httpx.NewError(http.StatusRequestEntityTooLarge, httpx.CodePayloadTooLarge, "body too large"))
		return
	}
	var env billing.PushEnvelope
	// Lenient on purpose: Pub/Sub adds fields (attributes, publishTime, …).
	if err := json.Unmarshal(body, &env); err != nil {
		s.logWarn(r, eventRTDNRejected, "rtdn push undecodable", slog.String("reason", "envelope"))
		w.WriteHeader(http.StatusNoContent)
		return
	}
	n, err := billing.DecodePush(env)
	if err != nil {
		s.logWarn(r, eventRTDNRejected, "rtdn push undecodable", slog.String("reason", "notification"))
		w.WriteHeader(http.StatusNoContent)
		return
	}
	seen, err := s.Store.SeenRTDN(ctx, env.Message.MessageID)
	if err != nil {
		s.internalError(w, r, "rtdn_dedupe", err)
		return
	}
	if seen {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	// Unless processing completes, forget the id (also on panic or a dropped
	// connection) so Pub/Sub's retry runs it again.
	done := false
	defer func() {
		if !done {
			_ = s.Store.ForgetRTDN(context.WithoutCancel(ctx), env.Message.MessageID)
		}
	}()
	out, err := s.billingSvc.HandleNotification(ctx, n, s.Config.PlayPackageName)
	if err != nil {
		s.billingError(w, r, err)
		return
	}
	done = true
	s.logInfo(r, eventRTDNReceived, "rtdn processed", slog.String("kind", out.Kind),
		slog.Int("notificationType", out.Type), slog.String("productId", out.ProductID),
		slog.String("action", strings.SplitN(out.Action, ":", 2)[0]))
	if rf := out.Refund; rf != nil {
		s.logWarn(r, eventRefundApplied, "refund applied", slog.String(logx.KeyUser, rf.UserHash),
			slog.String("productId", rf.ProductID), slog.Int("coinsClawedBack", rf.Clawed), slog.Int("debt", rf.Debt),
			slog.Bool("premiumRevoked", rf.Revoked), slog.Bool("orphan", rf.WasOrphan))
	}
	w.WriteHeader(http.StatusNoContent)
}
