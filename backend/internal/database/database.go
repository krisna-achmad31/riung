// Package database opens the Postgres pool and runs embedded migrations.
package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io/fs"
	"log/slog"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"

	riungdb "github.com/krisna-achmad31/riung/backend/db"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// PoolOptions tunes the API connection pool.
type PoolOptions struct {
	MaxConns         int32
	StatementTimeout time.Duration
	AppName          string
	// ConnectWait keeps retrying the first ping for up to this long (0 = one
	// try). After a host reboot the API container can start before
	// shared-postgres is up or its name resolves.
	ConnectWait time.Duration
	// Logger gets one warning per failed attempt while waiting (optional).
	Logger *slog.Logger
}

// Retry delays while waiting for the database: doubling, capped.
const (
	connectRetryFirst = 500 * time.Millisecond
	connectRetryMax   = 5 * time.Second
)

// Open connects the pool and verifies it with a ping. Every session gets a
// statement_timeout so one slow query cannot pin a connection.
func Open(ctx context.Context, url string, opt PoolOptions) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	cfg.MaxConns = opt.MaxConns
	cfg.MaxConnIdleTime = 5 * time.Minute
	cfg.HealthCheckPeriod = 30 * time.Second
	rp := cfg.ConnConfig.RuntimeParams
	rp["statement_timeout"] = strconv.FormatInt(opt.StatementTimeout.Milliseconds(), 10)
	rp["idle_in_transaction_session_timeout"] = "30000"
	rp["timezone"] = "UTC"
	if opt.AppName != "" {
		rp["application_name"] = opt.AppName
	}

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("create pool: %w", err)
	}
	if err := waitForPing(ctx, pool, opt); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

// waitForPing pings until it succeeds, ctx ends, or the next retry would
// pass opt.ConnectWait. Failed attempts before the last are warnings, so a
// slow database start does not raise the server-error alert.
func waitForPing(ctx context.Context, pool *pgxpool.Pool, opt PoolOptions) error {
	start := time.Now()
	delay := connectRetryFirst
	for attempt := 1; ; attempt++ {
		pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		err := pool.Ping(pingCtx)
		cancel()
		if err == nil {
			if attempt > 1 && opt.Logger != nil {
				opt.Logger.LogAttrs(ctx, slog.LevelInfo, "database ready",
					slog.String(logx.KeyEvent, logx.EventStartup),
					slog.Int("attempt", attempt), slog.Int64("waitedMs", time.Since(start).Milliseconds()))
			}
			return nil
		}
		if ctx.Err() != nil || time.Since(start)+delay > opt.ConnectWait {
			return fmt.Errorf("ping database (attempt %d): %w", attempt, err)
		}
		if opt.Logger != nil {
			opt.Logger.LogAttrs(ctx, slog.LevelWarn, "database not ready, retrying",
				slog.String(logx.KeyEvent, logx.EventStartup),
				slog.Int("attempt", attempt), slog.Int64("retryInMs", delay.Milliseconds()),
				slog.String("error", err.Error()))
		}
		select {
		case <-ctx.Done():
			return fmt.Errorf("ping database (attempt %d): %w", attempt, err)
		case <-time.After(delay):
		}
		delay = min(2*delay, connectRetryMax)
	}
}

// Migration commands accepted by Migrate.
const (
	MigrateUp     = "up"
	MigrateStatus = "status"
	MigrateDown   = "down" // rolls back one version; refused in prod
)

// ErrDownInProd guards against rolling back production schema by accident.
var ErrDownInProd = errors.New("migrate down is disabled when RIUNG_ENV=prod")

// Migrate runs a goose command against url using the embedded migrations.
func Migrate(ctx context.Context, url, command string, prod bool, logger *slog.Logger) error {
	if command == MigrateDown && prod {
		return ErrDownInProd
	}
	connCfg, err := pgx.ParseConfig(url)
	if err != nil {
		return fmt.Errorf("parse MIGRATE_DATABASE_URL: %w", err)
	}
	connCfg.RuntimeParams["application_name"] = "riung-migrate"
	sqlDB := stdlib.OpenDB(*connCfg)
	defer func() { _ = sqlDB.Close() }()

	provider, err := newProvider(sqlDB)
	if err != nil {
		return err
	}

	switch command {
	case MigrateUp:
		results, err := provider.Up(ctx)
		for _, r := range results {
			logResult(ctx, logger, r)
		}
		if err == nil && len(results) == 0 {
			logger.LogAttrs(ctx, slog.LevelInfo, "database already up to date",
				slog.String(logx.KeyEvent, logx.EventMigration))
		}
		return err
	case MigrateDown:
		r, err := provider.Down(ctx)
		if r != nil {
			logResult(ctx, logger, r)
		}
		return err
	case MigrateStatus:
		statuses, err := provider.Status(ctx)
		if err != nil {
			return err
		}
		for _, s := range statuses {
			logger.LogAttrs(ctx, slog.LevelInfo, "migration status",
				slog.String(logx.KeyEvent, logx.EventMigration),
				slog.Int64("version", s.Source.Version),
				slog.String("file", s.Source.Path),
				slog.String("state", string(s.State)),
			)
		}
		return nil
	default:
		return fmt.Errorf("unknown migrate command %q (want up, status or down)", command)
	}
}

func newProvider(sqlDB *sql.DB) (*goose.Provider, error) {
	fsys, err := fs.Sub(riungdb.Migrations, "migrations")
	if err != nil {
		return nil, err
	}
	return goose.NewProvider(goose.DialectPostgres, sqlDB, fsys)
}

func logResult(ctx context.Context, logger *slog.Logger, r *goose.MigrationResult) {
	level := slog.LevelInfo
	attrs := []slog.Attr{
		slog.String(logx.KeyEvent, logx.EventMigration),
		slog.Int64("version", r.Source.Version),
		slog.String("file", r.Source.Path),
		slog.String("direction", r.Direction),
		slog.Int64("durationMs", r.Duration.Milliseconds()),
	}
	if r.Error != nil {
		level = slog.LevelError
		attrs = append(attrs, slog.String("error", r.Error.Error()))
	}
	logger.LogAttrs(ctx, level, "migration applied", attrs...)
}
