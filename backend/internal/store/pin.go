package store

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// PinBackup is a journal PIN backup. MAC is HMAC(server pepper, hash from the
// phone); it never leaves the server.
type PinBackup struct {
	MAC       string
	Salt      string
	UpdatedAt time.Time
}

// PinBackup returns the user's backup.
func (s *Store) PinBackup(ctx context.Context, userID string) (PinBackup, error) {
	var b PinBackup
	err := s.pool.QueryRow(ctx, `SELECT hash, salt, updated_at FROM journal_pin_backups WHERE user_id = $1`, userID).
		Scan(&b.MAC, &b.Salt, &b.UpdatedAt)
	return b, notFound(err)
}

// PutPinBackup creates or replaces the backup.
func (s *Store) PutPinBackup(ctx context.Context, userID, mac, salt string) (time.Time, error) {
	var at time.Time
	err := s.pool.QueryRow(ctx, `INSERT INTO journal_pin_backups (user_id, hash, salt) VALUES ($1, $2, $3)
		ON CONFLICT (user_id) DO UPDATE SET hash = EXCLUDED.hash, salt = EXCLUDED.salt, updated_at = now()
		RETURNING updated_at`, userID, mac, salt).Scan(&at)
	return at, err
}

// DeletePinBackup removes the backup (idempotent).
func (s *Store) DeletePinBackup(ctx context.Context, userID string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM journal_pin_backups WHERE user_id = $1`, userID)
	return err
}

// PinLockedUntil returns the active lock for day, if any.
func (s *Store) PinLockedUntil(ctx context.Context, userID string, day, now time.Time) (*time.Time, error) {
	var until *time.Time
	err := s.pool.QueryRow(ctx, `SELECT locked_until FROM pin_attempts WHERE user_id = $1 AND day = $2`, userID, day).Scan(&until)
	if err = notFound(err); errors.Is(err, ErrNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if until != nil && until.After(now) {
		return until, nil
	}
	return nil, nil
}

// RecordPinFailure counts a failed verification; at maxFailures the user is
// locked for lockFor. It returns the failures so far and the lock, if set.
func (s *Store) RecordPinFailure(ctx context.Context, userID string, day, now time.Time, maxFailures int, lockFor time.Duration) (int, *time.Time, error) {
	var failures int
	var until *time.Time
	err := s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		if err := tx.QueryRow(ctx, `INSERT INTO pin_attempts (user_id, day, failures) VALUES ($1, $2, 1)
			ON CONFLICT (user_id, day) DO UPDATE SET failures = pin_attempts.failures + 1
			RETURNING failures`, userID, day).Scan(&failures); err != nil {
			return err
		}
		if failures >= maxFailures {
			t := now.Add(lockFor)
			until = &t
			_, err := tx.Exec(ctx, `UPDATE pin_attempts SET locked_until = $3 WHERE user_id = $1 AND day = $2`, userID, day, t)
			return err
		}
		return nil
	})
	return failures, until, err
}
