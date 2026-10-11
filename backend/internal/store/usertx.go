package store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
)

// UserTx is a transaction holding the row lock on one user's wallet. Every
// coin, counter, progress or inventory change for that user runs inside one,
// so concurrent requests for the same user are serialized and daily caps,
// balances and idempotency checks cannot race.
type UserTx struct {
	ctx    context.Context
	tx     pgx.Tx
	userID string
	wallet Wallet
}

// ErrInsufficientCoins is returned by Spend.
type ErrInsufficientCoins struct {
	Balance    int // spendable balance for this purchase
	Required   int
	EarnedOnly bool
}

func (e *ErrInsufficientCoins) Error() string {
	return fmt.Sprintf("insufficient coins: have %d, need %d", e.Balance, e.Required)
}

// WithUserTx runs fn inside a transaction that has locked userID's wallet.
func (s *Store) WithUserTx(ctx context.Context, userID string, fn func(*UserTx) error) error {
	return s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		// Users created before wallets existed (or by hand) still get one.
		if _, err := tx.Exec(ctx, `INSERT INTO wallets (user_id) VALUES ($1) ON CONFLICT DO NOTHING`, userID); err != nil {
			return fmt.Errorf("ensure wallet: %w", err)
		}
		u := &UserTx{ctx: ctx, tx: tx, userID: userID}
		w := &u.wallet
		if err := tx.QueryRow(ctx, `SELECT earned_coins, purchased_coins, debt_coins, lifetime_earned, lifetime_spent
			FROM wallets WHERE user_id = $1 FOR UPDATE`, userID).
			Scan(&w.EarnedCoins, &w.PurchasedCoins, &w.DebtCoins, &w.LifetimeEarned, &w.LifetimeSpent); err != nil {
			return fmt.Errorf("lock wallet: %w", notFound(err))
		}
		return fn(u)
	})
}

// Wallet is the locked wallet as changed so far in this transaction.
func (u *UserTx) Wallet() Wallet { return u.wallet }

// --- activity idempotency ---------------------------------------------------------

// Activity returns the stored result of an already processed event.
func (u *UserTx) Activity(key string) (json.RawMessage, bool, error) {
	var res []byte
	err := u.tx.QueryRow(u.ctx, `SELECT result FROM activity_events WHERE user_id = $1 AND key = $2`, u.userID, key).Scan(&res)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	return res, true, nil
}

// RecordActivity stores the result of a processed event.
func (u *UserTx) RecordActivity(key, typ string, result any) error {
	raw, err := json.Marshal(result)
	if err != nil {
		return err
	}
	_, err = u.tx.Exec(u.ctx, `INSERT INTO activity_events (user_id, key, type, result) VALUES ($1, $2, $3, $4)`,
		u.userID, key, typ, raw)
	return err
}

// --- daily counters -------------------------------------------------------------------

// Counter reads a daily counter.
func (u *UserTx) Counter(day time.Time, key string) (int, error) {
	var n int
	err := u.tx.QueryRow(u.ctx, `SELECT count FROM daily_counters WHERE user_id = $1 AND day = $2 AND key = $3`,
		u.userID, day, key).Scan(&n)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, nil
	}
	return n, err
}

// IncCounter adds by to a daily counter and returns the new value.
func (u *UserTx) IncCounter(day time.Time, key string, by int) (int, error) {
	var n int
	err := u.tx.QueryRow(u.ctx, `INSERT INTO daily_counters (user_id, day, key, count) VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, day, key) DO UPDATE SET count = daily_counters.count + EXCLUDED.count
		RETURNING count`, u.userID, day, key, by).Scan(&n)
	return n, err
}

// --- coins ----------------------------------------------------------------------------

// Bucket names.
const (
	BucketEarned    = "earned"
	BucketPurchased = "purchased"
)

// Credit grants coins. Outstanding refund debt is repaid first; the rest goes
// to the bucket. It reports false (and changes nothing) when key was already
// used — the ledger's per-user unique key makes rewards idempotent.
type Credit struct {
	Type   string // earn | purchase | adjust
	Bucket string
	Amount int
	Reason string
	Ref    string
	Key    string
}

// Credit applies c. Returns whether it was applied.
func (u *UserTx) Credit(c Credit) (bool, error) {
	if c.Amount <= 0 {
		return false, fmt.Errorf("credit amount must be positive")
	}
	if dup, err := u.ledgerKeyUsed(c.Key); err != nil || dup {
		return false, err
	}
	w := u.wallet
	repay := min(w.DebtCoins, c.Amount)
	net := c.Amount - repay
	var earned, purchased int
	if c.Bucket == BucketPurchased {
		purchased = net
	} else {
		earned = net
	}
	w.DebtCoins -= repay
	w.EarnedCoins += earned
	w.PurchasedCoins += purchased
	w.LifetimeEarned += c.Amount
	if err := u.writeLedger(c.Type, earned, purchased, -repay, c.Reason, c.Ref, c.Key, w); err != nil {
		return false, err
	}
	return true, nil
}

// Debit spends coins: purchased coins first, then earned, unless EarnedOnly
// (Aplikasi Beku unlocks may only use practice coins).
type Debit struct {
	Amount     int
	EarnedOnly bool
	Reason     string
	Ref        string
	Key        string
}

// ErrLedgerKeyUsed: a spend reused a key from an earlier, different request.
var ErrLedgerKeyUsed = errors.New("ledger key already used")

// Debit applies d or returns *ErrInsufficientCoins. A reused key returns
// ErrLedgerKeyUsed: callers derive spend keys from the request's Idempotency-Key.
func (u *UserTx) Debit(d Debit) error {
	if d.Amount <= 0 {
		return fmt.Errorf("debit amount must be positive")
	}
	if dup, err := u.ledgerKeyUsed(d.Key); err != nil {
		return err
	} else if dup {
		return ErrLedgerKeyUsed
	}
	w := u.wallet
	available := w.Coins()
	if d.EarnedOnly {
		available = w.EarnedCoins
	}
	if available < d.Amount {
		return &ErrInsufficientCoins{Balance: available, Required: d.Amount, EarnedOnly: d.EarnedOnly}
	}
	fromPurchased := 0
	if !d.EarnedOnly {
		fromPurchased = min(w.PurchasedCoins, d.Amount)
	}
	fromEarned := d.Amount - fromPurchased
	w.PurchasedCoins -= fromPurchased
	w.EarnedCoins -= fromEarned
	w.LifetimeSpent += d.Amount
	return u.writeLedger("spend", -fromEarned, -fromPurchased, 0, d.Reason, d.Ref, d.Key, w)
}

func (u *UserTx) ledgerKeyUsed(key string) (bool, error) {
	var exists bool
	err := u.tx.QueryRow(u.ctx, `SELECT EXISTS (SELECT 1 FROM coin_ledger WHERE user_id = $1 AND idempotency_key = $2)`,
		u.userID, key).Scan(&exists)
	return exists, err
}

func (u *UserTx) writeLedger(typ string, earned, purchased, debt int, reason, ref, key string, w Wallet) error {
	if _, err := u.tx.Exec(u.ctx, `UPDATE wallets SET earned_coins = $2, purchased_coins = $3, debt_coins = $4,
			lifetime_earned = $5, lifetime_spent = $6, updated_at = now() WHERE user_id = $1`,
		u.userID, w.EarnedCoins, w.PurchasedCoins, w.DebtCoins, w.LifetimeEarned, w.LifetimeSpent); err != nil {
		return fmt.Errorf("update wallet: %w", err)
	}
	var refArg *string
	if ref != "" {
		refArg = &ref
	}
	if _, err := u.tx.Exec(u.ctx, `INSERT INTO coin_ledger (user_id, type, amount, earned_delta, purchased_delta, debt_delta,
			reason, ref, idempotency_key, balance_after) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		u.userID, typ, earned+purchased, earned, purchased, debt, reason, refArg, key, w.Coins()); err != nil {
		return fmt.Errorf("insert ledger: %w", err)
	}
	u.wallet = w
	return nil
}

// --- premium ------------------------------------------------------------------------

// Subscription returns the user's subscription, if any.
func (u *UserTx) Subscription() (*Subscription, error) {
	var s Subscription
	err := u.tx.QueryRow(u.ctx, `SELECT plan, status, expires_at, auto_renewing FROM subscriptions WHERE user_id = $1`, u.userID).
		Scan(&s.Plan, &s.Status, &s.ExpiresAt, &s.AutoRenewing)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// --- monsters -------------------------------------------------------------------------

// AddMonsterProgress adds delta (clamped to 0–100) and reports whether this
// call tamed the monster for the first time.
func (u *UserTx) AddMonsterProgress(saboteurID string, delta int) (MonsterProgress, bool, error) {
	var m MonsterProgress
	var wasTamed bool
	err := u.tx.QueryRow(u.ctx, `
		WITH prev AS (
			SELECT tamed_at IS NOT NULL AS tamed FROM monster_progress WHERE user_id = $1 AND saboteur_id = $2
		), up AS (
			INSERT INTO monster_progress (user_id, saboteur_id, progress, state, tamed_at)
			VALUES ($1, $2, LEAST(100, GREATEST(0, $3)),
				CASE WHEN $3 >= 100 THEN 'tamed' WHEN $3 > 0 THEN 'taming' ELSE 'wild' END,
				CASE WHEN $3 >= 100 THEN now() END)
			ON CONFLICT (user_id, saboteur_id) DO UPDATE SET
				progress = LEAST(100, GREATEST(0, monster_progress.progress + $3)),
				state = CASE
					WHEN monster_progress.progress + $3 >= 100 OR monster_progress.tamed_at IS NOT NULL THEN 'tamed'
					WHEN monster_progress.progress + $3 > 0 THEN 'taming' ELSE 'wild' END,
				tamed_at = COALESCE(monster_progress.tamed_at,
					CASE WHEN monster_progress.progress + $3 >= 100 THEN now() END),
				updated_at = now()
			RETURNING saboteur_id, state, progress, tamed_at
		)
		SELECT up.saboteur_id, up.state, up.progress, up.tamed_at, COALESCE((SELECT tamed FROM prev), false)
		FROM up`, u.userID, saboteurID, delta).
		Scan(&m.SaboteurID, &m.State, &m.Progress, &m.TamedAt, &wasTamed)
	if err != nil {
		return MonsterProgress{}, false, err
	}
	return m, m.TamedAt != nil && !wasTamed, nil
}

// --- streak ---------------------------------------------------------------------------

// Streak reads the check-in streak.
func (u *UserTx) Streak() (Streak, error) {
	var s Streak
	err := u.tx.QueryRow(u.ctx, `SELECT current_days, longest_days, last_checkin_date FROM streaks WHERE user_id = $1`, u.userID).
		Scan(&s.CurrentDays, &s.LongestDays, &s.LastCheckinDate)
	if errors.Is(err, pgx.ErrNoRows) {
		return Streak{}, nil
	}
	return s, err
}

// SetStreak stores the streak.
func (u *UserTx) SetStreak(s Streak) error {
	_, err := u.tx.Exec(u.ctx, `INSERT INTO streaks (user_id, current_days, longest_days, last_checkin_date) VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id) DO UPDATE SET current_days = EXCLUDED.current_days, longest_days = EXCLUDED.longest_days,
			last_checkin_date = EXCLUDED.last_checkin_date`, u.userID, s.CurrentDays, s.LongestDays, s.LastCheckinDate)
	return err
}

// --- consumables & inventory -------------------------------------------------------------

// Consumable kinds.
const (
	ConsumableStreakShield = "streak_shield"
	ConsumablePrepaidFocus = "prepaid_focus"
)

// Consumable returns the quantity of kind.
func (u *UserTx) Consumable(kind string) (int, error) {
	var n int
	err := u.tx.QueryRow(u.ctx, `SELECT qty FROM consumables WHERE user_id = $1 AND kind = $2`, u.userID, kind).Scan(&n)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, nil
	}
	return n, err
}

// ErrNotEnough is returned when a consumable would go below zero.
var ErrNotEnough = errors.New("not enough left")

// AddConsumable changes the quantity of kind by delta and returns the new
// quantity. Taking more than is left returns ErrNotEnough and changes nothing.
func (u *UserTx) AddConsumable(kind string, delta int) (int, error) {
	var n int
	if delta >= 0 {
		err := u.tx.QueryRow(u.ctx, `INSERT INTO consumables (user_id, kind, qty) VALUES ($1, $2, $3)
			ON CONFLICT (user_id, kind) DO UPDATE SET qty = consumables.qty + EXCLUDED.qty RETURNING qty`,
			u.userID, kind, delta).Scan(&n)
		return n, err
	}
	// A negative INSERT row would fail the CHECK before ON CONFLICT applies,
	// so decrements are a guarded UPDATE.
	err := u.tx.QueryRow(u.ctx, `UPDATE consumables SET qty = qty + $3
		WHERE user_id = $1 AND kind = $2 AND qty + $3 >= 0 RETURNING qty`, u.userID, kind, delta).Scan(&n)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, ErrNotEnough
	}
	return n, err
}

// Inventory returns the owned item ids.
func (u *UserTx) Inventory() (map[string]bool, error) {
	rows, err := u.tx.Query(u.ctx, `SELECT item_id FROM inventory WHERE user_id = $1`, u.userID)
	if err != nil {
		return nil, err
	}
	ids, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, err
	}
	out := make(map[string]bool, len(ids))
	for _, id := range ids {
		out[id] = true
	}
	return out, nil
}

// AddInventory grants item ids (already owned ones are kept as they are).
func (u *UserTx) AddInventory(ids []string, source string) error {
	for _, id := range ids {
		if _, err := u.tx.Exec(u.ctx, `INSERT INTO inventory (user_id, item_id, source) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`,
			u.userID, id, source); err != nil {
			return err
		}
	}
	return nil
}

// --- Better Me & loadouts ----------------------------------------------------------------

// BettermeCompleted returns the completed lesson ids.
func (u *UserTx) BettermeCompleted() (map[string]bool, error) {
	rows, err := u.tx.Query(u.ctx, `SELECT lesson_id FROM betterme_completions WHERE user_id = $1`, u.userID)
	if err != nil {
		return nil, err
	}
	ids, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, err
	}
	out := make(map[string]bool, len(ids))
	for _, id := range ids {
		out[id] = true
	}
	return out, nil
}

// CompleteBetterme records a lesson; false if it was already completed.
func (u *UserTx) CompleteBetterme(lessonID string) (bool, error) {
	tag, err := u.tx.Exec(u.ctx, `INSERT INTO betterme_completions (user_id, lesson_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
		u.userID, lessonID)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

// SetMonsterLoadout replaces the cosmetics worn by one monster.
func (u *UserTx) SetMonsterLoadout(saboteurID string, items []string) error {
	_, err := u.tx.Exec(u.ctx, `INSERT INTO monster_loadouts (user_id, saboteur_id, item_ids) VALUES ($1, $2, $3)
		ON CONFLICT (user_id, saboteur_id) DO UPDATE SET item_ids = EXCLUDED.item_ids, updated_at = now()`,
		u.userID, saboteurID, items)
	return err
}

// SetCharacterLoadout replaces a personality character's accessories and card style.
func (u *UserTx) SetCharacterLoadout(testID string, accessories []string, cardStyle *string) error {
	_, err := u.tx.Exec(u.ctx, `INSERT INTO character_loadouts (user_id, test_id, accessory_ids, card_style) VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, test_id) DO UPDATE SET accessory_ids = EXCLUDED.accessory_ids,
			card_style = EXCLUDED.card_style, updated_at = now()`, u.userID, testID, accessories, cardStyle)
	return err
}
