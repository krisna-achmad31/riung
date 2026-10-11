package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
	"unicode/utf8"

	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Operator commands. Run inside the container on the VPS (root access is the
// authorization); every change is written to admin_audit_log as actor "cli".

func reasonFrom(args []string) (string, error) {
	r := strings.TrimSpace(strings.Join(args, " "))
	if n := utf8.RuneCountInString(r); n < 3 || n > 500 {
		return "", errors.New("a reason (3–500 characters) is required")
	}
	return r, nil
}

func runSettings(ctx context.Context, cfg config.Config, args []string, logger *slog.Logger) error {
	if len(args) == 0 {
		return errors.New(usage)
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
	cache := settings.NewCache(st, econ.Caps, 0, nowFunc)

	switch args[0] {
	case "list":
		tw := tabwriter.NewWriter(os.Stdout, 2, 4, 2, ' ', 0)
		_, _ = fmt.Fprintln(tw, "KEY\tVALUE\tDEFAULT\tRANGE\tOVERRIDDEN")
		for _, v := range cache.All(ctx) {
			_, _ = fmt.Fprintf(tw, "%s\t%d\t%d\t%d–%d\t%v\n", v.Key, v.Value, v.Default, v.Min, v.Max, v.Overridden)
		}
		return tw.Flush()
	case "set", "reset":
		if len(args) < 2 {
			return errors.New(usage)
		}
		key := args[1]
		def, ok := cache.Def(key)
		if !ok {
			return fmt.Errorf("unknown setting %q", key)
		}
		var value any
		rest := args[2:]
		if args[0] == "set" {
			if len(rest) == 0 {
				return errors.New(usage)
			}
			n, err := strconv.Atoi(rest[0])
			if err != nil || n < def.Min || n > def.Max {
				return fmt.Errorf("%s must be an integer %d–%d", key, def.Min, def.Max)
			}
			value, rest = n, rest[1:]
		}
		reason, err := reasonFrom(rest)
		if err != nil {
			return err
		}
		if _, err := st.ChangeSetting(ctx, store.SettingChange{Key: key, Value: value, Actor: "cli", Reason: reason}); err != nil {
			return err
		}
		logger.Warn("setting changed", logx.KeyEvent, "admin_setting_changed", "key", key, "value", value, "actor", "cli", "reason", reason)
		fmt.Printf("%s updated (the API picks it up within 30 s)\n", key)
		return nil
	default:
		return errors.New(usage)
	}
}

func runAdmin(ctx context.Context, cfg config.Config, args []string, logger *slog.Logger) error {
	if len(args) < 2 || (args[0] != "grant" && args[0] != "revoke") {
		return errors.New(usage)
	}
	grant := args[0] == "grant"
	email := strings.TrimSpace(args[1])
	reason, err := reasonFrom(args[2:])
	if err != nil {
		return err
	}
	if cfg.FirebaseProjectID == "" || cfg.FirebaseCredentialsFile == "" {
		return errors.New("FIREBASE_PROJECT_ID and FIREBASE_CREDENTIALS_FILE are required")
	}
	fb, err := authn.NewFirebase(ctx, authn.FirebaseOptions{ProjectID: cfg.FirebaseProjectID, CredentialsFile: cfg.FirebaseCredentialsFile})
	if err != nil {
		return err
	}
	return changeAdmin(ctx, cfg, fb, email, grant, reason, logger)
}

func changeAdmin(ctx context.Context, cfg config.Config, mgr authn.AdminManager, email string, grant bool, reason string, logger *slog.Logger) error {
	subject, verified, err := mgr.LookupEmail(ctx, email)
	if err != nil {
		return fmt.Errorf("look up %s: %w", email, err)
	}
	if grant && !verified {
		return errors.New("the account's email is not verified")
	}
	st, closeStore, err := openStore(ctx, cfg)
	if err != nil {
		return err
	}
	defer closeStore()
	u, err := st.UserByIdentity(ctx, authn.IdentityProviderFirebase, subject)
	if errors.Is(err, store.ErrNotFound) {
		return errors.New("this account has never opened the app; sign in once first")
	}
	if err != nil {
		return err
	}
	if grant {
		err = st.GrantAdmin(ctx, u.ID, "cli", reason)
	} else {
		err = st.RevokeAdmin(ctx, u.ID, "cli", reason)
	}
	if err != nil {
		return err
	}
	if err := mgr.SetAdmin(ctx, subject, grant); err != nil {
		return fmt.Errorf("database updated but setting the claim failed (retry): %w", err)
	}
	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)
	logger.Warn("admin access changed", logx.KeyEvent, "admin_setting_changed", "action", args0(grant),
		logx.KeyUser, hasher.User(u.ID), "actor", "cli", "reason", reason)
	fmt.Printf("%s: %s (they must sign in again)\n", args0(grant), email)
	return nil
}

func args0(grant bool) string {
	if grant {
		return "admin granted"
	}
	return "admin revoked"
}
