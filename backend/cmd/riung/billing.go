package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// newBilling builds the billing service: fakes of Play and the App Store in
// DEV_BILLING; otherwise the Android Publisher client when PLAY_PACKAGE_NAME
// is set and the App Store Server API client when APPSTORE_BUNDLE_ID is set.
// A store that is not configured answers 503 on its endpoints.
func newBilling(ctx context.Context, cfg config.Config, st *store.Store, econ economy.Props, hasher logx.Hasher,
	logger *slog.Logger) (*billing.Service, billing.PushVerifier, error) {
	svc := &billing.Service{Store: st, Economy: econ, Hasher: hasher, AccountKey: cfg.BillingAccountKey, Now: nowFunc}
	if cfg.DevBilling {
		logger.Warn("DEV_BILLING enabled: Google Play and the App Store are faked (dev-coin:/dev-sub: ids)",
			logx.KeyEvent, logx.EventStartup)
		svc.Publisher = billing.NewFakePublisher()
		fake := appstore.NewFake(cfg.AppStoreBundleID)
		fake.Now = nowFunc
		svc.AppStore = fake
		return svc, billing.DevPushVerifier{}, nil
	}
	if cfg.AppStoreBundleID != "" {
		key, err := os.ReadFile(cfg.AppStorePrivateKeyFile)
		if err != nil {
			return nil, nil, fmt.Errorf("read APPSTORE_PRIVATE_KEY_FILE: %w", err)
		}
		client, err := appstore.NewClient(appstore.ClientOptions{BundleID: cfg.AppStoreBundleID, IssuerID: cfg.AppStoreIssuerID,
			KeyID: cfg.AppStoreKeyID, PrivateKeyPEM: key, Now: nowFunc})
		if err != nil {
			return nil, nil, err
		}
		svc.AppStore = client
	}
	if cfg.PlayPackageName == "" {
		return svc, nil, nil
	}
	pub, err := billing.NewGooglePublisher(ctx, cfg.PlayPackageName, cfg.PlayCredentialsFile)
	if err != nil {
		return nil, nil, err
	}
	svc.Publisher = pub
	return svc, billing.GooglePushVerifier{Audience: cfg.RTDNAudience, ServiceAccount: cfg.RTDNServiceAccount}, nil
}

func runBillingSync(ctx context.Context, cfg config.Config, logger *slog.Logger) error {
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	if !cfg.BillingEnabled() {
		// Not an error: the hourly cron runs before billing is set up.
		logger.Info("billing sync skipped: billing is not configured", logx.KeyEvent, "job_run", "job", "billing_sync",
			"ok", true, "skipped", true)
		return nil
	}
	econ, err := economy.Load()
	if err != nil {
		return err
	}
	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()
	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)
	svc, _, err := newBilling(ctx, cfg, st, econ, hasher, logger)
	if err != nil {
		return err
	}
	res, err := svc.Sync(ctx)
	for _, e := range res.Errors {
		logger.Error("billing sync item failed", logx.KeyEvent, logx.EventDependencyError, "op", "billing_sync", "error", e.Error())
	}
	for _, r := range res.Refunded {
		logger.Warn("refund applied", logx.KeyEvent, "refund_applied", logx.KeyUser, r.UserHash,
			"productId", r.ProductID, "coinsClawedBack", r.Clawed, "debt", r.Debt, "premiumRevoked", r.Revoked, "orphan", r.WasOrphan)
	}
	if err != nil {
		logger.Error("billing sync failed", logx.KeyEvent, "job_run", "job", "billing_sync", "ok", false, "error", err.Error())
		return err
	}
	logger.Info("billing sync done", logx.KeyEvent, "job_run", "job", "billing_sync", "ok", res.OK(),
		"voidedSeen", res.Voided, "refunded", len(res.Refunded), "voidFailed", res.VoidFailed,
		"acknowledged", res.Acknowledged, "ackFailed", res.AckFailed)
	if !res.OK() {
		return errors.New("some purchases could not be processed; retried on the next run")
	}
	return nil
}

// runReconcile fails (exit 1, an alert in Loki) when any wallet differs from
// the sum of its ledger: that would mean a bug or a manual DB edit.
func runReconcile(ctx context.Context, cfg config.Config, logger *slog.Logger) error {
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()
	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)
	bad, checked, err := st.Reconcile(ctx)
	if err != nil {
		return err
	}
	for _, m := range bad {
		logger.Error("wallet does not match ledger", logx.KeyEvent, "ledger_mismatch", logx.KeyUser, hasher.User(m.UserID),
			"earned", m.Earned, "ledgerEarned", m.LedgerEarned, "purchased", m.Purchased, "ledgerPurchased", m.LedgerPurchased,
			"debt", m.Debt, "ledgerDebt", m.LedgerDebt)
	}
	logger.Info("reconcile done", logx.KeyEvent, "job_run", "job", "reconcile", "ok", len(bad) == 0,
		"wallets", checked, "mismatches", len(bad))
	if len(bad) > 0 {
		return errors.New("ledger mismatch")
	}
	return nil
}
