package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// runAppStoreCheck proves the App Store configuration without a purchase:
// Apple accepts the In-App Purchase key for the bundle id (no 401), and with
// --notify Apple delivers a TEST notification to the production and sandbox
// URLs set in App Store Connect (the webhook must answer 200).
func runAppStoreCheck(ctx context.Context, cfg config.Config, args []string, logger *slog.Logger) error {
	notify := false
	for _, a := range args {
		switch a {
		case "--notify":
			notify = true
		default:
			return fmt.Errorf("unknown argument %q (want --notify)", a)
		}
	}
	if cfg.DevBilling || cfg.AppStoreBundleID == "" {
		return errors.New("app store billing is not configured (APPSTORE_* in .env)")
	}
	key, err := os.ReadFile(cfg.AppStorePrivateKeyFile)
	if err != nil {
		return fmt.Errorf("read APPSTORE_PRIVATE_KEY_FILE: %w", err)
	}
	client, err := appstore.NewClient(appstore.ClientOptions{BundleID: cfg.AppStoreBundleID, IssuerID: cfg.AppStoreIssuerID,
		KeyID: cfg.AppStoreKeyID, PrivateKeyPEM: key})
	if err != nil {
		return err
	}
	// The sandbox must accept the key. Production answers 401 until the app's
	// first release, which is reported but not a failure.
	if err := client.CheckAuth(ctx, true); err != nil {
		return fmt.Errorf("app store server API (sandbox): %w", err)
	}
	prodErr := client.CheckAuth(ctx, false)
	if prodErr != nil && !errors.Is(prodErr, appstore.ErrAuth) {
		return fmt.Errorf("app store server API (production): %w", prodErr)
	}
	logger.Info("app store key accepted", logx.KeyEvent, "appstore_check", "bundleId", cfg.AppStoreBundleID,
		"keyId", cfg.AppStoreKeyID, "sandbox", true, "production", prodErr == nil)
	if prodErr != nil {
		logger.Warn("app store production API answers 401: normal until the app's first release", logx.KeyEvent, "appstore_check")
	}
	if !notify {
		return nil
	}
	failed := false
	for _, env := range []struct {
		name    string
		sandbox bool
	}{{"production", false}, {"sandbox", true}} {
		if !env.sandbox && prodErr != nil {
			continue // not possible before the first release
		}
		result, err := testNotification(ctx, client, env.sandbox)
		if err != nil {
			return fmt.Errorf("%s test notification: %w", env.name, err)
		}
		level := slog.LevelInfo
		if result != "SUCCESS" {
			level, failed = slog.LevelWarn, true
		}
		logger.Log(ctx, level, "app store test notification", logx.KeyEvent, "appstore_check",
			"environment", env.name, "result", result)
	}
	if failed {
		return errors.New("apple could not deliver a test notification: check the URLs in App Store Connect and /v1/webhooks/app-store")
	}
	return nil
}

// testNotification requests one TEST notification and waits up to 60 s for
// Apple's delivery result.
func testNotification(ctx context.Context, client *appstore.Client, sandbox bool) (string, error) {
	token, err := client.RequestTestNotification(ctx, sandbox)
	if err != nil {
		return "", err
	}
	deadline := time.Now().Add(60 * time.Second)
	for {
		select {
		case <-ctx.Done():
			return "", ctx.Err()
		case <-time.After(3 * time.Second):
		}
		result, err := client.TestNotificationResult(ctx, sandbox, token)
		if err != nil && !errors.Is(err, appstore.ErrNotFound) { // not recorded yet → 404
			return "", err
		}
		if result != "" {
			return result, nil
		}
		if time.Now().After(deadline) {
			return "NOT_SENT_WITHIN_60S", nil
		}
	}
}
