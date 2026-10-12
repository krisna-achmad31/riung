// Command riung is the single backend binary:
//
//	riung api                     serve the HTTP API
//	riung migrate up|status|down  apply embedded migrations (MIGRATE_DATABASE_URL)
//	riung seed-content <file|->   load public content from a seed JSON (DATABASE_URL)
//	riung settings list|set|reset admin-adjustable settings (audited as "cli")
//	riung cleanup                 daily housekeeping (cron)
//	riung billing-sync            apply Play refunds, acknowledge late subscriptions (cron)
//	riung reconcile               check every wallet against its ledger (cron)
//	riung admin grant|revoke      give/remove Admin API access (needs Firebase credentials)
//	riung healthcheck             probe the local /healthz (Docker HEALTHCHECK)
//	riung version                 print the build version
package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/api"
	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/database"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/ratelimit"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// version is set at build time with -ldflags "-X main.version=...".
var version = "dev"

const usage = `usage:
  riung api
  riung migrate up|status|down
  riung seed-content <file|->
  riung settings list
  riung settings set <key> <value> <reason...>
  riung settings reset <key> <reason...>
  riung admin grant|revoke <email> <reason...>
  riung cleanup
  riung billing-sync
  riung reconcile
  riung healthcheck
  riung version`

func main() {
	os.Exit(run(os.Args[1:]))
}

func run(args []string) int {
	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, usage)
		return 2
	}
	switch args[0] {
	case "version":
		fmt.Println(version)
		return 0
	case "healthcheck":
		return healthcheck()
	}

	cfg, err := config.Load(os.Getenv)
	logger := logx.New(os.Stdout, cfg.LogLevel)
	if err != nil {
		logger.Error("invalid configuration", logx.KeyEvent, logx.EventCommandError, "error", err.Error())
		return 1
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	switch args[0] {
	case "api":
		err = runAPI(ctx, cfg, logger)
	case "migrate":
		cmd := database.MigrateUp
		if len(args) > 1 {
			cmd = args[1]
		}
		err = runMigrate(ctx, cfg, cmd, logger)
	case "settings":
		err = runSettings(ctx, cfg, args[1:], logger)
	case "cleanup":
		err = runCleanup(ctx, cfg, logger)
	case "billing-sync":
		err = runBillingSync(ctx, cfg, logger)
	case "reconcile":
		err = runReconcile(ctx, cfg, logger)
	case "admin":
		err = runAdmin(ctx, cfg, args[1:], logger)
	case "seed-content":
		src := "-"
		if len(args) > 1 {
			src = args[1]
		}
		err = runSeedContent(ctx, cfg, src, logger)
	default:
		fmt.Fprintf(os.Stderr, "unknown command %q\n", args[0])
		return 2
	}
	if err != nil {
		logger.Error("command failed", logx.KeyEvent, logx.EventCommandError, "command", args[0], "error", err.Error())
		return 1
	}
	return 0
}

func runMigrate(ctx context.Context, cfg config.Config, cmd string, logger *slog.Logger) error {
	if err := cfg.ValidateMigrate(); err != nil {
		return err
	}
	return database.Migrate(ctx, cfg.MigrationURL(), cmd, cfg.Env == config.EnvProd, logger)
}

func openStore(ctx context.Context, cfg config.Config) (*store.Store, func(), error) {
	pool, err := database.Open(ctx, cfg.DatabaseURL, database.PoolOptions{
		MaxConns:         cfg.DBMaxConns,
		StatementTimeout: cfg.DBStatementTimeout,
		AppName:          "riung-api",
	})
	if err != nil {
		return nil, nil, err
	}
	return store.New(pool), pool.Close, nil
}

func runAPI(ctx context.Context, cfg config.Config, logger *slog.Logger) error {
	if err := cfg.ValidateAPI(); err != nil {
		return err
	}
	econ, err := economy.Load()
	if err != nil {
		return err
	}
	cat, err := catalog.Load(econ)
	if err != nil {
		return err
	}

	var (
		verifier authn.Verifier
		appCheck authn.AppChecker
	)
	if cfg.DevAuth {
		logger.Warn("DEV_AUTH enabled: accepting dev:<uid>:<provider> tokens", logx.KeyEvent, logx.EventStartup)
		verifier, appCheck = &authn.DevVerifier{}, authn.DevAppChecker{}
	} else {
		fb, err := authn.NewFirebase(ctx, authn.FirebaseOptions{
			ProjectID:       cfg.FirebaseProjectID,
			CredentialsFile: cfg.FirebaseCredentialsFile,
		})
		if err != nil {
			return err
		}
		verifier, appCheck = fb, fb.AppCheck()
	}

	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()

	limiter := ratelimit.New(nil)
	go limiter.Run(ctx, 5*time.Minute, 2*time.Hour)

	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)
	bill, push, err := newBilling(ctx, cfg, st, econ, hasher, logger)
	if err != nil {
		return err
	}
	deps := api.Deps{
		Config:   cfg,
		Logger:   logger,
		Hasher:   hasher,
		Store:    st,
		Verifier: verifier,
		AppCheck: appCheck,
		Economy:  econ,
		Catalog:  cat,
		Limiter:  limiter,
		Settings: settings.NewCache(st, econ.Caps, 30*time.Second, time.Now),
		Billing:  bill,
		Push:     push,
	}
	servers := []*http.Server{httpx.NewServer(cfg.ListenAddr, api.NewHandler(deps))}
	if cfg.AdminListenAddr != "" {
		servers = append(servers, httpx.NewServer(cfg.AdminListenAddr, api.NewAdminHandler(deps)))
	}

	errCh := make(chan error, len(servers))
	for i, srv := range servers {
		srv.ErrorLog = slog.NewLogLogger(logger.Handler(), slog.LevelWarn)
		name := "api"
		if i == 1 {
			name = "admin"
		}
		go func(srv *http.Server, name string) {
			logger.Info(name+" listening", logx.KeyEvent, logx.EventStartup, "addr", srv.Addr, "version", version,
				"env", cfg.Env, "appCheck", cfg.AppCheckMode, "economy", econ.Version, "catalog", cat.Version,
				"billing", cfg.BillingEnabled())
			if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
				errCh <- fmt.Errorf("%s server: %w", name, err)
			}
		}(srv, name)
	}

	var runErr error
	select {
	case runErr = <-errCh:
	case <-ctx.Done():
	}

	logger.Info("shutting down", logx.KeyEvent, logx.EventShutdown)
	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()
	for _, srv := range servers {
		if err := srv.Shutdown(shutdownCtx); err != nil && runErr == nil {
			runErr = err
		}
	}
	return runErr
}

func nowFunc() time.Time { return time.Now() }

func runCleanup(ctx context.Context, cfg config.Config, logger *slog.Logger) error {
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()
	res, err := st.Purge(ctx)
	if err != nil {
		logger.Error("cleanup failed", logx.KeyEvent, "job_run", "job", "cleanup", "ok", false, "error", err.Error())
		return err
	}
	logger.Info("cleanup done", logx.KeyEvent, "job_run", "job", "cleanup", "ok", true,
		"idempotencyKeys", res.IdempotencyKeys, "appCheckJtis", res.AppCheckJTIs, "signupCounters", res.SignupCounters,
		"dailyCounters", res.DailyCounters, "pinAttempts", res.PinAttempts, "rtdnMessages", res.RTDNMessages)
	return nil
}

// healthcheck calls the local liveness endpoint; distroless has no curl.
func healthcheck() int {
	port := 8080
	if addr := os.Getenv("LISTEN_ADDR"); addr != "" {
		if _, p, err := net.SplitHostPort(addr); err == nil {
			if n, err := strconv.Atoi(p); err == nil && n > 0 && n < 65536 {
				port = n
			}
		}
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	// Fixed loopback host and a numeric port: not attacker-controlled.
	url := "http://127.0.0.1:" + strconv.Itoa(port) + "/healthz"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil) //nolint:gosec // G704: loopback probe of our own port
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck:", err)
		return 1
	}
	resp, err := http.DefaultClient.Do(req) //nolint:gosec // G704: loopback probe of our own port
	if err != nil {
		fmt.Fprintln(os.Stderr, "healthcheck:", err)
		return 1
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		fmt.Fprintln(os.Stderr, "healthcheck: status", resp.StatusCode)
		return 1
	}
	return 0
}
