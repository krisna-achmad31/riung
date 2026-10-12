package config

import (
	"log/slog"
	"net/netip"
	"strings"
	"testing"
	"time"
)

func env(m map[string]string) func(string) string {
	return func(k string) string { return m[k] }
}

func TestLoadDefaults(t *testing.T) {
	c, err := Load(env(nil))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	if c.Env != EnvDev || c.ListenAddr != ":8080" || c.LogLevel != slog.LevelInfo {
		t.Fatalf("unexpected defaults: %+v", c)
	}
	if c.DBMaxConns != 10 || c.DBStatementTimeout != 5*time.Second || c.ShutdownTimeout != 15*time.Second {
		t.Fatalf("unexpected db/shutdown defaults: %+v", c)
	}
	if len(c.TrustedProxies) != 0 {
		t.Fatalf("no proxy must be trusted by default, got %v", c.TrustedProxies)
	}
	if !strings.HasPrefix(string(c.LogPepper), devSecret) || string(c.LogPepper) == string(c.BillingAccountKey) {
		t.Fatal("dev should fall back to distinct dev secrets")
	}
}

func TestLoadRejectsBadValues(t *testing.T) {
	_, err := Load(env(map[string]string{
		"RIUNG_ENV":       "staging",
		"LOG_LEVEL":       "loud",
		"DB_MAX_CONNS":    "500",
		"TRUSTED_PROXIES": "nginx",
	}))
	if err == nil {
		t.Fatal("expected errors")
	}
	for _, want := range []string{"RIUNG_ENV", "LOG_LEVEL", "DB_MAX_CONNS", "TRUSTED_PROXIES"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error should mention %s: %v", want, err)
		}
	}
}

func TestTrustedProxies(t *testing.T) {
	c, err := Load(env(map[string]string{"TRUSTED_PROXIES": "172.19.0.2, 10.0.0.0/8"}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	want := []netip.Prefix{netip.MustParsePrefix("172.19.0.2/32"), netip.MustParsePrefix("10.0.0.0/8")}
	if len(c.TrustedProxies) != len(want) {
		t.Fatalf("got %v", c.TrustedProxies)
	}
	for i := range want {
		if c.TrustedProxies[i] != want[i] {
			t.Errorf("proxy %d: got %v want %v", i, c.TrustedProxies[i], want[i])
		}
	}
}

func TestValidateAPIProdNeedsSecrets(t *testing.T) {
	c, err := Load(env(map[string]string{"RIUNG_ENV": "prod", "DATABASE_URL": "postgres://x"}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	err = c.ValidateAPI()
	if err == nil || !strings.Contains(err.Error(), "LOG_PEPPER") || !strings.Contains(err.Error(), "IP_HASH_KEY") {
		t.Fatalf("prod must require secrets, got %v", err)
	}

	long := strings.Repeat("k", 40)
	valid := map[string]string{
		"RIUNG_ENV": "prod", "DATABASE_URL": "postgres://x",
		"LOG_PEPPER": long + "1", "IP_HASH_KEY": long + "2", "PIN_PEPPER": long + "3", "BILLING_ACCOUNT_KEY": long + "4",
		"FIREBASE_PROJECT_ID": "riung-5e979", "FIREBASE_CREDENTIALS_FILE": "/run/secrets/firebase.json",
		"TRUSTED_PROXIES": "172.19.0.2/32",
	}
	c, _ = Load(env(valid))
	if err := c.ValidateAPI(); err != nil {
		t.Fatalf("valid prod config rejected: %v", err)
	}

	valid["LOG_PEPPER"] = valid["BILLING_ACCOUNT_KEY"]
	c, _ = Load(env(valid))
	if err := c.ValidateAPI(); err == nil || !strings.Contains(err.Error(), "must be different") {
		t.Fatalf("prod must reject a reused secret: %v", err)
	}

	valid["LOG_PEPPER"] = devSecret + "/LOG_PEPPER"
	c, _ = Load(env(valid))
	if err := c.ValidateAPI(); err == nil {
		t.Fatal("prod must reject the dev secret")
	}
}

func TestMigrationURL(t *testing.T) {
	c, _ := Load(env(map[string]string{"DATABASE_URL": "postgres://app"}))
	if c.MigrationURL() != "postgres://app" {
		t.Fatal("dev may fall back to DATABASE_URL")
	}
	c, _ = Load(env(map[string]string{"RIUNG_ENV": "prod", "DATABASE_URL": "postgres://app"}))
	if c.MigrationURL() != "" || c.ValidateMigrate() == nil {
		t.Fatal("prod must never migrate with the API credentials")
	}
	c, _ = Load(env(map[string]string{"RIUNG_ENV": "prod", "MIGRATE_DATABASE_URL": "postgres://migrator"}))
	if c.MigrationURL() != "postgres://migrator" || c.ValidateMigrate() != nil {
		t.Fatal("prod migrate should use MIGRATE_DATABASE_URL")
	}
}

func TestB1Settings(t *testing.T) {
	c, err := Load(env(map[string]string{"DEV_AUTH": "true"}))
	if err != nil || !c.DevAuth || c.AppCheckMode != AppCheckOff {
		t.Fatalf("dev defaults: %+v %v", c, err)
	}
	if err := c.ValidateAPI(); err == nil || !strings.Contains(err.Error(), "DATABASE_URL") || strings.Contains(err.Error(), "FIREBASE_PROJECT_ID") {
		t.Fatalf("dev auth should not need a project id: %v", err)
	}

	_, err = Load(env(map[string]string{"RIUNG_ENV": "prod", "DEV_AUTH": "true"}))
	if err == nil || !strings.Contains(err.Error(), "DEV_AUTH") {
		t.Fatalf("DEV_AUTH must be refused in prod, got %v", err)
	}
	_, err = Load(env(map[string]string{"RIUNG_ENV": "prod", "APP_CHECK_MODE": "off"}))
	if err == nil || !strings.Contains(err.Error(), "APP_CHECK_MODE") {
		t.Fatalf("App Check off must be refused in prod, got %v", err)
	}

	c, _ = Load(env(map[string]string{"RIUNG_ENV": "prod"}))
	if c.AppCheckMode != AppCheckMonitor {
		t.Fatalf("prod default should be monitor, got %q", c.AppCheckMode)
	}
	long := strings.Repeat("k", 40)
	c, _ = Load(env(map[string]string{"RIUNG_ENV": "prod", "DATABASE_URL": "postgres://x", "LOG_PEPPER": long, "IP_HASH_KEY": long}))
	err = c.ValidateAPI()
	for _, want := range []string{"FIREBASE_PROJECT_ID", "PIN_PEPPER", "BILLING_ACCOUNT_KEY", "FIREBASE_CREDENTIALS_FILE", "TRUSTED_PROXIES"} {
		if err == nil || !strings.Contains(err.Error(), want) {
			t.Errorf("prod must require %s: %v", want, err)
		}
	}
}

func TestParseVersion(t *testing.T) {
	for in, want := range map[string][3]int{"1.4.0": {1, 4, 0}, "1.0.0+1": {1, 0, 0}, "12.30.7+999": {12, 30, 7}} {
		got, ok := ParseVersion(in)
		if !ok || got != want {
			t.Errorf("%q: got %v %v", in, got, ok)
		}
	}
	for _, bad := range []string{"", "1.4", "1.4.x", "v1.4.0", "1.4.0.1", "-1.0.0"} {
		if _, ok := ParseVersion(bad); ok {
			t.Errorf("%q should be rejected", bad)
		}
	}
}

func TestAdminListener(t *testing.T) {
	if _, err := Load(env(map[string]string{"ADMIN_LISTEN_ADDR": ":8081"})); err == nil || !strings.Contains(err.Error(), "ADMIN_ALLOWED_CIDRS") {
		t.Fatalf("admin listener without allowlist must fail: %v", err)
	}
	if _, err := Load(env(map[string]string{"ADMIN_LISTEN_ADDR": ":8080", "ADMIN_ALLOWED_CIDRS": "10.0.0.1"})); err == nil {
		t.Fatal("admin must not share the public port")
	}
	c, err := Load(env(map[string]string{"ADMIN_LISTEN_ADDR": ":8081", "ADMIN_ALLOWED_CIDRS": "172.19.0.7"}))
	if err != nil || len(c.AdminAllowedCIDRs) != 1 {
		t.Fatalf("valid admin config: %v %v", c.AdminAllowedCIDRs, err)
	}
}

func TestBillingConfig(t *testing.T) {
	c, _ := Load(env(nil))
	if c.BillingEnabled() {
		t.Fatal("billing is off by default")
	}
	if _, err := Load(env(map[string]string{"RIUNG_ENV": "prod", "DEV_BILLING": "true"})); err == nil || !strings.Contains(err.Error(), "DEV_BILLING") {
		t.Fatalf("DEV_BILLING refused in prod: %v", err)
	}
	if _, err := Load(env(map[string]string{"PLAY_PACKAGE_NAME": "com.riung.riung", "FIREBASE_CREDENTIALS_FILE": "/x.json"})); err == nil || !strings.Contains(err.Error(), "RTDN_AUDIENCE") {
		t.Fatalf("billing needs RTDN settings: %v", err)
	}
	c, err := Load(env(map[string]string{"PLAY_PACKAGE_NAME": "com.riung.riung", "FIREBASE_CREDENTIALS_FILE": "/x.json",
		"RTDN_AUDIENCE": "https://riung.e55techlab.com/v1/webhooks/google-play", "RTDN_SERVICE_ACCOUNT": "rtdn@riung.iam.gserviceaccount.com"}))
	if err != nil || !c.BillingEnabled() || c.PlayCredentialsFile != "/x.json" {
		t.Fatalf("valid billing config: %+v %v", c, err)
	}
	c, _ = Load(env(map[string]string{"DEV_BILLING": "true"}))
	if !c.BillingEnabled() || c.PlayPackageName != "com.riung.riung" {
		t.Fatalf("dev billing: %+v", c)
	}
}
