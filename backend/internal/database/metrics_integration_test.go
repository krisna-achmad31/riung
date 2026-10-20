package database_test

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"os"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/krisna-achmad31/riung/backend/internal/database"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

// TestMetricsViews: the Grafana role sees aggregates and nothing else.
func TestMetricsViews(t *testing.T) {
	urls := testdb.Create(t)
	ctx := context.Background()
	admin, err := pgx.Connect(ctx, os.Getenv("RIUNG_TEST_DATABASE_URL"))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = admin.Close(ctx) }()
	// Cluster-wide role, created like create-riung-metrics-role.sql would.
	if _, err := admin.Exec(ctx, `CREATE ROLE riung_metrics NOLOGIN`); err != nil {
		var pgErr *pgconn.PgError
		if !errors.As(err, &pgErr) || pgErr.Code != "42710" { // duplicate_object
			t.Fatal(err)
		}
	}
	if err := database.Migrate(ctx, urls.Migrator, database.MigrateUp, false, logx.New(io.Discard, slog.LevelError)); err != nil {
		t.Fatal(err)
	}
	owner, err := pgx.Connect(ctx, urls.Migrator)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = owner.Close(ctx) }()

	var u1, u2 string
	must := func(sql string, args ...any) {
		t.Helper()
		if _, err := owner.Exec(ctx, sql, args...); err != nil {
			t.Fatalf("%s: %v", sql, err)
		}
	}
	if err := owner.QueryRow(ctx, `INSERT INTO users (is_anonymous) VALUES (false) RETURNING id`).Scan(&u1); err != nil {
		t.Fatal(err)
	}
	if err := owner.QueryRow(ctx, `INSERT INTO users (is_anonymous) VALUES (true) RETURNING id`).Scan(&u2); err != nil {
		t.Fatal(err)
	}
	must(`INSERT INTO activity_events (user_id, key, type, result) VALUES ($1, 'checkin:1', 'checkin', '{}'), ($2, 'checkin:2', 'checkin', '{}'), ($1, 'journal:1', 'journal_saved', '{}')`, u1, u2)
	must(`INSERT INTO coin_ledger (user_id, type, amount, earned_delta, reason, idempotency_key, balance_after)
		VALUES ($1, 'earn', 5, 5, 'checkin', 'k1', 5), ($2, 'earn', 5, 5, 'checkin', 'k2', 5)`, u1, u2)
	must(`INSERT INTO purchases (purchase_token, user_id, user_hash, product_id, kind, state, raw) VALUES
		('play-tok-1', $1, 'u_1', 'coin_pack_small', 'consumable', 'purchased', '{"Test": false}'),
		('appstore:2000000001', $1, 'u_1', 'coin_pack_small', 'consumable', 'purchased', '{"environment": "Sandbox"}')`, u1)

	var accounts, permanent int
	if err := owner.QueryRow(ctx, `SELECT accounts, permanent FROM metrics.users_summary`).Scan(&accounts, &permanent); err != nil || accounts != 2 || permanent != 1 {
		t.Fatalf("users_summary: %d %d %v", accounts, permanent, err)
	}
	var dau int
	if err := owner.QueryRow(ctx, `SELECT sum(users) FROM metrics.daily_active_users`).Scan(&dau); err != nil || dau != 2 {
		t.Fatalf("daily_active_users: %d %v", dau, err)
	}
	var coins int
	if err := owner.QueryRow(ctx, `SELECT sum(coins) FROM metrics.daily_coins WHERE type = 'earn' AND reason = 'checkin'`).Scan(&coins); err != nil || coins != 10 {
		t.Fatalf("daily_coins: %d %v", coins, err)
	}
	rows, err := owner.Query(ctx, `SELECT store, test, purchases FROM metrics.daily_purchases ORDER BY store`)
	if err != nil {
		t.Fatal(err)
	}
	type row struct {
		store string
		test  bool
		n     int
	}
	var got []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.store, &r.test, &r.n); err != nil {
			t.Fatal(err)
		}
		got = append(got, r)
	}
	if len(got) != 2 || got[0] != (row{"app_store", true, 1}) || got[1] != (row{"play", false, 1}) {
		t.Fatalf("daily_purchases: %+v", got)
	}
	// Every view must at least run.
	for _, v := range []string{"daily_signups", "daily_activity", "premium_status", "monster_states", "daily_focus", "daily_appbeku", "daily_waitlist"} {
		if _, err := owner.Exec(ctx, `SELECT * FROM metrics.`+v); err != nil {
			t.Fatalf("%s: %v", v, err)
		}
	}

	privilege := func(role, table string) bool {
		var ok bool
		if err := owner.QueryRow(ctx, `SELECT has_table_privilege($1, $2, 'SELECT')`, role, table).Scan(&ok); err != nil {
			t.Fatal(err)
		}
		return ok
	}
	if !privilege("riung_metrics", "metrics.daily_coins") || !privilege("riung_metrics", "metrics.users_summary") {
		t.Fatal("riung_metrics must read the views")
	}
	for _, table := range []string{"public.users", "public.coin_ledger", "public.purchases", "public.journal_pin_backups"} {
		if privilege("riung_metrics", table) {
			t.Fatalf("riung_metrics must not read %s", table)
		}
	}
	if privilege("riung_app", "metrics.daily_coins") {
		t.Fatal("the API role has no business with the metrics views")
	}
}
