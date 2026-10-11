// Package testdb provisions throwaway, fully migrated databases for
// integration tests. Tests are skipped unless RIUNG_TEST_DATABASE_URL points
// at a Postgres superuser connection.
//
// Missing riung_migrator / riung_app roles are created with the passwords in
// RIUNG_TEST_MIGRATOR_PASSWORD / RIUNG_TEST_APP_PASSWORD (default "test");
// existing roles are left untouched, so set those variables to their real
// passwords when reusing a server (e.g. the dev compose stack).
package testdb

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io"
	"log/slog"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/krisna-achmad31/riung/backend/internal/database"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// URLs of a provisioned database.
type URLs struct {
	Migrator string
	App      string
}

// Create makes an empty database owned by riung_migrator (not migrated).
func Create(t testing.TB) URLs {
	t.Helper()
	admin := os.Getenv("RIUNG_TEST_DATABASE_URL")
	if admin == "" {
		t.Skip("RIUNG_TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, admin)
	if err != nil {
		t.Fatalf("testdb: connect admin: %v", err)
	}
	defer func() { _ = conn.Close(ctx) }()

	passwords := map[string]string{
		"riung_migrator": envOr("RIUNG_TEST_MIGRATOR_PASSWORD", "test"),
		"riung_app":      envOr("RIUNG_TEST_APP_PASSWORD", "test"),
	}
	for role, pw := range passwords {
		var exists bool
		if err := conn.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = $1)`, role).Scan(&exists); err != nil {
			t.Fatalf("testdb: check role %s: %v", role, err)
		}
		if exists {
			continue
		}
		quoted := "'" + strings.ReplaceAll(pw, "'", "''") + "'"
		if _, err := conn.Exec(ctx, "CREATE ROLE "+role+" LOGIN PASSWORD "+quoted); err != nil {
			// A parallel test package may have created it meanwhile
			// (42710 duplicate_object, or 23505 on the catalog index).
			var pgErr *pgconn.PgError
			if !errors.As(err, &pgErr) || (pgErr.Code != "42710" && pgErr.Code != "23505") {
				t.Fatalf("testdb: create role %s: %v", role, err)
			}
		}
	}

	suffix := make([]byte, 6)
	_, _ = rand.Read(suffix)
	name := "riung_test_" + hex.EncodeToString(suffix)
	if _, err := conn.Exec(ctx, "CREATE DATABASE "+name+" OWNER riung_migrator"); err != nil {
		t.Fatalf("testdb: create database: %v", err)
	}
	t.Cleanup(func() {
		c, err := pgx.Connect(context.Background(), admin)
		if err != nil {
			return
		}
		defer func() { _ = c.Close(context.Background()) }()
		_, _ = c.Exec(context.Background(), "DROP DATABASE IF EXISTS "+name+" WITH (FORCE)")
	})

	u, err := url.Parse(admin)
	if err != nil {
		t.Fatalf("testdb: parse url: %v", err)
	}
	withRole := func(role string) string {
		c := *u
		c.User = url.UserPassword(role, passwords[role])
		c.Path = "/" + name
		return c.String()
	}
	return URLs{Migrator: withRole("riung_migrator"), App: withRole("riung_app")}
}

// Pool returns a migrated database and a pool connected as riung_app.
func Pool(t testing.TB) *pgxpool.Pool {
	t.Helper()
	urls := Create(t)
	ctx := context.Background()
	logger := logx.New(io.Discard, slog.LevelError)
	if err := database.Migrate(ctx, urls.Migrator, database.MigrateUp, false, logger); err != nil {
		t.Fatalf("testdb: migrate: %v", err)
	}
	pool, err := database.Open(ctx, urls.App, database.PoolOptions{MaxConns: 8, StatementTimeout: 10 * time.Second, AppName: "riung-test"})
	if err != nil {
		t.Fatalf("testdb: open pool: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
