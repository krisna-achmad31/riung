// Package config reads the backend configuration from environment variables.
//
// Every command (api, migrate, healthcheck) parses the same environment, then
// validates only what it needs: the API never requires the migrator
// credentials and the migrate command never requires the API secrets.
package config

import (
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"log/slog"
	"net/netip"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Environments.
const (
	EnvDev  = "dev"
	EnvProd = "prod"
)

// App Check modes (docs/backend-api-spec.md §4.3): off (dev only), monitor
// (verify and log, never reject), enforce (reject missing/invalid tokens).
const (
	AppCheckOff     = "off"
	AppCheckMonitor = "monitor"
	AppCheckEnforce = "enforce"
)

// minSecretLen is the minimum length for peppers and HMAC keys in prod.
const minSecretLen = 32

// devSecret is used only when RIUNG_ENV=dev and the variable is unset, so a
// local run works without ceremony. It is rejected in prod (checkSecret).
const devSecret = "dev-only-insecure-secret-do-not-use-in-prod" //nolint:gosec // G101: public dev placeholder, refused in prod

// Config is the parsed environment.
type Config struct {
	Env      string
	LogLevel slog.Level

	ListenAddr      string
	ShutdownTimeout time.Duration

	// DatabaseURL is the riung_app (DML-only) connection used by the API.
	DatabaseURL string
	// MigrateDatabaseURL is the riung_migrator (DDL) connection used only by
	// the migrate command.
	MigrateDatabaseURL string
	DBMaxConns         int32
	DBStatementTimeout time.Duration

	// TrustedProxies are the only peers whose X-Real-IP header is honoured
	// (shared-nginx, 172.19.0.2/32, in prod). Empty means never trust it.
	TrustedProxies []netip.Prefix

	// LogPepper keys the pseudonymous user hash written to logs.
	LogPepper []byte
	// IPHashKey keys the daily-rotating IP hash written to logs.
	IPHashKey []byte

	// FirebaseProjectID is the project whose ID / App Check tokens we accept.
	FirebaseProjectID string
	// FirebaseCredentialsFile is the service account used for revocation
	// checks and account deletion (required in prod).
	FirebaseCredentialsFile string
	// DevAuth replaces Firebase with authn.DevVerifier ("dev:<uid>:<provider>"
	// tokens). Only allowed when Env is dev.
	DevAuth      bool
	AppCheckMode string

	// PinPepper keys the server-side HMAC over journal PIN backup hashes.
	PinPepper []byte
	// BillingAccountKey derives the obfuscated Play account id per user.
	BillingAccountKey []byte
	// FocusTicketKey is the Ed25519 seed (32 bytes) that signs Focus tickets;
	// FocusTicketKid names it so keys can be rotated.
	FocusTicketKey []byte
	FocusTicketKid string
	// AnonRetentionDays: anonymous accounts unseen this long are deleted by
	// riung cleanup-anon.
	AnonRetentionDays int
	// LogTee is an extra file the JSON log is also written to. Cron jobs run
	// with `docker exec -e LOG_TEE=/proc/1/fd/1` so their job_run lines reach
	// the container log (and Loki) instead of only the cron mail.
	LogTee string

	// CORSLandingOrigin is the only origin allowed to call POST /v1/waitlist
	// from a browser (empty = no CORS at all).
	CORSLandingOrigin string
	// MinAppVersion makes older app builds receive 426 upgrade_required.
	MinAppVersion string

	// AdminListenAddr serves the Admin API (empty = disabled). Never proxied
	// by nginx; only AdminAllowedCIDRs may connect (prod: OpenVPN 172.19.0.7/32).
	AdminListenAddr   string
	AdminAllowedCIDRs []netip.Prefix

	// Google Play billing. Enabled when PlayPackageName is set (or DevBilling).
	PlayPackageName     string
	PlayCredentialsFile string // defaults to FirebaseCredentialsFile
	// RTDN push authentication (Pub/Sub OIDC): audience configured on the
	// push subscription and the service account it signs as.
	RTDNAudience       string
	RTDNServiceAccount string
	// DevBilling fakes Play (dev-coin:/dev-sub: tokens). Only in dev.
	DevBilling bool
}

// BillingEnabled reports whether purchase verification is configured.
func (c Config) BillingEnabled() bool { return c.DevBilling || c.PlayPackageName != "" }

// Load parses the environment through getenv (os.Getenv in production,
// a map lookup in tests). It applies defaults but does not check that
// command-specific values are present; call ValidateAPI / ValidateMigrate.
func Load(getenv func(string) string) (Config, error) {
	var errs []error
	c := Config{
		Env:                strings.TrimSpace(getenv("RIUNG_ENV")),
		ListenAddr:         orDefault(getenv("LISTEN_ADDR"), ":8080"),
		DatabaseURL:        strings.TrimSpace(getenv("DATABASE_URL")),
		MigrateDatabaseURL: strings.TrimSpace(getenv("MIGRATE_DATABASE_URL")),
	}
	if c.Env == "" {
		c.Env = EnvDev
	}
	if c.Env != EnvDev && c.Env != EnvProd {
		errs = append(errs, fmt.Errorf("RIUNG_ENV must be %q or %q, got %q", EnvDev, EnvProd, c.Env))
	}

	level, err := parseLevel(orDefault(getenv("LOG_LEVEL"), "info"))
	if err != nil {
		errs = append(errs, err)
	}
	c.LogLevel = level

	if c.ShutdownTimeout, err = parseDuration("SHUTDOWN_TIMEOUT", orDefault(getenv("SHUTDOWN_TIMEOUT"), "15s")); err != nil {
		errs = append(errs, err)
	}
	if c.DBStatementTimeout, err = parseDuration("DB_STATEMENT_TIMEOUT", orDefault(getenv("DB_STATEMENT_TIMEOUT"), "5s")); err != nil {
		errs = append(errs, err)
	}
	maxConns, err := strconv.ParseInt(orDefault(getenv("DB_MAX_CONNS"), "10"), 10, 32)
	if err != nil || maxConns < 1 || maxConns > 50 {
		errs = append(errs, fmt.Errorf("DB_MAX_CONNS must be an integer between 1 and 50"))
		maxConns = 10
	}
	c.DBMaxConns = int32(maxConns)

	if c.TrustedProxies, err = parsePrefixes(getenv("TRUSTED_PROXIES")); err != nil {
		errs = append(errs, err)
	}

	c.LogPepper = []byte(getenv("LOG_PEPPER"))
	c.IPHashKey = []byte(getenv("IP_HASH_KEY"))
	c.PinPepper = []byte(getenv("PIN_PEPPER"))
	c.BillingAccountKey = []byte(getenv("BILLING_ACCOUNT_KEY"))
	if v := strings.TrimSpace(getenv("FOCUS_TICKET_KEY")); v != "" {
		seed, err := decodeKey(v)
		if err != nil || len(seed) != 32 {
			errs = append(errs, errors.New("FOCUS_TICKET_KEY must be 32 random bytes in base64 (openssl rand -base64 32)"))
		}
		c.FocusTicketKey = seed
	} else if c.Env == EnvDev {
		sum := sha256.Sum256([]byte(devSecret + "/FOCUS_TICKET_KEY"))
		c.FocusTicketKey = sum[:]
	}
	c.FocusTicketKid = orDefault(getenv("FOCUS_TICKET_KID"), "k1")
	c.LogTee = strings.TrimSpace(getenv("LOG_TEE"))
	c.AnonRetentionDays = 90
	if v := strings.TrimSpace(getenv("ANON_RETENTION_DAYS")); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 30 || n > 3650 {
			errs = append(errs, errors.New("ANON_RETENTION_DAYS must be 30–3650"))
		}
		c.AnonRetentionDays = n
	}
	if !kidPattern.MatchString(c.FocusTicketKid) {
		errs = append(errs, errors.New("FOCUS_TICKET_KID must be 1–32 letters, digits, '-' or '_'"))
	}
	if c.Env == EnvDev {
		// Distinct per purpose even in dev: one shared key would make the log
		// user hash a prefix of the billingAccountId sent to Google.
		for name, s := range c.secrets() {
			if len(*s) == 0 {
				*s = []byte(devSecret + "/" + name)
			}
		}
	}

	c.FirebaseProjectID = strings.TrimSpace(getenv("FIREBASE_PROJECT_ID"))
	c.FirebaseCredentialsFile = strings.TrimSpace(getenv("FIREBASE_CREDENTIALS_FILE"))
	if v := strings.TrimSpace(getenv("DEV_AUTH")); v != "" {
		b, err := strconv.ParseBool(v)
		if err != nil {
			errs = append(errs, fmt.Errorf("DEV_AUTH must be true or false"))
		}
		c.DevAuth = b
	}
	if c.DevAuth && c.Env != EnvDev {
		errs = append(errs, errors.New("DEV_AUTH is only allowed when RIUNG_ENV=dev"))
	}

	defaultMode := AppCheckOff
	if c.Env == EnvProd {
		defaultMode = AppCheckMonitor
	}
	c.AppCheckMode = orDefault(getenv("APP_CHECK_MODE"), defaultMode)
	switch c.AppCheckMode {
	case AppCheckOff, AppCheckMonitor, AppCheckEnforce:
	default:
		errs = append(errs, fmt.Errorf("APP_CHECK_MODE must be off, monitor or enforce"))
	}
	if c.AppCheckMode == AppCheckOff && c.Env == EnvProd {
		errs = append(errs, errors.New("APP_CHECK_MODE=off is not allowed in prod (use monitor or enforce)"))
	}

	c.CORSLandingOrigin = strings.TrimSpace(getenv("CORS_LANDING_ORIGIN"))
	if c.CORSLandingOrigin != "" && !strings.HasPrefix(c.CORSLandingOrigin, "https://") && c.Env == EnvProd {
		errs = append(errs, errors.New("CORS_LANDING_ORIGIN must be an https:// origin"))
	}
	c.AdminListenAddr = strings.TrimSpace(getenv("ADMIN_LISTEN_ADDR"))
	if c.AdminAllowedCIDRs, err = parsePrefixes(getenv("ADMIN_ALLOWED_CIDRS")); err != nil {
		errs = append(errs, fmt.Errorf("ADMIN_ALLOWED_CIDRS: %w", err))
	}
	if c.AdminListenAddr != "" && len(c.AdminAllowedCIDRs) == 0 {
		errs = append(errs, errors.New("ADMIN_ALLOWED_CIDRS is required when ADMIN_LISTEN_ADDR is set"))
	}
	if c.AdminListenAddr != "" && c.AdminListenAddr == c.ListenAddr {
		errs = append(errs, errors.New("ADMIN_LISTEN_ADDR must differ from LISTEN_ADDR"))
	}
	c.PlayPackageName = strings.TrimSpace(getenv("PLAY_PACKAGE_NAME"))
	c.PlayCredentialsFile = orDefault(getenv("PLAY_CREDENTIALS_FILE"), c.FirebaseCredentialsFile)
	c.RTDNAudience = strings.TrimSpace(getenv("RTDN_AUDIENCE"))
	c.RTDNServiceAccount = strings.TrimSpace(getenv("RTDN_SERVICE_ACCOUNT"))
	if v := strings.TrimSpace(getenv("DEV_BILLING")); v != "" {
		b, err := strconv.ParseBool(v)
		if err != nil {
			errs = append(errs, errors.New("DEV_BILLING must be true or false"))
		}
		c.DevBilling = b
	}
	if c.DevBilling && c.Env != EnvDev {
		errs = append(errs, errors.New("DEV_BILLING is only allowed when RIUNG_ENV=dev"))
	}
	if c.DevBilling && c.PlayPackageName == "" {
		c.PlayPackageName = "com.riung.riung"
	}
	if c.PlayPackageName != "" && !c.DevBilling {
		if c.PlayCredentialsFile == "" {
			errs = append(errs, errors.New("PLAY_CREDENTIALS_FILE (or FIREBASE_CREDENTIALS_FILE) is required for billing"))
		}
		if c.RTDNAudience == "" || c.RTDNServiceAccount == "" {
			errs = append(errs, errors.New("RTDN_AUDIENCE and RTDN_SERVICE_ACCOUNT are required for billing"))
		}
	}
	c.MinAppVersion = orDefault(getenv("MIN_APP_VERSION"), "0.0.0")
	if _, ok := ParseVersion(c.MinAppVersion); !ok {
		errs = append(errs, fmt.Errorf("MIN_APP_VERSION must look like 1.4.0"))
	}

	return c, errors.Join(errs...)
}

// ValidateAPI checks what the HTTP API needs to start.
func (c Config) ValidateAPI() error {
	var errs []error
	if c.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL is required"))
	}
	if !c.DevAuth && c.FirebaseProjectID == "" {
		errs = append(errs, errors.New("FIREBASE_PROJECT_ID is required (or DEV_AUTH=true in dev)"))
	}
	if c.Env == EnvProd {
		errs = append(errs,
			checkSecret("LOG_PEPPER", c.LogPepper),
			checkSecret("IP_HASH_KEY", c.IPHashKey),
			checkSecret("PIN_PEPPER", c.PinPepper),
			checkSecret("BILLING_ACCOUNT_KEY", c.BillingAccountKey),
			c.checkFocusTicketKey(),
			c.checkDistinctSecrets(),
		)
		if c.FirebaseCredentialsFile == "" {
			errs = append(errs, errors.New("FIREBASE_CREDENTIALS_FILE is required in prod (revocation checks, account deletion)"))
		}
		// Behind shared-nginx every request would otherwise appear to come from
		// the proxy's address, turning per-IP limits (e.g. new accounts per IP)
		// into one global limit for all users.
		if len(c.TrustedProxies) == 0 {
			errs = append(errs, errors.New("TRUSTED_PROXIES is required in prod (shared-nginx, 172.19.0.2/32)"))
		}
	}
	return errors.Join(errs...)
}

// ParseVersion parses "1.4.0" or "1.4.0+27" into [major, minor, patch].
func ParseVersion(s string) ([3]int, bool) {
	var v [3]int
	if i := strings.IndexByte(s, '+'); i >= 0 {
		s = s[:i]
	}
	parts := strings.Split(s, ".")
	if len(parts) != 3 {
		return v, false
	}
	for i, p := range parts {
		n, err := strconv.Atoi(p)
		if err != nil || n < 0 || n > 9999 {
			return v, false
		}
		v[i] = n
	}
	return v, true
}

// ValidateMigrate checks what the migrate command needs.
func (c Config) ValidateMigrate() error {
	if c.MigrationURL() == "" {
		return errors.New("MIGRATE_DATABASE_URL is required")
	}
	return nil
}

// MigrationURL is the connection the migrate command uses. Outside dev it is
// always the dedicated migrator URL: the API credentials cannot run DDL.
func (c Config) MigrationURL() string {
	if c.MigrateDatabaseURL == "" && c.Env == EnvDev {
		return c.DatabaseURL
	}
	return c.MigrateDatabaseURL
}

func (c *Config) secrets() map[string]*[]byte {
	return map[string]*[]byte{"LOG_PEPPER": &c.LogPepper, "IP_HASH_KEY": &c.IPHashKey,
		"PIN_PEPPER": &c.PinPepper, "BILLING_ACCOUNT_KEY": &c.BillingAccountKey}
}

func checkSecret(name string, v []byte) error {
	if len(v) < minSecretLen {
		return fmt.Errorf("%s must be at least %d characters in prod", name, minSecretLen)
	}
	if strings.HasPrefix(string(v), devSecret) {
		return fmt.Errorf("%s must not use the dev default in prod", name)
	}
	return nil
}

var kidPattern = regexp.MustCompile(`^[A-Za-z0-9_-]{1,32}$`)

// decodeKey accepts standard or URL-safe base64, padded or not.
func decodeKey(v string) ([]byte, error) {
	for _, enc := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding, base64.URLEncoding, base64.RawURLEncoding} {
		if b, err := enc.DecodeString(v); err == nil {
			return b, nil
		}
	}
	return nil, errors.New("not base64")
}

func (c *Config) checkFocusTicketKey() error {
	dev := sha256.Sum256([]byte(devSecret + "/FOCUS_TICKET_KEY"))
	switch {
	case len(c.FocusTicketKey) != 32:
		return errors.New("FOCUS_TICKET_KEY is required in prod (openssl rand -base64 32)")
	case string(c.FocusTicketKey) == string(dev[:]):
		return errors.New("FOCUS_TICKET_KEY must not use the dev default in prod")
	}
	return nil
}

// checkDistinctSecrets refuses reusing one secret for two purposes.
func (c *Config) checkDistinctSecrets() error {
	seen := map[string]string{}
	names := []string{"LOG_PEPPER", "IP_HASH_KEY", "PIN_PEPPER", "BILLING_ACCOUNT_KEY"}
	secrets := c.secrets()
	for _, name := range names {
		v := string(*secrets[name])
		if v == "" {
			continue
		}
		if other, ok := seen[v]; ok {
			return fmt.Errorf("%s and %s must be different secrets", other, name)
		}
		seen[v] = name
	}
	return nil
}

func orDefault(v, def string) string {
	if v = strings.TrimSpace(v); v == "" {
		return def
	}
	return v
}

func parseLevel(s string) (slog.Level, error) {
	var l slog.Level
	if err := l.UnmarshalText([]byte(s)); err != nil {
		return slog.LevelInfo, fmt.Errorf("LOG_LEVEL: %w", err)
	}
	return l, nil
}

func parseDuration(name, s string) (time.Duration, error) {
	d, err := time.ParseDuration(s)
	if err != nil || d <= 0 {
		return 0, fmt.Errorf("%s must be a positive duration, got %q", name, s)
	}
	return d, nil
}

// parsePrefixes parses a comma-separated list of CIDRs or bare IPs.
func parsePrefixes(s string) ([]netip.Prefix, error) {
	var out []netip.Prefix
	for _, part := range strings.Split(s, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		if !strings.Contains(part, "/") {
			addr, err := netip.ParseAddr(part)
			if err != nil {
				return nil, fmt.Errorf("TRUSTED_PROXIES: %q is not an IP or CIDR", part)
			}
			out = append(out, netip.PrefixFrom(addr, addr.BitLen()))
			continue
		}
		p, err := netip.ParsePrefix(part)
		if err != nil {
			return nil, fmt.Errorf("TRUSTED_PROXIES: %q is not an IP or CIDR", part)
		}
		out = append(out, p.Masked())
	}
	return out, nil
}
