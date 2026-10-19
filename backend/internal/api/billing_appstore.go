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

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// App Store (iOS) billing: docs/backend-api-spec.md §3.9b. Same results as
// Google Play; the app sends the StoreKit transactionId and the server asks
// Apple (App Store Server API) for the signed transaction.

// transactionPattern: Apple ids are numeric; the dev fake also accepts
// dev-coin:/dev-sub: ids.
var transactionPattern = regexp.MustCompile(`^[A-Za-z0-9._:-]{1,200}$`)

type appStoreRef struct {
	ProductID     string `json:"productId"`
	TransactionID string `json:"transactionId"`
}

func (a appStoreRef) valid() bool {
	return idPatternAPI.MatchString(a.ProductID) && transactionPattern.MatchString(a.TransactionID)
}

// asRef lets logPurchase log the transaction like a Play token (last 6 characters only).
func (a appStoreRef) asRef() purchaseRef {
	return purchaseRef{ProductID: a.ProductID, PurchaseToken: a.TransactionID}
}

// --- POST /v1/billing/appstore/verify ------------------------------------------------

func (s *Server) postAppStoreVerify(w http.ResponseWriter, r *http.Request) {
	var ref appStoreRef
	if apiErr := httpx.DecodeJSON(r, &ref); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if !ref.valid() {
		httpx.WriteError(w, r, invalid("productId and transactionId are required", "productId", "transactionId"))
		return
	}
	c := callerFrom(r.Context())
	res, wallet, err := s.billingSvc.VerifyAppStore(r.Context(), *c.User, ref.ProductID, ref.TransactionID)
	s.logPurchase(r, c.User.ID, ref.asRef(), res, err)
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

// --- POST /v1/billing/appstore/restore -----------------------------------------------

type appStoreRestoreRequest struct {
	Purchases []appStoreRef `json:"purchases"`
}

// appStoreRestoreItem is one row of the answer, in request order; the app
// matches rows by transactionId.
type appStoreRestoreItem struct {
	ProductID     string          `json:"productId"`
	TransactionID string          `json:"transactionId"`
	OK            bool            `json:"ok"`
	Result        *billing.Result `json:"result,omitempty"`
	Error         *batchError     `json:"error,omitempty"`
}

func (s *Server) postAppStoreRestore(w http.ResponseWriter, r *http.Request) {
	var req appStoreRestoreRequest
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
	items := make([]appStoreRestoreItem, 0, len(req.Purchases))
	for _, ref := range req.Purchases {
		item := appStoreRestoreItem{ProductID: ref.ProductID, TransactionID: ref.TransactionID}
		if !ref.valid() {
			item.Error = &batchError{Code: httpx.CodeInvalidRequest, Message: "invalid transaction reference"}
			items = append(items, item)
			continue
		}
		res, _, err := s.billingSvc.VerifyAppStore(ctx, *c.User, ref.ProductID, ref.TransactionID)
		s.logPurchase(r, c.User.ID, ref.asRef(), res, err)
		switch {
		case err == nil:
			item.OK, item.Result = true, &res
		case errors.Is(err, billing.ErrInvalidPurchase):
			item.Error = &batchError{Code: httpx.CodePurchaseInvalid, Message: "not confirmed by the App Store"}
		case errors.Is(err, billing.ErrUnknownProduct):
			item.Error = &batchError{Code: httpx.CodeInvalidRequest, Message: "unknown product"}
		default:
			s.billingError(w, r, err) // Apple/DB down: let the app retry the whole restore
			return
		}
		items = append(items, item)
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

// --- POST /v1/webhooks/app-store -------------------------------------------------------

// postAppStoreWebhook receives App Store Server Notifications V2 (production
// and sandbox URL in App Store Connect). Answers: 200 handled, duplicate or
// for another app; 400 not signed by Apple; 429/503/500 transient failure,
// so Apple retries (five times over about three days). 404 while App Store
// billing is off, like the Play webhook.
func (s *Server) postAppStoreWebhook(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	if ok, _ := s.Limiter.Allow(rlAppStoreWebhookIP, s.Hasher.IP(httpx.ClientIPFrom(ctx), s.now())); !ok {
		httpx.WriteError(w, r, errWebhookLimited)
		return
	}
	if !s.Config.AppStoreEnabled() || s.billingSvc.AppStore == nil {
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	if ok, _ := s.Limiter.Allow(rlAppStoreWebhook, "global"); !ok {
		s.logWarn(r, logx.EventRateLimited, "rate limited", slog.String("limit", rlAppStoreWebhook.Name), slog.String("scope", "global"))
		httpx.WriteError(w, r, errWebhookLimited)
		return
	}
	body, err := io.ReadAll(r.Body)
	if err != nil {
		httpx.WriteError(w, r, httpx.NewError(http.StatusRequestEntityTooLarge, httpx.CodePayloadTooLarge, "body too large"))
		return
	}
	reject := func(reason string) {
		s.logWarn(r, eventRTDNRejected, "app store notification rejected", slog.String("store", "app_store"), slog.String("reason", reason))
		httpx.WriteError(w, r, invalid("not a signed App Store notification", "signedPayload"))
	}
	var env struct {
		SignedPayload string `json:"signedPayload"`
	}
	if err := json.Unmarshal(body, &env); err != nil || env.SignedPayload == "" {
		reject("envelope")
		return
	}
	var ev billing.AppStoreEvent
	if err := s.appStoreJWS.Decode(env.SignedPayload, &ev.Notification); err != nil || ev.Notification.NotificationUUID == "" {
		reject("signature")
		return
	}
	if d := ev.Notification.Data; d != nil {
		if d.SignedTransactionInfo != "" {
			var t appstore.Transaction
			if err := s.appStoreJWS.Decode(d.SignedTransactionInfo, &t); err != nil {
				reject("transaction_signature")
				return
			}
			ev.Transaction = &t
		}
		if d.SignedRenewalInfo != "" {
			var ri appstore.RenewalInfo
			if err := s.appStoreJWS.Decode(d.SignedRenewalInfo, &ri); err != nil {
				reject("renewal_signature")
				return
			}
			ev.Renewal = &ri
		}
		if id := s.Config.AppStoreAppAppleID; id != 0 && d.Environment == appstore.EnvProduction && d.AppAppleID != id {
			s.logInfo(r, eventRTDNReceived, "app store notification ignored", slog.String("store", "app_store"),
				slog.String("kind", ev.Notification.NotificationType), slog.String("action", "other_app"))
			w.WriteHeader(http.StatusOK)
			return
		}
	}
	msgID := "appstore:" + ev.Notification.NotificationUUID
	seen, err := s.Store.SeenRTDN(ctx, msgID)
	if err != nil {
		s.internalError(w, r, "rtdn_dedupe", err)
		return
	}
	if seen {
		w.WriteHeader(http.StatusOK)
		return
	}
	// Unless processing completes, forget the id so Apple's retry runs it again.
	done := false
	defer func() {
		if !done {
			_ = s.Store.ForgetRTDN(context.WithoutCancel(ctx), msgID)
		}
	}()
	out, err := s.billingSvc.HandleAppStoreNotification(ctx, ev, s.Config.AppStoreBundleID)
	if err != nil {
		s.billingError(w, r, err)
		return
	}
	done = true
	environment := ""
	if ev.Notification.Data != nil {
		environment = ev.Notification.Data.Environment
	}
	s.logInfo(r, eventRTDNReceived, "app store notification processed", slog.String("store", "app_store"),
		slog.String("kind", out.Kind), slog.String("subtype", ev.Notification.Subtype),
		slog.String("productId", out.ProductID), slog.String("environment", environment),
		slog.String("action", strings.SplitN(out.Action, ":", 2)[0]))
	if rf := out.Refund; rf != nil {
		s.logWarn(r, eventRefundApplied, "refund applied", slog.String("store", "app_store"), slog.String(logx.KeyUser, rf.UserHash),
			slog.String("productId", rf.ProductID), slog.Int("coinsClawedBack", rf.Clawed), slog.Int("debt", rf.Debt),
			slog.Bool("premiumRevoked", rf.Revoked), slog.Bool("orphan", rf.WasOrphan))
	}
	w.WriteHeader(http.StatusOK)
}
