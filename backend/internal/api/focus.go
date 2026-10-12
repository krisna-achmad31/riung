package api

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/rules"
	"github.com/krisna-achmad31/riung/backend/internal/store"
	"github.com/krisna-achmad31/riung/backend/internal/ticket"
)

// Focus & Aplikasi Beku log events (docs/backend-api-spec.md §6.4).
const (
	eventFocusIssued   = "focus_ticket_issued"
	eventFocusRedeemed = "focus_ticket_redeemed"
	eventFocusInvalid  = "focus_ticket_invalid"
	eventAppBekuUnlock = "appbeku_unlock"
	eventAppBekuBlock  = "appbeku_blocked"
)

var errTicketsOff = httpx.NewError(http.StatusServiceUnavailable, httpx.CodeUnavailable, "focus tickets are not available right now")

// blockingError maps the errors of limits that block an action (§1.3).
func blockingError(err error) (*httpx.APIError, bool) {
	var limit *rules.LimitError
	var cool *rules.CooldownError
	var tk *rules.TicketError
	switch {
	case errors.As(err, &limit):
		d := map[string]any{"reason": limit.Reason, "limit": limit.Limit}
		if limit.ResetsAt != nil {
			d["resetsAt"] = limit.ResetsAt.UTC()
		}
		return httpx.NewError(http.StatusConflict, httpx.CodeLimitReached, "limit reached").WithDetails(d), true
	case errors.As(err, &cool):
		secs := int(cool.RetryAfter.Seconds() + 0.999)
		return httpx.NewError(http.StatusConflict, httpx.CodeCooldown, "please wait before the next paid unlock").
			WithDetails(map[string]any{"retryAfterSeconds": max(1, secs)}), true
	case errors.As(err, &tk):
		return httpx.NewError(http.StatusConflict, httpx.CodeTicketInvalid, "focus ticket cannot be used").
			WithDetails(map[string]any{"reason": tk.Reason}), true
	}
	return nil, false
}

// --- POST /v1/focus/tickets -----------------------------------------------------------

func (s *Server) postFocusTicket(w http.ResponseWriter, r *http.Request) {
	if s.tickets == nil {
		httpx.WriteError(w, r, errTicketsOff)
		return
	}
	var in rules.FocusTicketInput
	if apiErr := httpx.DecodeJSON(r, &in); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	c := callerFrom(r.Context())
	key := strings.ToLower(r.Header.Get("Idempotency-Key"))
	out, wallet, err := s.rules.IssueFocusTicket(r.Context(), *c.User, in, key)
	if err != nil {
		s.ruleError(w, r, "focus_ticket", err)
		return
	}
	user := s.Hasher.User(c.User.ID)
	s.logInfo(r, eventFocusIssued, "focus ticket issued", slog.String(logx.KeyUser, user),
		slog.String("source", in.Source), slog.Int("durationMin", in.DurationMin))
	if out.Price > 0 {
		s.logInfo(r, eventWalletMutation, "coins debited", slog.String(logx.KeyUser, user),
			slog.String("type", "spend"), slog.String("kind", "focus_ticket"), slog.Int("amount", out.Price))
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"ticket": s.tickets.Sign(out.Ticket), "price": out.Price,
		"freeFocusLeft": out.FreeFocusLeft, "prepaidFocus": out.PrepaidFocus, "wallet": walletOut(wallet),
	})
}

// --- GET /v1/focus/tickets ------------------------------------------------------------

func (s *Server) getFocusTickets(w http.ResponseWriter, r *http.Request) {
	if s.tickets == nil {
		httpx.WriteError(w, r, errTicketsOff)
		return
	}
	c := callerFrom(r.Context())
	open, err := s.Store.OpenFocusTickets(r.Context(), c.User.ID, s.now())
	if err != nil {
		s.internalError(w, r, "focus_tickets", err)
		return
	}
	out := make([]ticket.Ticket, 0, len(open))
	for _, t := range open {
		out = append(out, s.tickets.Sign(t))
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"tickets": out, "keys": s.ticketKeys()})
}

type ticketKey struct {
	Kid       string `json:"kid"`
	Alg       string `json:"alg"`
	PublicKey string `json:"publicKey"`
}

func (s *Server) ticketKeys() []ticketKey {
	if s.tickets == nil {
		return []ticketKey{}
	}
	return []ticketKey{{Kid: s.tickets.Kid(), Alg: "Ed25519", PublicKey: s.tickets.PublicKey()}}
}

// --- POST /v1/appbeku/unlocks -----------------------------------------------------------

func (s *Server) postAppBekuUnlock(w http.ResponseWriter, r *http.Request) {
	var in rules.AppBekuInput
	if apiErr := httpx.DecodeJSON(r, &in); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(in.AppIDs) > 10 || len(in.AppID) > 128 || len(in.BundleID) > 64 {
		httpx.WriteError(w, r, invalid("request is too large", "appIds"))
		return
	}
	c := callerFrom(r.Context())
	user := s.Hasher.User(c.User.ID)
	key := strings.ToLower(r.Header.Get("Idempotency-Key"))
	res, wallet, err := s.rules.AppBekuUnlock(r.Context(), *c.User, in, key)
	if err != nil {
		if reason := appBekuBlockReason(err); reason != "" {
			s.logWarn(r, eventAppBekuBlock, "appbeku unlock blocked", slog.String(logx.KeyUser, user), slog.String("reason", reason))
		}
		s.ruleError(w, r, "appbeku_unlock", err)
		return
	}
	// Only counts and prices are logged: which apps were opened is not.
	s.logInfo(r, eventAppBekuUnlock, "appbeku unlock", slog.String(logx.KeyUser, user),
		slog.String("target", res.Target), slog.Int("n", res.PaidUnlocksUsed), slog.Int("price", res.Price))
	s.logInfo(r, eventWalletMutation, "coins debited", slog.String(logx.KeyUser, user),
		slog.String("type", "spend"), slog.String("kind", "appbeku_unlock"), slog.Int("amount", res.Price))
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"result": res, "wallet": walletOut(wallet)})
}

func appBekuBlockReason(err error) string {
	var limit *rules.LimitError
	var cool *rules.CooldownError
	var coins *store.ErrInsufficientCoins
	switch {
	case errors.As(err, &limit):
		return "limit"
	case errors.As(err, &cool):
		return "cooldown"
	case errors.As(err, &coins):
		return "earned_only"
	}
	return ""
}

// logFocusEvent logs a redeemed or refused ticket of a focus_completed event.
func (s *Server) logFocusEvent(r *http.Request, userID string, res *rules.ActivityResult, err error) {
	var tk *rules.TicketError
	switch {
	case errors.As(err, &tk):
		s.logWarn(r, eventFocusInvalid, "focus ticket invalid", slog.String(logx.KeyUser, s.Hasher.User(userID)),
			slog.String("reason", tk.Reason))
	case err == nil && res != nil && res.Type == rules.TypeFocusComplete && !res.Replayed:
		s.logInfo(r, eventFocusRedeemed, "focus ticket redeemed", slog.String(logx.KeyUser, s.Hasher.User(userID)))
	}
}
