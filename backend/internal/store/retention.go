package store

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

// InactiveAnonymous is an anonymous account and its Firebase uids.
type InactiveAnonymous struct {
	UserID   string
	Subjects []string
}

// InactiveAnonymousUsers lists anonymous accounts not seen since cutoff,
// oldest first.
func (s *Store) InactiveAnonymousUsers(ctx context.Context, cutoff time.Time, limit int) ([]InactiveAnonymous, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT u.id::text, COALESCE(array_agg(ai.subject) FILTER (WHERE ai.provider = 'firebase'), '{}')
		FROM users u LEFT JOIN auth_identities ai ON ai.user_id = u.id
		WHERE u.is_anonymous AND u.last_seen_at < $1
		GROUP BY u.id, u.last_seen_at
		ORDER BY u.last_seen_at
		LIMIT $2`, cutoff, limit)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, func(r pgx.CollectableRow) (InactiveAnonymous, error) {
		var a InactiveAnonymous
		err := r.Scan(&a.UserID, &a.Subjects)
		return a, err
	})
}

// DeleteInactiveAnonymous deletes the account only if it is still anonymous
// and still inactive (it may have signed in since it was listed). It reports
// whether it was deleted.
func (s *Store) DeleteInactiveAnonymous(ctx context.Context, userID, userHash string, cutoff time.Time) (bool, error) {
	deleted := false
	err := s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `DELETE FROM users WHERE id = $1 AND is_anonymous AND last_seen_at < $2`, userID, cutoff)
		if err != nil || tag.RowsAffected() == 0 {
			return err
		}
		deleted = true
		_, err = tx.Exec(ctx, `INSERT INTO deleted_users (user_hash) VALUES ($1) ON CONFLICT DO NOTHING`, userHash)
		return err
	})
	return deleted, err
}

// DeletedUserHashes returns every hash recorded in deleted_users.
func (s *Store) DeletedUserHashes(ctx context.Context) (map[string]bool, error) {
	rows, err := s.pool.Query(ctx, `SELECT user_hash FROM deleted_users`)
	if err != nil {
		return nil, err
	}
	hashes, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, err
	}
	out := make(map[string]bool, len(hashes))
	for _, h := range hashes {
		out[h] = true
	}
	return out, nil
}

// UserIDsAfter pages through all user ids in id order.
func (s *Store) UserIDsAfter(ctx context.Context, after string, limit int) ([]string, error) {
	rows, err := s.pool.Query(ctx, `SELECT id::text FROM users WHERE id > $1::uuid ORDER BY id LIMIT $2`, after, limit)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, pgx.RowTo[string])
}

// DeleteUserByID removes a user that was deleted before a backup restore.
func (s *Store) DeleteUserByID(ctx context.Context, userID string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM users WHERE id = $1`, userID)
	return err
}
