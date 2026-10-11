package store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
)

// IsAdmin reports whether userID is listed in admins.
func (s *Store) IsAdmin(ctx context.Context, userID string) (bool, error) {
	var ok bool
	err := s.pool.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM admins WHERE user_id = $1)`, userID).Scan(&ok)
	return ok, err
}

// GrantAdmin lists userID as an admin and audits it.
func (s *Store) GrantAdmin(ctx context.Context, userID, actor, reason string) error {
	return s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `INSERT INTO admins (user_id, granted_by) VALUES ($1, $2) ON CONFLICT DO NOTHING`, userID, actor); err != nil {
			return err
		}
		return audit(ctx, tx, AuditEntry{Actor: actor, Action: "admin.grant", Key: &userID, Reason: reason})
	})
}

// RevokeAdmin removes userID from admins and audits it.
func (s *Store) RevokeAdmin(ctx context.Context, userID, actor, reason string) error {
	return s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `DELETE FROM admins WHERE user_id = $1`, userID); err != nil {
			return err
		}
		return audit(ctx, tx, AuditEntry{Actor: actor, Action: "admin.revoke", Key: &userID, Reason: reason})
	})
}

// AuditEntry is one admin_audit_log row.
type AuditEntry struct {
	ID          string          `json:"id"`
	AdminUserID *string         `json:"adminUserId"`
	Actor       string          `json:"actor"`
	Action      string          `json:"action"`
	Key         *string         `json:"key"`
	OldValue    json.RawMessage `json:"oldValue"`
	NewValue    json.RawMessage `json:"newValue"`
	Reason      string          `json:"reason"`
	RequestID   *string         `json:"requestId"`
	CreatedAt   time.Time       `json:"createdAt"`
}

func audit(ctx context.Context, tx pgx.Tx, e AuditEntry) error {
	_, err := tx.Exec(ctx, `INSERT INTO admin_audit_log (admin_user_id, actor, action, key, old_value, new_value, reason, request_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		e.AdminUserID, e.Actor, e.Action, e.Key, nullJSON(e.OldValue), nullJSON(e.NewValue), e.Reason, e.RequestID)
	return err
}

func nullJSON(v json.RawMessage) any {
	if len(v) == 0 {
		return nil
	}
	return []byte(v)
}

// SettingChange describes an audited settings update.
type SettingChange struct {
	Key         string
	Value       any // nil = reset to default (row deleted)
	Actor       string
	AdminUserID *string
	Reason      string
	RequestID   *string
}

// ChangeSetting upserts (or, with a nil Value, deletes) a setting and writes
// the audit row in the same transaction. It returns the previous stored value.
func (s *Store) ChangeSetting(ctx context.Context, c SettingChange) (json.RawMessage, error) {
	var old json.RawMessage
	err := s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		var prev []byte
		err := tx.QueryRow(ctx, `SELECT value FROM app_settings WHERE key = $1 FOR UPDATE`, c.Key).Scan(&prev)
		if err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		old = prev
		action := "setting.reset"
		var newRaw json.RawMessage
		if c.Value == nil {
			if _, err := tx.Exec(ctx, `DELETE FROM app_settings WHERE key = $1`, c.Key); err != nil {
				return err
			}
		} else {
			action = "setting.set"
			if newRaw, err = json.Marshal(c.Value); err != nil {
				return err
			}
			if _, err := tx.Exec(ctx, `INSERT INTO app_settings (key, value, updated_by) VALUES ($1, $2, $3)
				ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_by = EXCLUDED.updated_by, updated_at = now()`,
				c.Key, []byte(newRaw), c.Actor); err != nil {
				return err
			}
		}
		key := c.Key
		return audit(ctx, tx, AuditEntry{AdminUserID: c.AdminUserID, Actor: c.Actor, Action: action, Key: &key,
			OldValue: prev, NewValue: newRaw, Reason: c.Reason, RequestID: c.RequestID})
	})
	return old, err
}

// SettingRows returns stored overrides with who changed them and when.
func (s *Store) SettingRows(ctx context.Context) (map[string]SettingRow, error) {
	rows, err := s.pool.Query(ctx, `SELECT key, value, updated_at, updated_by FROM app_settings`)
	if err != nil {
		return nil, err
	}
	out := map[string]SettingRow{}
	var r SettingRow
	_, err = pgx.ForEachRow(rows, []any{&r.Key, &r.Value, &r.UpdatedAt, &r.UpdatedBy}, func() error {
		out[r.Key] = SettingRow{Key: r.Key, Value: append(json.RawMessage(nil), r.Value...), UpdatedAt: r.UpdatedAt, UpdatedBy: r.UpdatedBy}
		return nil
	})
	return out, err
}

// SettingRow is a stored app_settings row.
type SettingRow struct {
	Key       string
	Value     json.RawMessage
	UpdatedAt time.Time
	UpdatedBy string
}

// AuditLog returns audit entries newest first, paged like Transactions.
func (s *Store) AuditLog(ctx context.Context, limit int, cursor string) ([]AuditEntry, string, error) {
	args := []any{limit + 1}
	where := ""
	if cursor != "" {
		at, id, err := decodeCursor(cursor)
		if err != nil {
			return nil, "", ErrBadCursor
		}
		where = `WHERE (created_at, id) < ($2, $3::uuid)`
		args = append(args, at, id)
	}
	rows, err := s.pool.Query(ctx, `SELECT id::text, admin_user_id::text, actor, action, key, old_value, new_value,
			reason, request_id, created_at
		FROM admin_audit_log `+where+` ORDER BY created_at DESC, id DESC LIMIT $1`, args...)
	if err != nil {
		return nil, "", err
	}
	items, err := pgx.CollectRows(rows, func(r pgx.CollectableRow) (AuditEntry, error) {
		var e AuditEntry
		var oldV, newV []byte
		err := r.Scan(&e.ID, &e.AdminUserID, &e.Actor, &e.Action, &e.Key, &oldV, &newV, &e.Reason, &e.RequestID, &e.CreatedAt)
		e.OldValue, e.NewValue = oldV, newV
		return e, err
	})
	if err != nil {
		return nil, "", fmt.Errorf("audit log: %w", err)
	}
	next := ""
	if len(items) > limit {
		items = items[:limit]
		last := items[len(items)-1]
		next = encodeCursor(last.CreatedAt, last.ID)
	}
	return items, next, nil
}
