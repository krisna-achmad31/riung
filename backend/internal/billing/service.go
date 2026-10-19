package billing

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/rules"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Subscription product ids (match the app's PremiumSku).
const (
	PlanMonthly = "premium_monthly"
	PlanYearly  = "premium_yearly"
)

// Errors returned to the API.
var (
	// ErrInvalidPurchase: Play does not confirm a valid purchase for this account.
	ErrInvalidPurchase = errors.New("purchase is not valid for this account")
	// ErrUnknownProduct: not one of our product ids.
	ErrUnknownProduct = errors.New("unknown product")
	// ErrNotConfigured: billing is disabled on this server.
	ErrNotConfigured = errors.New("billing is not configured")
)

// Service verifies purchases and applies Play events.
type Service struct {
	Store     *store.Store
	Economy   economy.Props
	Publisher Publisher // nil = billing not configured
	// AppStore verifies iOS purchases; nil = App Store billing not configured.
	AppStore appstore.API
	Hasher   logx.Hasher
	// AccountKey derives the obfuscated account id the app passes to Play.
	AccountKey []byte
	Now        func() time.Time
	// AckAfter is how long the app gets to acknowledge a verified purchase
	// before Sync does it (default 1h).
	AckAfter time.Duration
}

// AccountID is the obfuscated Play account id for a user: the app sets it as
// applicationUserName so a token can only be credited to its buyer.
func AccountID(key []byte, userID string) string {
	m := hmac.New(sha256.New, key)
	m.Write([]byte(userID))
	return "ba_" + hex.EncodeToString(m.Sum(nil))[:32]
}

// ledgerKey keeps ledger keys short: Play tokens can exceed the key column.
func ledgerKey(prefix, token string) string {
	sum := sha256.Sum256([]byte(token))
	return prefix + ":" + hex.EncodeToString(sum[:])[:40]
}

// Verify statuses.
const (
	StatusCredited        = "credited"
	StatusAlreadyCredited = "already_credited"
	StatusPending         = "pending"
	StatusActive          = "active"
	StatusInactive        = "inactive"
)

// Result is the outcome of verifying one purchase.
type Result struct {
	ProductID    string     `json:"productId"`
	Kind         string     `json:"kind"`
	Status       string     `json:"status"`
	CoinsGranted int        `json:"coinsGranted"`
	PremiumUntil *time.Time `json:"premiumUntil,omitempty"`
	Test         bool       `json:"test"`
}

func (s *Service) coinPack(productID string) (economy.CoinPack, bool) {
	for _, p := range s.Economy.CoinPacks {
		if p.ProductID == productID {
			return p, true
		}
	}
	return economy.CoinPack{}, false
}

// IsSubscription reports whether productID is a Premium plan.
func IsSubscription(productID string) bool {
	return productID == PlanMonthly || productID == PlanYearly
}

// Verify checks a purchase with Play and grants it to user exactly once.
func (s *Service) Verify(ctx context.Context, user store.User, productID, token string) (Result, store.Wallet, error) {
	if s.Publisher == nil {
		return Result{}, store.Wallet{}, ErrNotConfigured
	}
	if pack, ok := s.coinPack(productID); ok {
		return s.verifyCoins(ctx, user, pack, token)
	}
	if IsSubscription(productID) {
		return s.verifySubscription(ctx, user, productID, token)
	}
	return Result{}, store.Wallet{}, ErrUnknownProduct
}

func (s *Service) verifyCoins(ctx context.Context, user store.User, pack economy.CoinPack, token string) (Result, store.Wallet, error) {
	res := Result{ProductID: pack.ProductID, Kind: store.PurchaseConsumable}
	// Already credited to this user? Answer without calling Play.
	if p, err := s.Store.PurchaseByToken(ctx, token); err == nil {
		if p.UserID == nil || *p.UserID != user.ID || p.ProductID != pack.ProductID || p.VoidedAt != nil {
			return res, store.Wallet{}, ErrInvalidPurchase
		}
		if p.CreditedAt != nil {
			w, err := s.Store.Wallet(ctx, user.ID)
			res.Status = StatusAlreadyCredited
			return res, w, err
		}
	} else if !errors.Is(err, store.ErrNotFound) {
		return res, store.Wallet{}, err
	}

	pp, err := s.Publisher.GetProduct(ctx, pack.ProductID, token)
	if err != nil {
		if errors.Is(err, ErrPurchaseNotFound) {
			return res, store.Wallet{}, ErrInvalidPurchase
		}
		return res, store.Wallet{}, err
	}
	res.Test = pp.Test
	if pp.ObfuscatedAccount != AccountID(s.AccountKey, user.ID) {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	switch pp.PurchaseState {
	case ProductPending:
		res.Status = StatusPending
		w, err := s.Store.Wallet(ctx, user.ID)
		return res, w, err
	case ProductPurchased:
	default:
		return res, store.Wallet{}, ErrInvalidPurchase
	}

	var wallet store.Wallet
	err = s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		p, err := tx.RecordPurchase(store.NewPurchase{Token: token, UserHash: s.Hasher.User(user.ID), ProductID: pack.ProductID,
			Kind: store.PurchaseConsumable, OrderID: pp.OrderID, State: "purchased", Acked: pp.Acknowledged, Raw: pp})
		if err != nil {
			return err
		}
		if p.VoidedAt != nil {
			return ErrInvalidPurchase
		}
		amount := pack.Coins + pack.Bonus
		amount *= int(pp.Quantity)
		applied, err := tx.Credit(store.Credit{Type: "purchase", Bucket: store.BucketPurchased, Amount: amount,
			Reason: "coin_pack", Ref: pack.ProductID, Key: ledgerKey("purchase", token)})
		if err != nil {
			return err
		}
		if err := tx.MarkCredited(token); err != nil {
			return err
		}
		if applied {
			res.Status, res.CoinsGranted = StatusCredited, amount
		} else {
			res.Status = StatusAlreadyCredited
		}
		wallet = tx.Wallet()
		return nil
	})
	if errors.Is(err, store.ErrPurchaseOtherUser) {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	return res, wallet, err
}

// subscriptionStatus maps a Play state to subscriptions.status.
func subscriptionStatus(state string) (string, bool) {
	switch state {
	case SubActive:
		return "active", true
	case SubInGrace:
		return "in_grace", true
	case SubCanceled:
		return "canceled", true // paid period continues until expiry
	case SubOnHold:
		return "on_hold", true
	case SubPaused:
		return "paused", true
	case SubExpired:
		return "expired", true
	}
	return "", false // pending states: nothing to store yet
}

func (s *Service) verifySubscription(ctx context.Context, user store.User, productID, token string) (Result, store.Wallet, error) {
	res := Result{ProductID: productID, Kind: store.PurchaseSubscription}
	owned := false
	if p, err := s.Store.PurchaseByToken(ctx, token); err == nil {
		if p.UserID == nil || *p.UserID != user.ID {
			return res, store.Wallet{}, ErrInvalidPurchase
		}
		owned = true
	} else if !errors.Is(err, store.ErrNotFound) {
		return res, store.Wallet{}, err
	}
	sp, err := s.Publisher.GetSubscription(ctx, token)
	if err != nil {
		if errors.Is(err, ErrPurchaseNotFound) {
			return res, store.Wallet{}, ErrInvalidPurchase
		}
		return res, store.Wallet{}, err
	}
	res.Test = sp.Test
	// A resubscribe from the Play Store can come without the account id; such
	// a token is accepted only once the server has already tied it to this
	// user (through its linkedPurchaseToken, see refreshSubscription).
	account := sp.ObfuscatedAccount
	if (account != AccountID(s.AccountKey, user.ID) && (account != "" || !owned)) || !IsSubscription(sp.ProductID) {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	res.ProductID = sp.ProductID
	status, ok := subscriptionStatus(sp.State)
	if !ok {
		res.Status = StatusPending
		w, err := s.Store.Wallet(ctx, user.ID)
		return res, w, err
	}
	var wallet store.Wallet
	err = s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		if err := s.applySubscription(tx, user.ID, token, sp, status); err != nil {
			return err
		}
		wallet = tx.Wallet()
		return nil
	})
	if errors.Is(err, store.ErrPurchaseOtherUser) {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	if err != nil {
		return res, store.Wallet{}, err
	}
	res.Status, res.PremiumUntil = StatusInactive, sp.ExpiresAt
	if (status == "active" || status == "in_grace" || status == "canceled") && sp.ExpiresAt != nil && sp.ExpiresAt.After(s.Now()) {
		res.Status = StatusActive
	}
	return res, wallet, nil
}

// applySubscription records the token and makes it the user's subscription
// unless the user already holds a newer one: a superseded (upgraded/
// resubscribed) token or one that ends earlier never overwrites the current.
func (s *Service) applySubscription(tx *store.UserTx, userID, token string, sp SubscriptionPurchase, status string) error {
	p, err := tx.RecordPurchase(store.NewPurchase{Token: token, UserHash: s.Hasher.User(userID), ProductID: sp.ProductID,
		Kind: store.PurchaseSubscription, OrderID: sp.OrderID, State: status, Acked: sp.Acknowledged, Raw: sp})
	if err != nil {
		return err
	}
	if sp.LinkedToken != "" && sp.LinkedToken != token {
		if err := tx.MarkSuperseded(sp.LinkedToken, token); err != nil {
			return err
		}
	}
	if err := tx.MarkCredited(token); err != nil {
		return err
	}
	currentToken, err := tx.SubscriptionToken()
	if err != nil {
		return err
	}
	if currentToken != "" && currentToken != token {
		if p.SupersededBy != nil {
			return nil
		}
		current, err := tx.Subscription()
		if err != nil {
			return err
		}
		// The linked successor always wins; otherwise keep whichever lasts longer.
		if sp.LinkedToken != currentToken && current != nil && current.ExpiresAt != nil &&
			(sp.ExpiresAt == nil || sp.ExpiresAt.Before(*current.ExpiresAt)) {
			return nil
		}
	}
	return tx.SetSubscription(store.Subscription{Plan: sp.ProductID, Status: status, ExpiresAt: sp.ExpiresAt, AutoRenewing: sp.AutoRenewing}, token)
}

func (s *Service) premiumActive(sub *store.Subscription) bool {
	return rules.PremiumStatus(sub, s.Now(), s.Economy.Premium.GraceDays).Active()
}

// Subscription returns the user's stored subscription.
func (s *Service) Subscription(ctx context.Context, userID string) (*store.Subscription, error) {
	return s.Store.Subscription(ctx, userID)
}

// --- refunds & housekeeping ---------------------------------------------------------

// RefundResult describes one processed voided purchase.
type RefundResult struct {
	Token      string
	UserHash   string
	ProductID  string
	Kind       string
	Clawed     int
	Debt       int
	Revoked    bool // subscription: Premium no longer active after re-reading Play
	WasOrphan  bool // the buyer deleted their account
	AlreadyRun bool
}

// ApplyVoided processes one voided purchase. A coin pack takes back exactly
// what it credited, once (unspent coins first, the rest becomes debt). A
// subscription is re-read from Play, which knows whether access was revoked
// (a refunded renewal can leave the subscription active). Unknown tokens are
// ignored.
func (s *Service) ApplyVoided(ctx context.Context, v VoidedPurchase) (RefundResult, error) {
	r := RefundResult{Token: v.Token}
	p, err := s.Store.PurchaseByToken(ctx, v.Token)
	if errors.Is(err, store.ErrNotFound) {
		return r, nil
	}
	if err != nil {
		return r, err
	}
	r.ProductID, r.Kind = p.ProductID, p.Kind
	if p.UserID == nil {
		r.WasOrphan = true
		if p.VoidedAt != nil {
			r.AlreadyRun = true
			return r, nil
		}
		return r, s.Store.MarkVoidedOrphan(ctx, v.Token, v.VoidedAt)
	}
	r.UserHash = s.Hasher.User(*p.UserID)
	if p.Kind == store.PurchaseSubscription {
		return s.voidSubscription(ctx, *p.UserID, p, r)
	}
	return s.voidCoinPack(ctx, *p.UserID, p, v.VoidedAt, r)
}

// voidCoinPack takes back exactly what a refunded coin pack credited, once
// (unspent coins first, the rest becomes debt). Shared by Play and App Store.
func (s *Service) voidCoinPack(ctx context.Context, userID string, p store.Purchase, at time.Time, r RefundResult) (RefundResult, error) {
	if p.VoidedAt != nil {
		r.AlreadyRun = true
		return r, nil
	}
	err := s.Store.WithUserTx(ctx, userID, func(tx *store.UserTx) error {
		cur, err := tx.PurchaseByToken(p.Token)
		if err != nil {
			return err
		}
		if cur.VoidedAt != nil {
			r.AlreadyRun = true
			return nil
		}
		if cur.CreditedAt != nil {
			credited, err := tx.CreditedValue(ledgerKey("purchase", p.Token))
			if err != nil {
				return err
			}
			if credited > 0 {
				if r.Clawed, r.Debt, err = tx.Clawback(credited, "refund", cur.ProductID, ledgerKey("refund", p.Token)); err != nil {
					return err
				}
			}
		}
		return tx.MarkVoided(p.Token, at)
	})
	return r, err
}

// voidSubscription refreshes a refunded subscription from Play. If Play no
// longer knows the token, Premium from it is revoked.
func (s *Service) voidSubscription(ctx context.Context, userID string, p store.Purchase, r RefundResult) (RefundResult, error) {
	sp, err := s.Publisher.GetSubscription(ctx, p.Token)
	gone := errors.Is(err, ErrPurchaseNotFound)
	if err != nil && !gone {
		return r, err
	}
	err = s.Store.WithUserTx(ctx, userID, func(tx *store.UserTx) error {
		before, err := tx.Subscription()
		if err != nil {
			return err
		}
		token, err := tx.SubscriptionToken()
		if err != nil {
			return err
		}
		wasActive := token == p.Token && before != nil && rules.PremiumStatus(before, s.Now(), s.Economy.Premium.GraceDays).Active()
		if gone {
			if token == p.Token {
				now := s.Now()
				if err := tx.SetSubscription(store.Subscription{Plan: p.ProductID, Status: "revoked", ExpiresAt: &now}, p.Token); err != nil {
					return err
				}
			}
		} else if status, ok := subscriptionStatus(sp.State); ok {
			if err := s.applySubscription(tx, userID, p.Token, sp, status); err != nil {
				return err
			}
		}
		after, err := tx.Subscription()
		if err != nil {
			return err
		}
		r.Revoked = wasActive && (after == nil || !rules.PremiumStatus(after, s.Now(), s.Economy.Premium.GraceDays).Active())
		r.AlreadyRun = !r.Revoked
		return nil
	})
	return r, err
}

// SyncResult summarises a billing sync run.
type SyncResult struct {
	Voided       int
	Refunded     []RefundResult
	VoidFailed   int // retried on the next run (Play keeps 30 days)
	Acknowledged int
	AckFailed    int // retried on the next run
	Errors       []error
}

// OK reports whether every item was processed.
func (r SyncResult) OK() bool { return r.VoidFailed == 0 && r.AckFailed == 0 }

// Sync applies refunds from the last 30 days (idempotent) and acknowledges
// purchases the app verified but failed to acknowledge within an hour, so
// Play does not refund them automatically after 3 days. Coin packs are only
// acknowledged, never consumed: the app consumes them (spec §3.9).
func (s *Service) Sync(ctx context.Context) (SyncResult, error) {
	var out SyncResult
	if s.Publisher == nil {
		return out, ErrNotConfigured
	}
	voided, err := s.Publisher.ListVoided(ctx, s.Now().Add(-30*24*time.Hour))
	if err != nil {
		return out, err
	}
	out.Voided = len(voided)
	for _, v := range voided {
		r, err := s.ApplyVoided(ctx, v)
		if err != nil {
			out.VoidFailed++
			out.Errors = append(out.Errors, err)
			continue
		}
		if !r.AlreadyRun && r.ProductID != "" {
			out.Refunded = append(out.Refunded, r)
		}
	}
	ackAfter := s.AckAfter
	if ackAfter <= 0 {
		ackAfter = time.Hour
	}
	pending, err := s.Store.UnacknowledgedPurchases(ctx, ackAfter)
	if err != nil {
		return out, err
	}
	for _, p := range pending {
		if err := s.acknowledge(ctx, p); err != nil {
			out.AckFailed++
			out.Errors = append(out.Errors, err)
			continue
		}
		if err := s.Store.MarkAcknowledged(ctx, p.Token); err != nil {
			return out, err
		}
		out.Acknowledged++
	}
	return out, nil
}

func (s *Service) acknowledge(ctx context.Context, p store.Purchase) error {
	if p.Kind == store.PurchaseConsumable {
		pp, err := s.Publisher.GetProduct(ctx, p.ProductID, p.Token)
		if err != nil {
			return err
		}
		if pp.Acknowledged || pp.Consumed || pp.PurchaseState != ProductPurchased {
			return nil
		}
		return s.Publisher.AcknowledgeProduct(ctx, p.ProductID, p.Token)
	}
	sp, err := s.Publisher.GetSubscription(ctx, p.Token)
	if err != nil {
		return err
	}
	if sp.Acknowledged || sp.State == SubPending {
		return nil
	}
	return s.Publisher.AcknowledgeSubscription(ctx, p.ProductID, p.Token)
}
