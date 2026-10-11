package store

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
)

// LedgerEntry is one coin_ledger row.
type LedgerEntry struct {
	ID             string    `json:"id"`
	Type           string    `json:"type"`
	Amount         int       `json:"amount"`
	EarnedDelta    int       `json:"earnedDelta"`
	PurchasedDelta int       `json:"purchasedDelta"`
	DebtDelta      int       `json:"debtDelta"`
	Reason         string    `json:"reason"`
	Ref            *string   `json:"ref"`
	BalanceAfter   int       `json:"balanceAfter"`
	CreatedAt      time.Time `json:"createdAt"`
}

// PurchaseRecord is the exportable part of a purchases row (never the token).
type PurchaseRecord struct {
	ProductID  string     `json:"productId"`
	Kind       string     `json:"kind"`
	State      string     `json:"state"`
	CreatedAt  time.Time  `json:"createdAt"`
	CreditedAt *time.Time `json:"creditedAt"`
	VoidedAt   *time.Time `json:"voidedAt"`
}

// Export is the user's server-side data for GET /v1/me/export.
type Export struct {
	Snapshot            Snapshot
	Ledger              []LedgerEntry
	Purchases           []PurchaseRecord
	BettermeCompleted   []string
	HasJournalPinBackup bool
	PaidAppBekuUnlocks  int
	FocusTicketsIssued  int
}

// Export gathers everything stored about the user.
func (s *Store) Export(ctx context.Context, userID string, day time.Time) (Export, error) {
	snap, err := s.Snapshot(ctx, userID, day)
	if err != nil {
		return Export{}, err
	}
	out := Export{Snapshot: snap, Ledger: []LedgerEntry{}, Purchases: []PurchaseRecord{}, BettermeCompleted: []string{}}

	rows, err := s.pool.Query(ctx, `SELECT id::text, type, amount, earned_delta, purchased_delta, debt_delta,
			reason, ref, balance_after, created_at
		FROM coin_ledger WHERE user_id = $1 ORDER BY created_at, id`, userID)
	if err != nil {
		return Export{}, fmt.Errorf("ledger: %w", err)
	}
	if out.Ledger, err = pgx.CollectRows(rows, pgx.RowToStructByPos[LedgerEntry]); err != nil {
		return Export{}, fmt.Errorf("ledger: %w", err)
	}

	rows, err = s.pool.Query(ctx, `SELECT product_id, kind, state, created_at, credited_at, voided_at
		FROM purchases WHERE user_id = $1 ORDER BY created_at`, userID)
	if err != nil {
		return Export{}, fmt.Errorf("purchases: %w", err)
	}
	if out.Purchases, err = pgx.CollectRows(rows, pgx.RowToStructByPos[PurchaseRecord]); err != nil {
		return Export{}, fmt.Errorf("purchases: %w", err)
	}

	rows, err = s.pool.Query(ctx, `SELECT lesson_id FROM betterme_completions WHERE user_id = $1 ORDER BY completed_at`, userID)
	if err != nil {
		return Export{}, fmt.Errorf("betterme: %w", err)
	}
	if out.BettermeCompleted, err = pgx.CollectRows(rows, pgx.RowTo[string]); err != nil {
		return Export{}, fmt.Errorf("betterme: %w", err)
	}

	err = s.pool.QueryRow(ctx, `SELECT
			EXISTS (SELECT 1 FROM journal_pin_backups WHERE user_id = $1),
			(SELECT count(*) FROM appbeku_unlocks WHERE user_id = $1),
			(SELECT count(*) FROM focus_tickets WHERE user_id = $1)`, userID).
		Scan(&out.HasJournalPinBackup, &out.PaidAppBekuUnlocks, &out.FocusTicketsIssued)
	if err != nil {
		return Export{}, fmt.Errorf("counts: %w", err)
	}
	return out, nil
}
