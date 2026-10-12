package store

import (
	"bytes"
	"context"
	"errors"
	"time"
)

// Idempotency errors.
var (
	ErrIdempotencyMismatch   = errors.New("idempotency key reused with a different request")
	ErrIdempotencyInProgress = errors.New("a request with this idempotency key is still running")
)

// StoredResponse is a previously completed response (body bytes verbatim).
type StoredResponse struct {
	Status int
	Body   []byte
}

// IdempotencyStaleAfter is how long an unfinished claim blocks retries. A
// request that crashed the process (or was killed by a deploy) leaves its
// claim unfinished; after this the key may be claimed again.
const IdempotencyStaleAfter = time.Minute

// BeginIdempotent claims key for this request. It returns nil, nil when the
// caller should run the request; a stored response to replay; or one of the
// Idempotency errors.
func (s *Store) BeginIdempotent(ctx context.Context, userID, key, route string, requestHash []byte) (*StoredResponse, error) {
	tag, err := s.pool.Exec(ctx, `INSERT INTO idempotency_keys (user_id, key, route, request_hash, status, response)
		VALUES ($1, $2, $3, $4, 0, '') ON CONFLICT (user_id, key) DO NOTHING`, userID, key, route, requestHash)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 1 {
		return nil, nil
	}
	var (
		gotRoute string
		gotHash  []byte
		status   int
		body     []byte
		stale    bool
	)
	if err := s.pool.QueryRow(ctx, `SELECT route, request_hash, status, response,
			created_at < now() - make_interval(secs => $3)
		FROM idempotency_keys WHERE user_id = $1 AND key = $2`, userID, key, IdempotencyStaleAfter.Seconds()).
		Scan(&gotRoute, &gotHash, &status, &body, &stale); err != nil {
		return nil, notFound(err)
	}
	if gotRoute != route || !bytes.Equal(gotHash, requestHash) {
		return nil, ErrIdempotencyMismatch
	}
	if status == 0 {
		if !stale {
			return nil, ErrIdempotencyInProgress
		}
		// Take over an abandoned claim (only one taker wins the update).
		tag, err := s.pool.Exec(ctx, `UPDATE idempotency_keys SET created_at = now()
			WHERE user_id = $1 AND key = $2 AND status = 0 AND created_at < now() - make_interval(secs => $3)`,
			userID, key, IdempotencyStaleAfter.Seconds())
		if err != nil {
			return nil, err
		}
		if tag.RowsAffected() == 0 {
			return nil, ErrIdempotencyInProgress
		}
		return nil, nil
	}
	return &StoredResponse{Status: status, Body: body}, nil
}

// CompleteIdempotent stores the response for replays.
func (s *Store) CompleteIdempotent(ctx context.Context, userID, key string, status int, body []byte) error {
	if body == nil {
		body = []byte{}
	}
	_, err := s.pool.Exec(ctx, `UPDATE idempotency_keys SET status = $3, response = $4 WHERE user_id = $1 AND key = $2`,
		userID, key, status, body)
	return err
}

// AbortIdempotent releases the key after a server error so the client can retry.
func (s *Store) AbortIdempotent(ctx context.Context, userID, key string) error {
	_, err := s.pool.Exec(ctx, `DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2 AND status = 0`, userID, key)
	return err
}

// PurgeResult counts rows removed by Purge.
type PurgeResult struct {
	IdempotencyKeys int64 `json:"idempotencyKeys"`
	AppCheckJTIs    int64 `json:"appCheckJtis"`
	SignupCounters  int64 `json:"signupCounters"`
	DailyCounters   int64 `json:"dailyCounters"`
	PinAttempts     int64 `json:"pinAttempts"`
	RTDNMessages    int64 `json:"rtdnMessages"`
}

// Purge deletes housekeeping rows nobody can need any more: idempotency keys
// past their replay window, expired App Check token ids, and counters for
// days that no rule can still look at (events older than 7 days are
// rejected). Coin ledger and processed events are never purged.
func (s *Store) Purge(ctx context.Context) (PurgeResult, error) {
	var r PurgeResult
	steps := []struct {
		dst *int64
		sql string
	}{
		{&r.IdempotencyKeys, `DELETE FROM idempotency_keys WHERE created_at < now() - interval '7 days'`},
		{&r.AppCheckJTIs, `DELETE FROM appcheck_jti WHERE expires_at < now()`},
		{&r.SignupCounters, `DELETE FROM signup_counters WHERE day < current_date - 2`},
		{&r.DailyCounters, `DELETE FROM daily_counters WHERE day < current_date - 30`},
		{&r.PinAttempts, `DELETE FROM pin_attempts WHERE day < current_date - 2`},
		// Pub/Sub keeps undelivered messages at most 7 days.
		{&r.RTDNMessages, `DELETE FROM rtdn_messages WHERE received_at < now() - interval '30 days'`},
	}
	for _, st := range steps {
		tag, err := s.pool.Exec(ctx, st.sql)
		if err != nil {
			return r, err
		}
		*st.dst = tag.RowsAffected()
	}
	return r, nil
}
