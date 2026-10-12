package api

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/rules"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Log events for economy actions.
const (
	eventActivity       = "activity"
	eventWalletMutation = "wallet_mutation"
	eventShopPurchase   = "shop_purchase"
)

func walletOut(w store.Wallet) walletJSON {
	return walletJSON{Coins: w.Coins(), EarnedCoins: w.EarnedCoins, PurchasedCoins: w.PurchasedCoins}
}

// ruleError maps rule/store errors to API errors.
func (s *Server) ruleError(w http.ResponseWriter, r *http.Request, op string, err error) {
	var v *rules.ValidationError
	var price *rules.PriceChangedError
	var coins *store.ErrInsufficientCoins
	switch {
	case errors.As(err, &v):
		httpx.WriteError(w, r, invalid(v.Message, v.Field))
	case errors.Is(err, rules.ErrNotFound):
		httpx.WriteError(w, r, httpx.ErrNotFound)
	case errors.Is(err, rules.ErrAlreadyOwned):
		httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodeAlreadyOwned, "item already owned"))
	case errors.Is(err, rules.ErrNotOwned):
		httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodeNotOwned, "item not owned"))
	case errors.Is(err, store.ErrLedgerKeyUsed):
		httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodeIdempotencyKeyReuse, "Idempotency-Key was already used"))
	case errors.Is(err, rules.ErrPremiumRequired):
		httpx.WriteError(w, r, httpx.NewError(http.StatusForbidden, httpx.CodePremiumRequired, "Riung Premium is required"))
	case errors.As(err, &price):
		httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodePriceChanged, "price changed; reload /v1/config").
			WithDetails(map[string]any{"price": price.Price}))
	case errors.As(err, &coins):
		// The app must offer practice before any coin pack (CLAUDE.md §4).
		httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodeInsufficientCoins, "not enough coins").
			WithDetails(map[string]any{
				"balance": coins.Balance, "required": coins.Required,
				"shortfall": coins.Required - coins.Balance, "earnedOnly": coins.EarnedOnly,
			}))
	default:
		if apiErr, ok := blockingError(err); ok {
			httpx.WriteError(w, r, apiErr)
			return
		}
		s.internalError(w, r, op, err)
	}
}

// --- POST /v1/activities ---------------------------------------------------------------

type activityResponse struct {
	Result rules.ActivityResult `json:"result"`
	Wallet walletJSON           `json:"wallet"`
}

func (s *Server) postActivity(w http.ResponseWriter, r *http.Request) {
	var in rules.ActivityInput
	if apiErr := httpx.DecodeJSON(r, &in); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	c := callerFrom(r.Context())
	res, wallet, err := s.rules.ApplyActivity(r.Context(), *c.User, in)
	s.logFocusEvent(r, c.User.ID, &res, err)
	if err != nil {
		s.ruleError(w, r, "activity", err)
		return
	}
	s.logActivity(r, c, res)
	httpx.WriteJSON(w, http.StatusOK, activityResponse{Result: res, Wallet: walletOut(wallet)})
}

func (s *Server) logActivity(r *http.Request, c *caller, res rules.ActivityResult) {
	if res.Replayed {
		return
	}
	user := s.Hasher.User(c.User.ID)
	attrs := []slog.Attr{slog.String(logx.KeyUser, user), slog.String("type", res.Type), slog.Int("coins", res.CoinsGranted)}
	if res.Capped {
		attrs = append(attrs, slog.String("capReason", res.CapReason))
	}
	s.logInfo(r, eventActivity, "activity applied", attrs...)
	if res.CoinsGranted > 0 {
		s.logInfo(r, eventWalletMutation, "coins credited", slog.String(logx.KeyUser, user),
			slog.String("type", "earn"), slog.String("kind", res.Type), slog.Int("amount", res.CoinsGranted))
	}
}

// --- POST /v1/activities/batch ---------------------------------------------------------

type batchRequest struct {
	Events []json.RawMessage `json:"events"`
}

type batchItem struct {
	OK     bool                  `json:"ok"`
	Result *rules.ActivityResult `json:"result,omitempty"`
	Error  *batchError           `json:"error,omitempty"`
}

type batchError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Field   string `json:"field,omitempty"`
}

// postActivityBatch drains an offline outbox: events are processed in order,
// each in its own transaction, and each reports its own outcome. A bad event
// does not block the others.
func (s *Server) postActivityBatch(w http.ResponseWriter, r *http.Request) {
	var req batchRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(req.Events) == 0 || len(req.Events) > maxBatchEvents {
		httpx.WriteError(w, r, invalid("events must contain 1–"+strconv.Itoa(maxBatchEvents)+" items", "events"))
		return
	}
	c := callerFrom(r.Context())
	items := make([]batchItem, 0, len(req.Events))
	for _, raw := range req.Events {
		var in rules.ActivityInput
		dec := json.NewDecoder(strings.NewReader(string(raw)))
		dec.DisallowUnknownFields()
		if err := dec.Decode(&in); err != nil {
			items = append(items, batchItem{Error: &batchError{Code: httpx.CodeInvalidRequest, Message: "malformed event"}})
			continue
		}
		res, _, err := s.rules.ApplyActivity(r.Context(), *c.User, in)
		s.logFocusEvent(r, c.User.ID, &res, err)
		var v *rules.ValidationError
		var tk *rules.TicketError
		switch {
		case err == nil:
			s.logActivity(r, c, res)
			items = append(items, batchItem{OK: true, Result: &res})
		case errors.As(err, &v):
			items = append(items, batchItem{Error: &batchError{Code: httpx.CodeInvalidRequest, Message: v.Message, Field: v.Field}})
		case errors.As(err, &tk):
			items = append(items, batchItem{Error: &batchError{Code: httpx.CodeTicketInvalid, Message: tk.Reason, Field: "ticketId"}})
		default:
			// Infrastructure failure: stop so the client retries the rest later.
			s.internalError(w, r, "activity_batch", err)
			return
		}
	}
	wallet, err := s.Store.Wallet(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "wallet", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"results": items, "wallet": walletOut(wallet)})
}

// --- GET /v1/journal/access -------------------------------------------------------------

func (s *Server) getJournalAccess(w http.ResponseWriter, r *http.Request) {
	promptID := r.URL.Query().Get("promptId")
	if promptID != "" && len(promptID) > 64 {
		httpx.WriteError(w, r, invalid("promptId is too long", "promptId"))
		return
	}
	c := callerFrom(r.Context())
	acc, err := s.rules.JournalAccessFor(r.Context(), *c.User, promptID)
	if err != nil {
		s.ruleError(w, r, "journal_access", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, acc)
}

// --- wallet ------------------------------------------------------------------------------

func (s *Server) getWallet(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	wallet, err := s.Store.Wallet(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "wallet", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"coins": wallet.Coins(), "earnedCoins": wallet.EarnedCoins, "purchasedCoins": wallet.PurchasedCoins,
		"debtCoins": wallet.DebtCoins,
	})
}

type transactionJSON struct {
	ID           string    `json:"id"`
	Type         string    `json:"type"`
	Amount       int       `json:"amount"`
	Reason       string    `json:"reason"`
	Ref          *string   `json:"ref"`
	BalanceAfter int       `json:"balanceAfter"`
	CreatedAt    time.Time `json:"createdAt"`
}

func (s *Server) getTransactions(w http.ResponseWriter, r *http.Request) {
	limit := 20
	if v := r.URL.Query().Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 100 {
			httpx.WriteError(w, r, invalid("limit must be 1–100", "limit"))
			return
		}
		limit = n
	}
	cursor := r.URL.Query().Get("cursor")
	if len(cursor) > 200 {
		httpx.WriteError(w, r, invalid("invalid cursor", "cursor"))
		return
	}
	c := callerFrom(r.Context())
	entries, next, err := s.Store.Transactions(r.Context(), c.User.ID, limit, cursor)
	if errors.Is(err, store.ErrBadCursor) {
		httpx.WriteError(w, r, invalid("invalid cursor", "cursor"))
		return
	}
	if err != nil {
		s.internalError(w, r, "transactions", err)
		return
	}
	items := make([]transactionJSON, 0, len(entries))
	for _, e := range entries {
		items = append(items, transactionJSON{ID: e.ID, Type: e.Type, Amount: e.Amount, Reason: e.Reason, Ref: e.Ref,
			BalanceAfter: e.BalanceAfter, CreatedAt: e.CreatedAt.UTC()})
	}
	var nextCursor *string
	if next != "" {
		nextCursor = &next
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"items": items, "nextCursor": nextCursor})
}

// --- POST /v1/premium/daily-coins -----------------------------------------------------------

func (s *Server) postPremiumDaily(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	res, wallet, err := s.rules.ClaimPremiumDaily(r.Context(), *c.User)
	if err != nil {
		s.ruleError(w, r, "premium_daily", err)
		return
	}
	if res.CoinsGranted > 0 {
		s.logInfo(r, eventWalletMutation, "coins credited", slog.String(logx.KeyUser, s.Hasher.User(c.User.ID)),
			slog.String("type", "earn"), slog.String("bucket", store.BucketPurchased),
			slog.String("kind", "premium_daily"), slog.Int("amount", res.CoinsGranted))
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"result": res, "wallet": walletOut(wallet)})
}

// --- POST /v1/shop/purchase ------------------------------------------------------------------

func (s *Server) postPurchase(w http.ResponseWriter, r *http.Request) {
	var in rules.PurchaseInput
	if apiErr := httpx.DecodeJSON(r, &in); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(in.ItemID) == 0 || len(in.ItemID) > 64 {
		httpx.WriteError(w, r, invalid("itemId is required", "itemId"))
		return
	}
	c := callerFrom(r.Context())
	key := strings.ToLower(r.Header.Get("Idempotency-Key"))
	res, wallet, err := s.rules.Purchase(r.Context(), *c.User, in, key)
	if err != nil {
		s.ruleError(w, r, "purchase", err)
		return
	}
	user := s.Hasher.User(c.User.ID)
	s.logInfo(r, eventShopPurchase, "shop purchase", slog.String(logx.KeyUser, user),
		slog.String("itemType", res.ItemType), slog.String("itemId", res.ItemID), slog.Int("price", res.Price))
	s.logInfo(r, eventWalletMutation, "coins debited", slog.String(logx.KeyUser, user),
		slog.String("type", "spend"), slog.String("kind", res.ItemType), slog.Int("amount", res.Price))
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"result": res, "wallet": walletOut(wallet)})
}

// --- loadouts ---------------------------------------------------------------------------------

type monsterLoadoutRequest struct {
	Items []string `json:"items"`
}

func (s *Server) putMonsterLoadout(w http.ResponseWriter, r *http.Request) {
	var in monsterLoadoutRequest
	if apiErr := httpx.DecodeJSON(r, &in); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(in.Items) > 5 {
		httpx.WriteError(w, r, invalid("too many items", "items"))
		return
	}
	c := callerFrom(r.Context())
	items, err := s.rules.SetMonsterLoadout(r.Context(), *c.User, r.PathValue("saboteurId"), in.Items)
	if err != nil {
		s.ruleError(w, r, "monster_loadout", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"saboteurId": r.PathValue("saboteurId"), "items": items})
}

func (s *Server) putCharacterLoadout(w http.ResponseWriter, r *http.Request) {
	var in rules.CharacterLoadoutInput
	if apiErr := httpx.DecodeJSON(r, &in); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(in.Accessories) > 4 {
		httpx.WriteError(w, r, invalid("too many accessories", "accessories"))
		return
	}
	if in.Accessories == nil {
		in.Accessories = []string{}
	}
	c := callerFrom(r.Context())
	out, err := s.rules.SetCharacterLoadout(r.Context(), *c.User, r.PathValue("testId"), in)
	if err != nil {
		s.ruleError(w, r, "character_loadout", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"testId": r.PathValue("testId"), "accessories": out.Accessories, "cardStyle": out.CardStyle})
}
