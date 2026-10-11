package store

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
)

// ContentItem is one public content entry.
type ContentItem struct {
	ID       string
	Position int
	Data     json.RawMessage
}

// ContentList is the items of one kind and locale plus a validator.
type ContentList struct {
	Items     []json.RawMessage
	UpdatedAt time.Time
	ETag      string
}

// Content returns the items of kind/locale ordered by position.
func (s *Store) Content(ctx context.Context, kind, locale string) (ContentList, error) {
	rows, err := s.pool.Query(ctx, `SELECT data, updated_at FROM content_items
		WHERE kind = $1 AND locale = $2 ORDER BY position, id`, kind, locale)
	if err != nil {
		return ContentList{}, err
	}
	out := ContentList{Items: []json.RawMessage{}}
	var data []byte
	var at time.Time
	h := sha256.New()
	_, err = pgx.ForEachRow(rows, []any{&data, &at}, func() error {
		out.Items = append(out.Items, json.RawMessage(append([]byte(nil), data...)))
		h.Write(data)
		if at.After(out.UpdatedAt) {
			out.UpdatedAt = at
		}
		return nil
	})
	if err != nil {
		return ContentList{}, err
	}
	h.Write([]byte(kind + "|" + locale + "|" + strconv.Itoa(len(out.Items))))
	out.ETag = `"` + hex.EncodeToString(h.Sum(nil))[:32] + `"`
	return out, nil
}

// ReplaceContent atomically replaces every item of kind/locale.
func (s *Store) ReplaceContent(ctx context.Context, kind, locale string, items []ContentItem) error {
	return s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `DELETE FROM content_items WHERE kind = $1 AND locale = $2`, kind, locale); err != nil {
			return err
		}
		for _, it := range items {
			if _, err := tx.Exec(ctx, `INSERT INTO content_items (kind, id, locale, position, data) VALUES ($1, $2, $3, $4, $5)`,
				kind, it.ID, locale, it.Position, []byte(it.Data)); err != nil {
				return fmt.Errorf("insert %s/%s: %w", kind, it.ID, err)
			}
		}
		return nil
	})
}

// AddWaitlist stores an email once; it reports whether it was new.
func (s *Store) AddWaitlist(ctx context.Context, email, lang, source string) (bool, error) {
	tag, err := s.pool.Exec(ctx, `INSERT INTO waitlist (email, lang, source) VALUES ($1, NULLIF($2, ''), NULLIF($3, ''))
		ON CONFLICT (email) DO NOTHING`, email, lang, source)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

// Settings returns all admin-overridden settings.
func (s *Store) Settings(ctx context.Context) (map[string]json.RawMessage, time.Time, error) {
	rows, err := s.pool.Query(ctx, `SELECT key, value, updated_at FROM app_settings`)
	if err != nil {
		return nil, time.Time{}, err
	}
	out := map[string]json.RawMessage{}
	var latest time.Time
	var k string
	var v []byte
	var at time.Time
	_, err = pgx.ForEachRow(rows, []any{&k, &v, &at}, func() error {
		out[k] = append(json.RawMessage(nil), v...)
		if at.After(latest) {
			latest = at
		}
		return nil
	})
	return out, latest, err
}

// ConsumeAppCheckJTI records a limited-use App Check token id; it reports
// false when the id was already used (replay).
func (s *Store) ConsumeAppCheckJTI(ctx context.Context, jti string, expiresAt time.Time) (bool, error) {
	tag, err := s.pool.Exec(ctx, `INSERT INTO appcheck_jti (jti, expires_at) VALUES ($1, $2) ON CONFLICT DO NOTHING`, jti, expiresAt)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() == 1, nil
}

// SetSetting upserts an admin setting (validation is the caller's job).
func (s *Store) SetSetting(ctx context.Context, key string, value any, updatedBy string) error {
	raw, err := json.Marshal(value)
	if err != nil {
		return err
	}
	_, err = s.pool.Exec(ctx, `INSERT INTO app_settings (key, value, updated_by) VALUES ($1, $2, $3)
		ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_by = EXCLUDED.updated_by, updated_at = now()`,
		key, raw, updatedBy)
	return err
}
