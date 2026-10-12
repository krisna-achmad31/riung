package store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
)

// Purchase is a purchases row.
type Purchase struct {
	Token        string
	UserID       *string
	ProductID    string
	Kind         string // consumable | subscription
	OrderID      *string
	State        string
	CreditedAt   *time.Time
	AckedAt      *time.Time
	VoidedAt     *time.Time
	SupersededBy *string
	CreatedAt    time.Time
}

// Purchase kinds.
const (
	PurchaseConsumable   = "consumable"
	PurchaseSubscription = "subscription"
)

const purchaseColumns = `purchase_token, user_id::text, product_id, kind, order_id, state, credited_at, acknowledged_at,
	voided_at, superseded_by, created_at`

func scanPurchase(row pgx.Row) (Purchase, error) {
	var p Purchase
	err := row.Scan(&p.Token, &p.UserID, &p.ProductID, &p.Kind, &p.OrderID, &p.State, &p.CreditedAt, &p.AckedAt,
		&p.VoidedAt, &p.SupersededBy, &p.CreatedAt)
	return p, notFound(err)
}

// PurchaseByToken returns a purchase by its Play token.
func (s *Store) PurchaseByToken(ctx context.Context, token string) (Purchase, error) {
	return scanPurchase(s.pool.QueryRow(ctx, `SELECT `+purchaseColumns+` FROM purchases WHERE purchase_token = $1`, token))
}

// PurchaseByToken reads (and locks) a purchase inside the user transaction.
func (u *UserTx) PurchaseByToken(token string) (Purchase, error) {
	return scanPurchase(u.tx.QueryRow(u.ctx, `SELECT `+purchaseColumns+` FROM purchases WHERE purchase_token = $1 FOR UPDATE`, token))
}

// NewPurchase is a verified purchase to record.
type NewPurchase struct {
	Token     string
	UserHash  string
	ProductID string
	Kind      string
	OrderID   string
	State     string
	Acked     bool
	Raw       any
}

// ErrPurchaseOtherUser: the token is already recorded for another account.
var ErrPurchaseOtherUser = errors.New("purchase belongs to another account")

// RecordPurchase inserts the purchase for this user, or refreshes its state
// if it is already theirs. A token recorded for another user is refused.
func (u *UserTx) RecordPurchase(p NewPurchase) (Purchase, error) {
	raw, err := json.Marshal(p.Raw)
	if err != nil {
		return Purchase{}, err
	}
	var orderID *string
	if p.OrderID != "" {
		orderID = &p.OrderID
	}
	_, err = u.tx.Exec(u.ctx, `INSERT INTO purchases (purchase_token, user_id, user_hash, product_id, kind, order_id, state, raw, acknowledged_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CASE WHEN $9 THEN now() END)
		ON CONFLICT (purchase_token) DO NOTHING`,
		p.Token, u.userID, p.UserHash, p.ProductID, p.Kind, orderID, p.State, raw, p.Acked)
	if err != nil {
		return Purchase{}, fmt.Errorf("insert purchase: %w", err)
	}
	cur, err := u.PurchaseByToken(p.Token)
	if err != nil {
		return Purchase{}, err
	}
	if cur.UserID == nil || *cur.UserID != u.userID {
		return Purchase{}, ErrPurchaseOtherUser
	}
	if cur.ProductID != p.ProductID && cur.Kind == PurchaseConsumable {
		return Purchase{}, ErrPurchaseOtherUser
	}
	// Refresh mutable status columns (the only ones the API role may update).
	if _, err := u.tx.Exec(u.ctx, `UPDATE purchases SET state = $2, raw = $3, updated_at = now(),
			acknowledged_at = COALESCE(acknowledged_at, CASE WHEN $4 THEN now() END)
		WHERE purchase_token = $1`, p.Token, p.State, raw, p.Acked); err != nil {
		return Purchase{}, err
	}
	return u.PurchaseByToken(p.Token)
}

// MarkCredited records that the purchase's coins/entitlement were granted.
func (u *UserTx) MarkCredited(token string) error {
	_, err := u.tx.Exec(u.ctx, `UPDATE purchases SET credited_at = COALESCE(credited_at, now()), updated_at = now()
		WHERE purchase_token = $1`, token)
	return err
}

// MarkSuperseded links an old subscription token to its replacement.
func (u *UserTx) MarkSuperseded(oldToken, newToken string) error {
	_, err := u.tx.Exec(u.ctx, `UPDATE purchases SET superseded_by = $2, updated_at = now()
		WHERE purchase_token = $1 AND user_id = $3`, oldToken, newToken, u.userID)
	return err
}

// MarkVoided records a refund/chargeback.
func (u *UserTx) MarkVoided(token string, at time.Time) error {
	_, err := u.tx.Exec(u.ctx, `UPDATE purchases SET voided_at = COALESCE(voided_at, $2), state = 'voided', updated_at = now()
		WHERE purchase_token = $1`, token, at)
	return err
}

// MarkVoidedOrphan voids a purchase whose user was deleted (no wallet to lock).
func (s *Store) MarkVoidedOrphan(ctx context.Context, token string, at time.Time) error {
	_, err := s.pool.Exec(ctx, `UPDATE purchases SET voided_at = COALESCE(voided_at, $2), state = 'voided', updated_at = now()
		WHERE purchase_token = $1 AND user_id IS NULL`, token, at)
	return err
}

// MarkAcknowledged records a server-side acknowledgement.
func (s *Store) MarkAcknowledged(ctx context.Context, token string) error {
	_, err := s.pool.Exec(ctx, `UPDATE purchases SET acknowledged_at = COALESCE(acknowledged_at, now()), updated_at = now()
		WHERE purchase_token = $1`, token)
	return err
}

// UnacknowledgedPurchases lists verified purchases (credited coin packs and
// subscriptions) older than olderThan that nobody has acknowledged yet. Play
// refunds unacknowledged purchases after 3 days.
func (s *Store) UnacknowledgedPurchases(ctx context.Context, olderThan time.Duration) ([]Purchase, error) {
	rows, err := s.pool.Query(ctx, `SELECT `+purchaseColumns+` FROM purchases
		WHERE acknowledged_at IS NULL AND voided_at IS NULL AND credited_at IS NOT NULL AND user_id IS NOT NULL
		  AND created_at < now() - make_interval(secs => $1) AND created_at > now() - interval '3 days'
		ORDER BY created_at LIMIT 500`, olderThan.Seconds())
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (Purchase, error) { return scanPurchase(r) })
}

// Subscription returns the user's subscription, if any.
func (s *Store) Subscription(ctx context.Context, userID string) (*Subscription, error) {
	var sub Subscription
	err := s.pool.QueryRow(ctx, `SELECT plan, status, expires_at, auto_renewing FROM subscriptions WHERE user_id = $1`, userID).
		Scan(&sub.Plan, &sub.Status, &sub.ExpiresAt, &sub.AutoRenewing)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &sub, nil
}

// SetSubscription stores the user's current subscription.
func (u *UserTx) SetSubscription(sub Subscription, token string) error {
	_, err := u.tx.Exec(u.ctx, `INSERT INTO subscriptions (user_id, plan, status, expires_at, auto_renewing, purchase_token)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id) DO UPDATE SET plan = EXCLUDED.plan, status = EXCLUDED.status, expires_at = EXCLUDED.expires_at,
			auto_renewing = EXCLUDED.auto_renewing, purchase_token = EXCLUDED.purchase_token, updated_at = now()`,
		u.userID, sub.Plan, sub.Status, sub.ExpiresAt, sub.AutoRenewing, token)
	return err
}

// SubscriptionToken returns the token of the user's current subscription.
func (u *UserTx) SubscriptionToken() (string, error) {
	var t *string
	err := u.tx.QueryRow(u.ctx, `SELECT purchase_token FROM subscriptions WHERE user_id = $1`, u.userID).Scan(&t)
	if errors.Is(err, pgx.ErrNoRows) || t == nil {
		return "", nil
	}
	return *t, err
}

// --- refunds ------------------------------------------------------------------

// CreditedValue is what the ledger entry with key gave the user, including
// the part that repaid debt (0 if there is no such entry).
func (u *UserTx) CreditedValue(key string) (int, error) {
	var v int
	err := u.tx.QueryRow(u.ctx, `SELECT COALESCE(sum(earned_delta + purchased_delta - debt_delta), 0)::int FROM coin_ledger
		WHERE user_id = $1 AND idempotency_key = $2`, u.userID, key).Scan(&v)
	return v, err
}

// Clawback takes back refunded coins: purchased coins first, then earned;
// whatever the user already spent becomes debt, repaid from future credits
// (balances never go negative). Returns the coins removed and the debt added.
func (u *UserTx) Clawback(amount int, reason, ref, key string) (removed, debt int, err error) {
	if amount <= 0 {
		return 0, 0, fmt.Errorf("clawback amount must be positive")
	}
	if dup, err := u.ledgerKeyUsed(key); err != nil || dup {
		return 0, 0, err
	}
	w := u.wallet
	fromPurchased := min(w.PurchasedCoins, amount)
	fromEarned := min(w.EarnedCoins, amount-fromPurchased)
	debt = amount - fromPurchased - fromEarned
	w.PurchasedCoins -= fromPurchased
	w.EarnedCoins -= fromEarned
	w.DebtCoins += debt
	w.LifetimeEarned = max(0, w.LifetimeEarned-amount)
	if err := u.writeLedger("refund", -fromEarned, -fromPurchased, debt, reason, ref, key, w); err != nil {
		return 0, 0, err
	}
	return fromPurchased + fromEarned, debt, nil
}

// --- reconciliation --------------------------------------------------------------

// Mismatch is a wallet whose balances differ from the sum of its ledger.
type Mismatch struct {
	UserID                                    string
	Earned, Purchased, Debt                   int
	LedgerEarned, LedgerPurchased, LedgerDebt int
}

// Reconcile compares every wallet with the sum of its ledger deltas.
func (s *Store) Reconcile(ctx context.Context) ([]Mismatch, int, error) {
	var checked int
	if err := s.pool.QueryRow(ctx, `SELECT count(*) FROM wallets`).Scan(&checked); err != nil {
		return nil, 0, err
	}
	rows, err := s.pool.Query(ctx, `
		SELECT w.user_id::text, w.earned_coins, w.purchased_coins, w.debt_coins,
		       COALESCE(l.e, 0), COALESCE(l.p, 0), COALESCE(l.d, 0)
		FROM wallets w
		LEFT JOIN (SELECT user_id, sum(earned_delta)::int e, sum(purchased_delta)::int p, sum(debt_delta)::int d
		           FROM coin_ledger GROUP BY user_id) l ON l.user_id = w.user_id
		WHERE w.earned_coins <> COALESCE(l.e, 0) OR w.purchased_coins <> COALESCE(l.p, 0) OR w.debt_coins <> COALESCE(l.d, 0)`)
	if err != nil {
		return nil, 0, err
	}
	out, err := pgx.CollectRows(rows, func(r pgx.CollectableRow) (Mismatch, error) {
		var m Mismatch
		err := r.Scan(&m.UserID, &m.Earned, &m.Purchased, &m.Debt, &m.LedgerEarned, &m.LedgerPurchased, &m.LedgerDebt)
		return m, err
	})
	return out, checked, err
}

// --- RTDN -------------------------------------------------------------------------

// SeenRTDN records a Pub/Sub message id; false means it was already processed.
func (s *Store) SeenRTDN(ctx context.Context, messageID string) (bool, error) {
	tag, err := s.pool.Exec(ctx, `INSERT INTO rtdn_messages (message_id) VALUES ($1) ON CONFLICT DO NOTHING`, messageID)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 0, nil
}

// ForgetRTDN removes a message id after a failed processing so the retry runs.
func (s *Store) ForgetRTDN(ctx context.Context, messageID string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM rtdn_messages WHERE message_id = $1`, messageID)
	return err
}
