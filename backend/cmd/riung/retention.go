package main

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// anonBatch bounds one cleanup-anon run; the daily cron catches up.
const anonBatch = 1000

// runCleanupAnon deletes anonymous accounts inactive for ANON_RETENTION_DAYS
// (docs/backend-go-plan.md §7): server data first, then the Firebase user.
// With "--dry-run" it only counts.
func runCleanupAnon(ctx context.Context, cfg config.Config, args []string, logger *slog.Logger) error {
	dryRun := len(args) > 0 && args[0] == "--dry-run"
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	var verifier authn.Verifier = &authn.DevVerifier{}
	if !cfg.DevAuth && !dryRun {
		if cfg.FirebaseCredentialsFile == "" {
			return errors.New("FIREBASE_CREDENTIALS_FILE is required to delete Firebase users")
		}
		fb, err := authn.NewFirebase(ctx, authn.FirebaseOptions{ProjectID: cfg.FirebaseProjectID, CredentialsFile: cfg.FirebaseCredentialsFile})
		if err != nil {
			return err
		}
		verifier = fb
	}
	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()
	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)

	cutoff := time.Now().Add(-time.Duration(cfg.AnonRetentionDays) * 24 * time.Hour)
	users, err := st.InactiveAnonymousUsers(ctx, cutoff, anonBatch)
	if err != nil {
		return err
	}
	deleted, firebaseFailed := 0, 0
	if !dryRun {
		for _, u := range users {
			ok, err := st.DeleteInactiveAnonymous(ctx, u.UserID, hasher.User(u.UserID), cutoff)
			if err != nil {
				return err
			}
			if !ok {
				continue // signed in again since it was listed
			}
			deleted++
			for _, sub := range u.Subjects {
				if err := verifier.DeleteUser(ctx, sub); err != nil {
					// The server data is gone; a leftover anonymous Firebase user
					// only gets a fresh empty account if it ever signs in again.
					firebaseFailed++
					logger.Warn("firebase user not deleted", logx.KeyEvent, logx.EventDependencyError,
						"dependency", "firebase", "op", "cleanup_anon", "error", err.Error())
				}
			}
		}
	}
	logger.Info("cleanup-anon done", logx.KeyEvent, "job_run", "job", "cleanup_anon", "ok", firebaseFailed == 0,
		"dryRun", dryRun, "retentionDays", cfg.AnonRetentionDays, "candidates", len(users),
		"deleted", deleted, "firebaseFailed", firebaseFailed, "more", len(users) == anonBatch)
	return nil
}

// runReapplyDeletions deletes again every account that was deleted after the
// backup being restored was taken (spec §4.9). Run it right after a restore,
// before the API serves traffic. It needs the same LOG_PEPPER as production:
// deleted_users only keeps hashed ids.
func runReapplyDeletions(ctx context.Context, cfg config.Config, logger *slog.Logger) error {
	if cfg.DatabaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()
	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)
	gone, err := st.DeletedUserHashes(ctx)
	if err != nil {
		return err
	}
	checked, removed := 0, 0
	after := "00000000-0000-0000-0000-000000000000"
	for {
		ids, err := st.UserIDsAfter(ctx, after, 1000)
		if err != nil {
			return err
		}
		if len(ids) == 0 {
			break
		}
		for _, id := range ids {
			checked++
			if gone[hasher.User(id)] {
				if err := st.DeleteUserByID(ctx, id); err != nil {
					return err
				}
				removed++
			}
		}
		after = ids[len(ids)-1]
	}
	logger.Info("reapply-deletions done", logx.KeyEvent, "job_run", "job", "reapply_deletions", "ok", true,
		"usersChecked", checked, "deletedHashes", len(gone), "removed", removed)
	return nil
}
