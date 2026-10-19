package billing

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"errors"
	"fmt"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// App Store purchases live in the same purchases table as Play tokens, keyed
// "appstore:<id>": the transactionId for a coin pack, the
// originalTransactionId for a subscription (stable across renewals,
// upgrades and downgrades within the subscription group).
const appStorePrefix = "appstore:"

func appStoreKey(id string) string { return appStorePrefix + id }

// ErrAppStoreUnavailable: Apple did not answer (network, 429, 5xx). The API
// answers 503 so the app retries.
var ErrAppStoreUnavailable = errors.New("app store unavailable")

// AppAccountToken is the UUID the iOS app passes as applicationUserName
// (StoreKit appAccountToken), so a transaction can only be credited to the
// account that bought it — the App Store counterpart of AccountID.
func AppAccountToken(key []byte, userID string) string {
	m := hmac.New(sha256.New, key)
	m.Write([]byte("appstore:" + userID))
	b := m.Sum(nil)[:16]
	b[6] = (b[6] & 0x0f) | 0x80 // UUID version 8 (custom)
	b[8] = (b[8] & 0x3f) | 0x80 // RFC 4122 variant
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

func appStoreErr(err error) error {
	switch {
	case errors.Is(err, appstore.ErrNotFound), errors.Is(err, appstore.ErrInvalidSignature):
		return ErrInvalidPurchase
	case errors.Is(err, appstore.ErrUnavailable):
		return fmt.Errorf("%w: %w", ErrAppStoreUnavailable, err)
	}
	return err
}

// VerifyAppStore checks a transaction with the App Store and grants it to
// user exactly once. Same results as Verify.
func (s *Service) VerifyAppStore(ctx context.Context, user store.User, productID, transactionID string) (Result, store.Wallet, error) {
	if s.AppStore == nil {
		return Result{}, store.Wallet{}, ErrNotConfigured
	}
	if pack, ok := s.coinPack(productID); ok {
		return s.verifyAppStoreCoins(ctx, user, pack, transactionID)
	}
	if IsSubscription(productID) {
		return s.verifyAppStoreSubscription(ctx, user, productID, transactionID)
	}
	return Result{}, store.Wallet{}, ErrUnknownProduct
}

func (s *Service) verifyAppStoreCoins(ctx context.Context, user store.User, pack economy.CoinPack, transactionID string) (Result, store.Wallet, error) {
	res := Result{ProductID: pack.ProductID, Kind: store.PurchaseConsumable}
	key := appStoreKey(transactionID)
	if p, err := s.Store.PurchaseByToken(ctx, key); err == nil {
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

	t, err := s.AppStore.Transaction(ctx, transactionID)
	if err != nil {
		return res, store.Wallet{}, appStoreErr(err)
	}
	res.Test = t.Test()
	if t.ProductID != pack.ProductID || t.Type != appstore.TypeConsumable || t.Revoked() ||
		t.AccountToken() != AppAccountToken(s.AccountKey, user.ID) {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	quantity := max(t.Quantity, 1)

	var wallet store.Wallet
	err = s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		p, err := tx.RecordPurchase(store.NewPurchase{Token: key, UserHash: s.Hasher.User(user.ID), ProductID: pack.ProductID,
			Kind: store.PurchaseConsumable, OrderID: t.TransactionID, State: "purchased", Acked: true, Raw: t})
		if err != nil {
			return err
		}
		if p.VoidedAt != nil {
			return ErrInvalidPurchase
		}
		amount := (pack.Coins + pack.Bonus) * quantity
		applied, err := tx.Credit(store.Credit{Type: "purchase", Bucket: store.BucketPurchased, Amount: amount,
			Reason: "coin_pack", Ref: pack.ProductID, Key: ledgerKey("purchase", key)})
		if err != nil {
			return err
		}
		if err := tx.MarkCredited(key); err != nil {
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

// appStoreState maps an App Store subscription to subscriptions.status and
// the date access ends.
func appStoreState(st appstore.SubscriptionStatus) (string, *time.Time) {
	expires := st.Transaction.Expires()
	switch st.Status {
	case appstore.StatusActive:
		if st.Renewal.AutoRenewStatus == 1 {
			return "active", expires
		}
		return "canceled", expires // paid period continues until expiry
	case appstore.StatusGracePeriod:
		if g := st.Renewal.GraceUntil(); g != nil && (expires == nil || g.After(*expires)) {
			return "in_grace", g
		}
		return "in_grace", expires
	case appstore.StatusBillingRetry:
		return "on_hold", expires
	case appstore.StatusRevoked:
		return "revoked", expires
	}
	return "expired", expires
}

func (s *Service) verifyAppStoreSubscription(ctx context.Context, user store.User, productID, transactionID string) (Result, store.Wallet, error) {
	res := Result{ProductID: productID, Kind: store.PurchaseSubscription}
	t, err := s.AppStore.Transaction(ctx, transactionID)
	if err != nil {
		return res, store.Wallet{}, appStoreErr(err)
	}
	if t.Type != appstore.TypeAutoRenewing || t.OriginalTransactionID == "" {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	key := appStoreKey(t.OriginalTransactionID)
	owned := false
	if p, err := s.Store.PurchaseByToken(ctx, key); err == nil {
		if p.UserID == nil || *p.UserID != user.ID {
			return res, store.Wallet{}, ErrInvalidPurchase
		}
		owned = true
	} else if !errors.Is(err, store.ErrNotFound) {
		return res, store.Wallet{}, err
	}
	st, err := s.AppStore.Subscription(ctx, t.OriginalTransactionID)
	if err != nil {
		return res, store.Wallet{}, appStoreErr(err)
	}
	if !s.appStoreOwner(user.ID, owned, t, st.Transaction) || !IsSubscription(st.Transaction.ProductID) {
		return res, store.Wallet{}, ErrInvalidPurchase
	}
	res.Test = st.Transaction.Test()
	res.ProductID = st.Transaction.ProductID

	status, expires := appStoreState(st)
	var wallet store.Wallet
	err = s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		if err := s.applyAppStoreSubscription(tx, user.ID, key, st, status, expires); err != nil {
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
	res.Status, res.PremiumUntil = StatusInactive, expires
	if (status == "active" || status == "in_grace" || status == "canceled") && expires != nil && expires.After(s.Now()) {
		res.Status = StatusActive
	}
	return res, wallet, nil
}

// appStoreOwner: every appAccountToken on the subscription must be this
// user's. A resubscribe from the App Store settings can come without one; it
// is accepted only once the server already tied the subscription to user.
func (s *Service) appStoreOwner(userID string, owned bool, txns ...appstore.Transaction) bool {
	mine := AppAccountToken(s.AccountKey, userID)
	seen := false
	for _, t := range txns {
		if tok := t.AccountToken(); tok != "" {
			if tok != mine {
				return false
			}
			seen = true
		}
	}
	return seen || owned
}

func (s *Service) applyAppStoreSubscription(tx *store.UserTx, userID, key string, st appstore.SubscriptionStatus, status string, expires *time.Time) error {
	sp := SubscriptionPurchase{ProductID: st.Transaction.ProductID, ExpiresAt: expires, AutoRenewing: st.Renewal.AutoRenewStatus == 1,
		Acknowledged: true, OrderID: st.Transaction.TransactionID, Test: st.Transaction.Test()}
	return s.applySubscription(tx, userID, key, sp, status)
}

// --- App Store Server Notifications V2 ---------------------------------------------

// AppStoreEvent is a verified notification with its decoded transaction and
// renewal info (nil when the notification has none).
type AppStoreEvent struct {
	Notification appstore.Notification
	Transaction  *appstore.Transaction
	Renewal      *appstore.RenewalInfo
}

// HandleAppStoreNotification applies one notification. Subscription events
// re-read the subscription from Apple (the notification may be stale or
// arrive out of order); refunds and revocations of a coin pack take the
// coins back. Transactions nobody has verified yet are left for the app.
func (s *Service) HandleAppStoreNotification(ctx context.Context, ev AppStoreEvent, bundleID string) (HandleOutcome, error) {
	if s.AppStore == nil {
		return HandleOutcome{}, ErrNotConfigured
	}
	n := ev.Notification
	out := HandleOutcome{Kind: n.NotificationType, Action: "logged"}
	if n.Data == nil || n.Data.BundleID != bundleID {
		out.Action = "other_bundle"
		return out, nil
	}
	if n.NotificationType == "TEST" {
		out.Kind = "test"
		return out, nil
	}
	t := ev.Transaction
	if t == nil {
		return out, nil
	}
	out.ProductID = t.ProductID
	if t.BundleID != bundleID {
		out.Action = "other_bundle"
		return out, nil
	}

	if t.Type == appstore.TypeConsumable {
		if n.NotificationType != "REFUND" && n.NotificationType != "REVOKE" {
			return out, nil // credited when the app calls /billing/appstore/verify
		}
		r, err := s.voidAppStoreCoins(ctx, t)
		if err != nil {
			return out, err
		}
		out.Action = "no_change"
		if !r.AlreadyRun && r.ProductID != "" {
			out.Action, out.Refund = "refund_applied", &r
		}
		return out, nil
	}
	if t.Type != appstore.TypeAutoRenewing {
		return out, nil
	}
	action, refund, err := s.refreshAppStoreSubscription(ctx, t.OriginalTransactionID)
	out.Action, out.Refund = action, refund
	return out, err
}

func (s *Service) voidAppStoreCoins(ctx context.Context, t *appstore.Transaction) (RefundResult, error) {
	key := appStoreKey(t.TransactionID)
	r := RefundResult{Token: key}
	p, err := s.Store.PurchaseByToken(ctx, key)
	if errors.Is(err, store.ErrNotFound) {
		return r, nil
	}
	if err != nil {
		return r, err
	}
	r.ProductID, r.Kind = p.ProductID, p.Kind
	at := s.Now().UTC()
	if rt := msUTC(t.RevocationDate); rt != nil {
		at = *rt
	}
	if p.UserID == nil {
		r.WasOrphan = true
		if p.VoidedAt != nil {
			r.AlreadyRun = true
			return r, nil
		}
		return r, s.Store.MarkVoidedOrphan(ctx, key, at)
	}
	r.UserHash = s.Hasher.User(*p.UserID)
	return s.voidCoinPack(ctx, *p.UserID, p, at, r)
}

// refreshAppStoreSubscription stores the subscription's current state for
// the user who verified it. A refund that ends access is reported as one.
func (s *Service) refreshAppStoreSubscription(ctx context.Context, original string) (string, *RefundResult, error) {
	key := appStoreKey(original)
	p, err := s.Store.PurchaseByToken(ctx, key)
	if errors.Is(err, store.ErrNotFound) {
		return "awaiting_verify", nil, nil
	}
	if err != nil {
		return "", nil, err
	}
	if p.UserID == nil {
		return "orphan", nil, nil
	}
	owner := *p.UserID
	st, err := s.AppStore.Subscription(ctx, original)
	if err != nil {
		if errors.Is(err, appstore.ErrNotFound) {
			return "unknown_subscription", nil, nil
		}
		return "", nil, appStoreErr(err)
	}
	if !s.appStoreOwner(owner, true, st.Transaction) {
		return "account_mismatch", nil, nil
	}
	status, expires := appStoreState(st)
	r := RefundResult{Token: key, UserHash: s.Hasher.User(owner), ProductID: st.Transaction.ProductID, Kind: store.PurchaseSubscription}
	err = s.Store.WithUserTx(ctx, owner, func(tx *store.UserTx) error {
		before, err := tx.Subscription()
		if err != nil {
			return err
		}
		current, err := tx.SubscriptionToken()
		if err != nil {
			return err
		}
		wasActive := current == key && before != nil && s.premiumActive(before)
		if err := s.applyAppStoreSubscription(tx, owner, key, st, status, expires); err != nil {
			return err
		}
		after, err := tx.Subscription()
		if err != nil {
			return err
		}
		r.Revoked = status == "revoked" && wasActive && (after == nil || !s.premiumActive(after))
		return nil
	})
	if errors.Is(err, store.ErrPurchaseOtherUser) {
		return "other_user", nil, nil
	}
	if err != nil {
		return "", nil, err
	}
	if r.Revoked {
		return "updated:" + status, &r, nil
	}
	return "updated:" + status, nil, nil
}

func msUTC(ms int64) *time.Time {
	if ms <= 0 {
		return nil
	}
	t := time.UnixMilli(ms).UTC()
	return &t
}
