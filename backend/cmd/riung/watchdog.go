package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/alert"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/watchdog"
)

// runWatchdog checks the API from outside (host cron, own container) and
// alerts on what changed since the last run. Settings (defaults in brackets):
//
//	WATCHDOG_API_URL     [http://riung-api:8080]  /readyz must answer 200
//	WATCHDOG_PUBLIC_URL  []                       e.g. https://riung.e55techlab.com/healthz
//	WATCHDOG_LOKI_URL    []                       e.g. http://shared-loki:3100 (5xx, p95, cron jobs)
//	WATCHDOG_CONTAINER   [riung-api]              Loki container label
//	WATCHDOG_BACKUP_DIR  []                       e.g. /backups (newest *.dump < 26 h)
//	WATCHDOG_STATE_FILE  [/state/watchdog.json]
//
// Failures are reported through Telegram (event watchdog_alert), not the exit
// code: the cron line only fails when the watchdog itself cannot run.
func runWatchdog(ctx context.Context, _ config.Config, logger *slog.Logger) error {
	env := func(k, def string) string {
		if v := strings.TrimSpace(os.Getenv(k)); v != "" {
			return v
		}
		return def
	}
	c := watchdog.Config{
		APIURL:    env("WATCHDOG_API_URL", "http://riung-api:8080"),
		PublicURL: env("WATCHDOG_PUBLIC_URL", ""),
		LokiURL:   env("WATCHDOG_LOKI_URL", ""),
		Container: env("WATCHDOG_CONTAINER", "riung-api"),
		BackupDir: env("WATCHDOG_BACKUP_DIR", ""),
		Now:       nowFunc,
	}
	statePath := env("WATCHDOG_STATE_FILE", "/state/watchdog.json")
	prev, err := watchdog.LoadState(statePath)
	if err != nil {
		return err
	}
	results := watchdog.Run(ctx, c)
	next, msgs := watchdog.Evaluate(prev, results, nowFunc())
	failing := 0
	for _, r := range results {
		if !r.OK {
			failing++
		}
	}
	for _, m := range msgs {
		level := slog.LevelWarn
		if m.Recovery {
			level = slog.LevelInfo
		}
		logger.Log(ctx, level, m.Text, logx.KeyEvent, "watchdog_alert", "check", m.Check, "recovery", m.Recovery)
	}
	if err := watchdog.SaveState(statePath, next); err != nil {
		return err
	}
	logger.Info("watchdog done", logx.KeyEvent, "job_run", "job", "watchdog", "ok", failing == 0,
		"checks", len(results), "failing", failing, "alerts", len(msgs))
	return nil
}

// runAlertTest sends one message through ALERT_TELEGRAM_* and waits for
// Telegram's answer (setup check; alarms themselves are sent in background).
func runAlertTest(ctx context.Context, cfg config.Config, logger *slog.Logger) error {
	if cfg.AlertTelegramToken == "" {
		return errors.New("ALERT_TELEGRAM_BOT_TOKEN / ALERT_TELEGRAM_CHAT_ID are not set")
	}
	host, _ := os.Hostname()
	tg := &alert.Telegram{Token: cfg.AlertTelegramToken, ChatID: cfg.AlertTelegramChatID}
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	if err := tg.Send(ctx, fmt.Sprintf("%s · 🧪 tes alarm (versi %s, host %s)", cfg.AlertLabel, version, host)); err != nil {
		return err
	}
	logger.Info("alert test sent", logx.KeyEvent, "alert_test")
	return nil
}
