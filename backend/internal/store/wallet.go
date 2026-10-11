package store

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

// Wallet returns the user's balances.
func (s *Store) Wallet(ctx context.Context, userID string) (Wallet, error) {
	var w Wallet
	err := s.pool.QueryRow(ctx, `SELECT earned_coins, purchased_coins, debt_coins, lifetime_earned, lifetime_spent
		FROM wallets WHERE user_id = $1`, userID).
		Scan(&w.EarnedCoins, &w.PurchasedCoins, &w.DebtCoins, &w.LifetimeEarned, &w.LifetimeSpent)
	if errors.Is(err, pgx.ErrNoRows) {
		return Wallet{}, nil
	}
	return w, err
}

// ErrBadCursor is returned for a tampered or malformed paging cursor.
var ErrBadCursor = errors.New("invalid cursor")

// Transactions returns ledger entries newest first. cursor is the opaque
// value from the previous page ("" for the first page).
func (s *Store) Transactions(ctx context.Context, userID string, limit int, cursor string) ([]LedgerEntry, string, error) {
	args := []any{userID, limit + 1}
	where := ""
	if cursor != "" {
		at, id, err := decodeCursor(cursor)
		if err != nil {
			return nil, "", ErrBadCursor
		}
		where = `AND (created_at, id) < ($3, $4::uuid)`
		args = append(args, at, id)
	}
	rows, err := s.pool.Query(ctx, `SELECT id::text, type, amount, earned_delta, purchased_delta, debt_delta,
			reason, ref, balance_after, created_at
		FROM coin_ledger WHERE user_id = $1 `+where+`
		ORDER BY created_at DESC, id DESC LIMIT $2`, args...)
	if err != nil {
		return nil, "", err
	}
	items, err := pgx.CollectRows(rows, pgx.RowToStructByPos[LedgerEntry])
	if err != nil {
		return nil, "", err
	}
	next := ""
	if len(items) > limit {
		items = items[:limit]
		last := items[len(items)-1]
		next = encodeCursor(last.CreatedAt, last.ID)
	}
	return items, next, nil
}

func encodeCursor(at time.Time, id string) string {
	return base64.RawURLEncoding.EncodeToString([]byte(at.UTC().Format(time.RFC3339Nano) + "|" + id))
}

func decodeCursor(c string) (time.Time, string, error) {
	raw, err := base64.RawURLEncoding.DecodeString(c)
	if err != nil {
		return time.Time{}, "", err
	}
	at, id, ok := strings.Cut(string(raw), "|")
	if !ok || len(id) != 36 {
		return time.Time{}, "", fmt.Errorf("cursor")
	}
	t, err := time.Parse(time.RFC3339Nano, at)
	return t, id, err
}

// UpsertSubscription stores the user's Play subscription state (written by
// purchase verification / RTDN handling).
func (s *Store) UpsertSubscription(ctx context.Context, userID string, sub Subscription, purchaseToken *string) error {
	_, err := s.pool.Exec(ctx, `INSERT INTO subscriptions (user_id, plan, status, expires_at, auto_renewing, purchase_token)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (user_id) DO UPDATE SET plan = EXCLUDED.plan, status = EXCLUDED.status, expires_at = EXCLUDED.expires_at,
			auto_renewing = EXCLUDED.auto_renewing, purchase_token = EXCLUDED.purchase_token, updated_at = now()`,
		userID, sub.Plan, sub.Status, sub.ExpiresAt, sub.AutoRenewing, purchaseToken)
	return err
}
