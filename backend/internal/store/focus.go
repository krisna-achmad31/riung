package store

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// FocusTicket is a prepaid Focus session the app may start offline.
type FocusTicket struct {
	ID          string
	UserID      string
	Source      string // free_daily | prepaid | coins
	DurationMin int
	IssuedAt    time.Time
	ExpiresAt   time.Time
	ConsumedAt  *time.Time
}

const focusColumns = `id::text, user_id::text, source, duration_min, issued_at, expires_at, consumed_at`

func scanFocusTicket(row pgx.Row) (FocusTicket, error) {
	var t FocusTicket
	err := row.Scan(&t.ID, &t.UserID, &t.Source, &t.DurationMin, &t.IssuedAt, &t.ExpiresAt, &t.ConsumedAt)
	return t, notFound(err)
}

// IssueFocusTicket stores a new ticket for the user.
func (u *UserTx) IssueFocusTicket(source string, durationMin int, issuedAt, expiresAt time.Time) (FocusTicket, error) {
	return scanFocusTicket(u.tx.QueryRow(u.ctx, `INSERT INTO focus_tickets (user_id, source, duration_min, issued_at, expires_at)
		VALUES ($1, $2, $3, $4, $5) RETURNING `+focusColumns, u.userID, source, durationMin, issuedAt, expiresAt))
}

// FocusTicket locks one of the user's tickets (ErrNotFound for another user's).
func (u *UserTx) FocusTicket(id string) (FocusTicket, error) {
	return scanFocusTicket(u.tx.QueryRow(u.ctx, `SELECT `+focusColumns+` FROM focus_tickets
		WHERE id = $1 AND user_id = $2 FOR UPDATE`, id, u.userID))
}

// ConsumeFocusTicket marks a ticket used; it reports false if it already was.
func (u *UserTx) ConsumeFocusTicket(id string, at time.Time) (bool, error) {
	tag, err := u.tx.Exec(u.ctx, `UPDATE focus_tickets SET consumed_at = $3
		WHERE id = $1 AND user_id = $2 AND consumed_at IS NULL`, id, u.userID, at)
	return tag.RowsAffected() == 1, err
}

// OpenFocusTickets lists the user's unused tickets that have not expired.
func (s *Store) OpenFocusTickets(ctx context.Context, userID string, now time.Time) ([]FocusTicket, error) {
	rows, err := s.pool.Query(ctx, `SELECT `+focusColumns+` FROM focus_tickets
		WHERE user_id = $1 AND consumed_at IS NULL AND expires_at > $2
		ORDER BY expires_at, issued_at LIMIT 200`, userID, now)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (FocusTicket, error) { return scanFocusTicket(r) })
}

// --- Aplikasi Beku --------------------------------------------------------------------

// LastAppBekuUnlock returns when the user last paid for an unlock (nil if never).
func (u *UserTx) LastAppBekuUnlock() (*time.Time, error) {
	var at time.Time
	err := u.tx.QueryRow(u.ctx, `SELECT created_at FROM appbeku_unlocks WHERE user_id = $1
		ORDER BY created_at DESC LIMIT 1`, u.userID).Scan(&at)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &at, nil
}

// RecordAppBekuUnlock stores a paid unlock. target is "unit" or a bundle id:
// which apps were opened is not kept (no app-usage history on the server).
func (u *UserTx) RecordAppBekuUnlock(target string, minutes, price int, at time.Time) error {
	_, err := u.tx.Exec(u.ctx, `INSERT INTO appbeku_unlocks (user_id, target, minutes, price, created_at)
		VALUES ($1, $2, $3, $4, $5)`, u.userID, target, minutes, price, at)
	return err
}
