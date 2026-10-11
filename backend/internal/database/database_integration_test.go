package database_test

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"

	"github.com/krisna-achmad31/riung/backend/internal/database"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

func TestMigrationsAndPrivileges(t *testing.T) {
	urls := testdb.Create(t)
	migratorURL, appURL := urls.Migrator, urls.App
	ctx := context.Background()
	logger := logx.New(io.Discard, slog.LevelInfo)

	if err := database.Migrate(ctx, migratorURL, database.MigrateUp, false, logger); err != nil {
		t.Fatalf("migrate up: %v", err)
	}
	// Down then up again proves the Down section is complete.
	if err := database.Migrate(ctx, migratorURL, database.MigrateDown, false, logger); err != nil {
		t.Fatalf("migrate down: %v", err)
	}
	if err := database.Migrate(ctx, migratorURL, database.MigrateUp, false, logger); err != nil {
		t.Fatalf("migrate up again: %v", err)
	}
	if err := database.Migrate(ctx, migratorURL, database.MigrateDown, true, logger); !errors.Is(err, database.ErrDownInProd) {
		t.Fatalf("down must be refused in prod, got %v", err)
	}

	pool, err := database.Open(ctx, appURL, database.PoolOptions{MaxConns: 2, StatementTimeout: 5 * time.Second, AppName: "riung-test"})
	if err != nil {
		t.Fatalf("open as riung_app: %v", err)
	}
	defer pool.Close()

	exec := func(sql string, args ...any) error {
		_, err := pool.Exec(ctx, sql, args...)
		return err
	}
	mustOK := func(what, sql string, args ...any) {
		t.Helper()
		if err := exec(sql, args...); err != nil {
			t.Fatalf("%s: %v", what, err)
		}
	}
	mustDeny := func(what, sql string, args ...any) {
		t.Helper()
		err := exec(sql, args...)
		var pgErr *pgconn.PgError
		if !errors.As(err, &pgErr) || pgErr.Code != "42501" { // insufficient_privilege
			t.Fatalf("%s: want permission denied, got %v", what, err)
		}
	}

	var userID string
	if err := pool.QueryRow(ctx, `INSERT INTO users (is_anonymous) VALUES (true) RETURNING id`).Scan(&userID); err != nil {
		t.Fatalf("insert user: %v", err)
	}
	mustOK("insert wallet", `INSERT INTO wallets (user_id, earned_coins, lifetime_earned) VALUES ($1, 5, 5)`, userID)
	mustOK("insert ledger", `INSERT INTO coin_ledger (user_id, type, amount, earned_delta, reason, idempotency_key, balance_after)
		VALUES ($1, 'earn', 5, 5, 'checkin', 'checkin:2026-10-11', 5)`, userID)
	mustOK("insert purchase", `INSERT INTO purchases (purchase_token, user_id, user_hash, product_id, kind, state)
		VALUES ('tok-1', $1, 'u_x', 'coin_pack_small', 'consumable', 'purchased')`, userID)
	mustOK("insert audit", `INSERT INTO admin_audit_log (actor, action, reason) VALUES ('cli', 'setting.set', 'test reason')`)

	// The ledger is idempotent per user.
	if err := exec(`INSERT INTO coin_ledger (user_id, type, amount, earned_delta, reason, idempotency_key, balance_after)
		VALUES ($1, 'earn', 5, 5, 'checkin', 'checkin:2026-10-11', 10)`, userID); err == nil || !strings.Contains(err.Error(), "duplicate key") {
		t.Fatalf("duplicate idempotency key must be rejected, got %v", err)
	}
	// Balances can never go negative.
	if err := exec(`UPDATE wallets SET earned_coins = -1 WHERE user_id = $1`, userID); err == nil {
		t.Fatal("negative balance must violate the CHECK constraint")
	}

	// Append-only trails.
	mustDeny("update ledger", `UPDATE coin_ledger SET amount = 500 WHERE user_id = $1`, userID)
	mustDeny("delete ledger", `DELETE FROM coin_ledger WHERE user_id = $1`, userID)
	mustDeny("update audit", `UPDATE admin_audit_log SET reason = 'rewritten'`)
	mustDeny("delete audit", `DELETE FROM admin_audit_log`)
	mustDeny("truncate ledger", `TRUNCATE coin_ledger`)
	// Purchases: status columns only.
	mustOK("update purchase state", `UPDATE purchases SET state = 'voided', voided_at = now() WHERE purchase_token = 'tok-1'`)
	mustDeny("update purchase product", `UPDATE purchases SET product_id = 'coin_pack_large' WHERE purchase_token = 'tok-1'`)
	mustDeny("delete purchase", `DELETE FROM purchases WHERE purchase_token = 'tok-1'`)
	// Processed practice events are append-only too.
	mustOK("insert activity", `INSERT INTO activity_events (user_id, key, type, result) VALUES ($1, 'checkin:2026-10-12', 'checkin', '{}')`, userID)
	mustDeny("update activity", `UPDATE activity_events SET result = '{"coinsGranted":999}'`)
	mustDeny("delete activity", `DELETE FROM activity_events`)
	// No DDL for the API role.
	mustDeny("create table", `CREATE TABLE evil (id int)`)

	// Account deletion cascades through the append-only ledger and keeps the
	// purchase anonymised, even though riung_app cannot delete those rows.
	mustOK("delete user", `DELETE FROM users WHERE id = $1`, userID)
	var ledgerRows int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM coin_ledger WHERE user_id = $1`, userID).Scan(&ledgerRows); err != nil || ledgerRows != 0 {
		t.Fatalf("ledger rows after delete: %d (%v)", ledgerRows, err)
	}
	var purchaseUser *string
	if err := pool.QueryRow(ctx, `SELECT user_id::text FROM purchases WHERE purchase_token = 'tok-1'`).Scan(&purchaseUser); err != nil || purchaseUser != nil {
		t.Fatalf("purchase should be kept with user_id NULL, got %v (%v)", purchaseUser, err)
	}
}
