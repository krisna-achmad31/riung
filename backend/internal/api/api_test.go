package api_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/api"
	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/ratelimit"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

// clock is an adjustable clock starting at the real time (DevVerifier stamps
// auth_time with the real time).
type clock struct {
	mu     sync.Mutex
	offset time.Duration
}

func (c *clock) now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return time.Now().Add(c.offset)
}

func (c *clock) advance(d time.Duration) {
	c.mu.Lock()
	c.offset += d
	c.mu.Unlock()
}

type syncBuffer struct {
	mu sync.Mutex
	b  bytes.Buffer
}

func (s *syncBuffer) Write(p []byte) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.b.Write(p)
}

func (s *syncBuffer) String() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.b.String()
}

type env struct {
	t        *testing.T
	url      string
	adminURL string
	store    *store.Store
	verifier *authn.DevVerifier
	clock    *clock
	logs     *syncBuffer
	play     *billing.FakePublisher
	billing  *billing.Service
}

type option func(*config.Config)

func newEnv(t *testing.T, opts ...option) *env {
	t.Helper()
	return newEnvWith(t, authn.DevAppChecker{}, opts...)
}

func newEnvWith(t *testing.T, appCheck authn.AppChecker, opts ...option) *env {
	t.Helper()
	pool := testdb.Pool(t)
	cfg, err := config.Load(func(k string) string {
		return map[string]string{"DEV_AUTH": "true", "DEV_BILLING": "true", "TRUSTED_PROXIES": "127.0.0.1/32",
			"ADMIN_LISTEN_ADDR": "127.0.0.1:0", "ADMIN_ALLOWED_CIDRS": "127.0.0.1/32"}[k]
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, o := range opts {
		o(&cfg)
	}
	e := &env{t: t, store: store.New(pool), verifier: &authn.DevVerifier{}, clock: &clock{}, logs: &syncBuffer{},
		play: billing.NewFakePublisher()}
	econ := economy.MustLoad()
	hasher := logx.NewHasher(cfg.LogPepper, cfg.IPHashKey)
	e.billing = &billing.Service{Store: e.store, Economy: econ, Hasher: hasher,
		AccountKey: cfg.BillingAccountKey, Now: e.clock.now, AckAfter: time.Nanosecond}
	if cfg.DevBilling {
		e.billing.Publisher = e.play
	}
	deps := api.Deps{
		Config:   cfg,
		Logger:   logx.New(e.logs, slog.LevelInfo),
		Hasher:   hasher,
		Store:    e.store,
		Verifier: e.verifier,
		AppCheck: appCheck,
		Economy:  econ,
		Limiter:  ratelimit.New(e.clock.now),
		Settings: settings.NewCache(e.store, econ.Caps, 30*time.Second, e.clock.now),
		Billing:  e.billing,
		Push:     billing.DevPushVerifier{},
		Now:      e.clock.now,
	}
	srv := httptest.NewServer(api.NewHandler(deps))
	t.Cleanup(srv.Close)
	admin := httptest.NewServer(api.NewAdminHandler(deps))
	t.Cleanup(admin.Close)
	e.url, e.adminURL = srv.URL, admin.URL
	return e
}

type req struct {
	method, path, token string
	body                any
	headers             map[string]string
	idemKey             string
}

type resp struct {
	status int
	header http.Header
	body   map[string]any
	raw    string
}

var keyCounter struct {
	sync.Mutex
	n int
}

func newKey() string {
	keyCounter.Lock()
	defer keyCounter.Unlock()
	keyCounter.n++
	return fmt.Sprintf("00000000-0000-4000-8000-%012d", keyCounter.n)
}

func (e *env) do(r req) resp {
	e.t.Helper()
	var body io.Reader
	if r.body != nil {
		switch b := r.body.(type) {
		case string:
			body = strings.NewReader(b)
		default:
			raw, _ := json.Marshal(b)
			body = bytes.NewReader(raw)
		}
	}
	baseURL := e.url
	if strings.HasPrefix(r.path, "/admin/") {
		baseURL = e.adminURL
	}
	hr, _ := http.NewRequestWithContext(context.Background(), r.method, baseURL+r.path, body)
	if r.body != nil {
		hr.Header.Set("Content-Type", "application/json")
	}
	if r.token != "" {
		hr.Header.Set("Authorization", "Bearer "+r.token)
	}
	if r.idemKey != "" {
		hr.Header.Set("Idempotency-Key", r.idemKey)
	}
	for k, v := range r.headers {
		hr.Header.Set(k, v)
	}
	res, err := http.DefaultClient.Do(hr)
	if err != nil {
		e.t.Fatalf("%s %s: %v", r.method, r.path, err)
	}
	defer func() { _ = res.Body.Close() }()
	raw, _ := io.ReadAll(res.Body)
	out := resp{status: res.StatusCode, header: res.Header, raw: string(raw)}
	_ = json.Unmarshal(raw, &out.body)
	return out
}

func errCode(r resp) string {
	if e, ok := r.body["error"].(map[string]any); ok {
		s, _ := e["code"].(string)
		return s
	}
	return ""
}

func get(m map[string]any, path ...string) any {
	var cur any = m
	for _, p := range path {
		mm, ok := cur.(map[string]any)
		if !ok {
			return nil
		}
		cur = mm[p]
	}
	return cur
}

const (
	anonToken   = "dev:user-anon:anonymous"
	googleToken = "dev:user-google:google.com"
)

func TestAuthenticationRequired(t *testing.T) {
	e := newEnv(t)
	for _, tok := range []string{"", "garbage", "dev:x:facebook.com"} {
		r := e.do(req{method: "GET", path: "/v1/me", token: tok})
		if r.status != 401 || errCode(r) != "unauthenticated" {
			t.Fatalf("token %q: got %d %s", tok, r.status, r.raw)
		}
	}
	if !strings.Contains(e.logs.String(), `"event":"auth_failed"`) {
		t.Fatal("auth failures must be logged")
	}
}

func TestMeCreatesAnonymousAccount(t *testing.T) {
	e := newEnv(t)
	r := e.do(req{method: "GET", path: "/v1/me", token: anonToken})
	if r.status != 200 {
		t.Fatalf("got %d %s", r.status, r.raw)
	}
	if get(r.body, "user", "isAnonymous") != true || get(r.body, "wallet", "coins") != float64(0) {
		t.Fatalf("unexpected body %s", r.raw)
	}
	if ba, _ := get(r.body, "user", "billingAccountId").(string); !strings.HasPrefix(ba, "ba_") || len(ba) != 35 {
		t.Fatalf("billingAccountId: %q", ba)
	}
	if get(r.body, "premium", "status") != "none" || get(r.body, "today", "freeFocusLeft") != float64(1) {
		t.Fatalf("defaults: %s", r.raw)
	}
	jakarta, _ := time.LoadLocation("Asia/Jakarta")
	if get(r.body, "today", "date") != e.clock.now().In(jakarta).Format(time.DateOnly) {
		t.Fatalf("today must be the user's local date: %v", get(r.body, "today", "date"))
	}
	id := get(r.body, "user", "id")
	if again := e.do(req{method: "GET", path: "/v1/me", token: anonToken}); get(again.body, "user", "id") != id {
		t.Fatal("same identity must map to the same user")
	}
	if !strings.Contains(e.logs.String(), `"event":"account_created"`) || strings.Contains(e.logs.String(), "user-anon") {
		t.Fatalf("account_created must be logged without the raw uid: %s", e.logs.String())
	}
}

func TestProfileValidationAndIdempotency(t *testing.T) {
	e := newEnv(t)
	patch := func(body any, key string) resp {
		return e.do(req{method: "PATCH", path: "/v1/me/profile", token: anonToken, body: body, idemKey: key})
	}
	if r := patch(map[string]any{"displayName": "Rani"}, ""); r.status != 400 || errCode(r) != "invalid_request" {
		t.Fatalf("missing Idempotency-Key: %d %s", r.status, r.raw)
	}
	for _, bad := range []map[string]any{
		{"avatarId": "av99"}, {"locale": "fr"}, {"persona": "ceo"}, {"tz": "Mars/Base"}, {"tz": "Local"},
		{"displayName": strings.Repeat("a", 41)}, {"displayName": "bad\u0007name"}, {"isAdmin": true},
	} {
		if r := patch(bad, newKey()); r.status != 400 {
			t.Fatalf("%v should be rejected, got %d %s", bad, r.status, r.raw)
		}
	}
	key := newKey()
	body := map[string]any{"displayName": "  Rani  ", "avatarId": "av3", "persona": "mahasiswa", "tz": "Asia/Makassar", "onboardingDone": true}
	first := patch(body, key)
	if first.status != 200 || get(first.body, "user", "displayName") != "Rani" || get(first.body, "user", "tz") != "Asia/Makassar" {
		t.Fatalf("valid patch: %d %s", first.status, first.raw)
	}
	replay := patch(body, key)
	if replay.status != 200 || replay.raw != first.raw || replay.header.Get("Idempotent-Replayed") != "true" {
		t.Fatalf("replay must return the stored response: %d %s", replay.status, replay.raw)
	}
	if r := patch(map[string]any{"displayName": "Other"}, key); r.status != 409 || errCode(r) != "idempotency_key_reuse" {
		t.Fatalf("same key, other body: %d %s", r.status, r.raw)
	}
}

func TestAssessment(t *testing.T) {
	e := newEnv(t)
	put := func(body any) resp {
		return e.do(req{method: "PUT", path: "/v1/me/assessment", token: anonToken, body: body, idemKey: newKey()})
	}
	for _, bad := range []map[string]any{
		{"dominantSaboteurs": []string{}},
		{"dominantSaboteurs": []string{"naga"}},
		{"dominantSaboteurs": []string{"waswas", "waswas"}},
		{"dominantSaboteurs": []string{"waswas"}, "scores": map[string]int{"waswas": 101}},
		{"dominantSaboteurs": []string{"waswas"}, "scores": map[string]int{"naga": 1}},
		{"dominantSaboteurs": []string{"waswas"}, "completedAt": time.Now().Add(time.Hour).Format(time.RFC3339)},
	} {
		if r := put(bad); r.status != 400 {
			t.Fatalf("%v should be rejected: %d %s", bad, r.status, r.raw)
		}
	}
	r := put(map[string]any{"dominantSaboteurs": []string{"waswas", "hakim"}, "scores": map[string]int{"waswas": 80, "hakim": 64}})
	if r.status != 200 {
		t.Fatalf("valid: %d %s", r.status, r.raw)
	}
	me := e.do(req{method: "GET", path: "/v1/me", token: anonToken})
	if get(me.body, "assessment", "scores", "waswas") != float64(80) {
		t.Fatalf("assessment not in /me: %s", me.raw)
	}
}

func TestLink(t *testing.T) {
	e := newEnv(t)
	e.do(req{method: "GET", path: "/v1/me", token: "dev:linker:anonymous"})
	if r := e.do(req{method: "POST", path: "/v1/me/link", token: "dev:linker:anonymous", idemKey: newKey()}); r.status != 400 {
		t.Fatalf("anonymous token cannot link: %d %s", r.status, r.raw)
	}
	r := e.do(req{method: "POST", path: "/v1/me/link", token: "dev:linker:google.com", idemKey: newKey()})
	if r.status != 200 || get(r.body, "user", "isAnonymous") != false {
		t.Fatalf("link: %d %s", r.status, r.raw)
	}
	if !strings.Contains(e.logs.String(), `"event":"account_linked"`) {
		t.Fatal("link must be logged")
	}
}

func TestJournalPinBackup(t *testing.T) {
	e := newEnv(t)
	const path = "/v1/me/journal-pin-backup"
	if r := e.do(req{method: "GET", path: path, token: anonToken}); r.status != 403 || errCode(r) != "permanent_account_required" {
		t.Fatalf("anonymous must be refused: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "GET", path: path, token: googleToken}); r.status != 404 {
		t.Fatalf("no backup yet: %d", r.status)
	}
	hash := "c2VjcmV0LWhhc2gtZnJvbS1waG9uZQ"
	if r := e.do(req{method: "PUT", path: path, token: googleToken, idemKey: newKey(), body: map[string]string{"hash": hash, "salt": "c2FsdHNhbHQ"}}); r.status != 200 {
		t.Fatalf("put: %d %s", r.status, r.raw)
	}
	r := e.do(req{method: "GET", path: path, token: googleToken})
	if r.status != 200 || r.body["salt"] != "c2FsdHNhbHQ" || strings.Contains(r.raw, hash) || r.body["hash"] != nil {
		t.Fatalf("GET must return the salt only: %s", r.raw)
	}

	verify := func(h string) resp {
		return e.do(req{method: "POST", path: path + "/verify", token: googleToken, body: map[string]string{"hash": h}})
	}
	// Failures count per UTC day and the steps below move the clock about an
	// hour: start well after midnight so the count never resets mid-test.
	if now := e.clock.now().UTC(); now.Hour() >= 21 {
		e.clock.advance(now.Truncate(24 * time.Hour).Add(25 * time.Hour).Sub(now))
	}
	if r := verify(hash); r.status != 200 || r.body["match"] != true {
		t.Fatalf("correct PIN: %d %s", r.status, r.raw)
	}
	wrong := "d3JvbmctaGFzaC1mcm9tLXBob25l"
	r = verify(wrong)
	if r.status != 200 || r.body["match"] != false || r.body["attemptsLeft"] != float64(9) {
		t.Fatalf("wrong PIN: %d %s", r.status, r.raw)
	}
	// Rate limit: 5 attempts per 15 minutes.
	for i := 0; i < 3; i++ {
		verify(wrong)
	}
	if r := verify(wrong); r.status != 429 || r.header.Get("Retry-After") == "" {
		t.Fatalf("6th attempt in 15 min must be rate limited: %d %s", r.status, r.raw)
	}
	// Spread the rest over time: 10 failures in a day lock verification.
	for failures := 4; failures < 10; {
		e.clock.advance(4 * time.Minute)
		r = verify(wrong)
		if r.status == 200 {
			failures++
			continue
		}
		if errCode(r) == "pin_locked" {
			break
		}
		if r.status != 429 {
			t.Fatalf("unexpected %d %s", r.status, r.raw)
		}
	}
	e.clock.advance(15 * time.Minute)
	if r := verify(hash); r.status != 409 || errCode(r) != "pin_locked" {
		t.Fatalf("after 10 failures even the right PIN is locked: %d %s", r.status, r.raw)
	}
	if !strings.Contains(e.logs.String(), `"event":"pin_locked"`) {
		t.Fatal("lock must be logged")
	}
	if strings.Contains(e.logs.String(), hash) || strings.Contains(e.logs.String(), wrong) {
		t.Fatal("PIN hashes must never be logged")
	}
}

func TestDeleteAccount(t *testing.T) {
	e := newEnv(t)
	first := e.do(req{method: "GET", path: "/v1/me", token: googleToken})
	firstID := get(first.body, "user", "id")

	// A permanent account must have signed in within 5 minutes.
	e.clock.advance(10 * time.Minute)
	if r := e.do(req{method: "DELETE", path: "/v1/me", token: googleToken}); r.status != 401 || errCode(r) != "recent_login_required" {
		t.Fatalf("stale sign-in: %d %s", r.status, r.raw)
	}
	e.clock.advance(-10 * time.Minute)
	if r := e.do(req{method: "DELETE", path: "/v1/me", token: googleToken}); r.status != 204 {
		t.Fatalf("delete: %d %s", r.status, r.raw)
	}
	if got := e.verifier.DeletedSubjects(); len(got) != 1 || got[0] != "user-google" {
		t.Fatalf("Firebase account must be deleted too: %v", got)
	}
	// Retrying is harmless.
	if r := e.do(req{method: "DELETE", path: "/v1/me", token: googleToken}); r.status != 204 {
		t.Fatalf("retry delete: %d", r.status)
	}
	again := e.do(req{method: "GET", path: "/v1/me", token: googleToken})
	if get(again.body, "user", "id") == firstID {
		t.Fatal("data must be gone after deletion")
	}

	// Anonymous accounts cannot re-authenticate, so no freshness check.
	e.do(req{method: "GET", path: "/v1/me", token: anonToken})
	e.clock.advance(10 * time.Minute)
	if r := e.do(req{method: "DELETE", path: "/v1/me", token: anonToken}); r.status != 204 {
		t.Fatalf("anonymous delete: %d %s", r.status, r.raw)
	}
}

func TestExport(t *testing.T) {
	e := newEnv(t)
	r := e.do(req{method: "GET", path: "/v1/me/export", token: anonToken})
	if r.status != 200 || get(r.body, "account", "user", "id") == nil || r.body["coinHistory"] == nil {
		t.Fatalf("export: %d %s", r.status, r.raw)
	}
	if !strings.Contains(r.header.Get("Content-Disposition"), "attachment") || r.header.Get("Cache-Control") != "no-store" {
		t.Fatalf("export headers: %v", r.header)
	}
}

func TestRateLimitPerUser(t *testing.T) {
	e := newEnv(t)
	for i := 1; i <= 6; i++ {
		r := e.do(req{method: "POST", path: "/v1/me/link", token: "dev:rl:google.com", idemKey: newKey()})
		if i <= 5 && r.status != 200 {
			t.Fatalf("request %d: %d %s", i, r.status, r.raw)
		}
		if i == 6 && (r.status != 429 || errCode(r) != "rate_limited" || r.header.Get("RateLimit-Policy") != "5;w=3600") {
			t.Fatalf("6th link in an hour must be limited: %d %s %v", r.status, r.raw, r.header)
		}
	}
	// Another user is unaffected.
	if r := e.do(req{method: "POST", path: "/v1/me/link", token: "dev:rl2:google.com", idemKey: newKey()}); r.status != 200 {
		t.Fatalf("other user: %d", r.status)
	}
}

func TestSignupLimitPerIP(t *testing.T) {
	e := newEnv(t)
	ip := map[string]string{"X-Real-IP": "203.0.113.20"}
	for i := 0; i < 10; i++ {
		if r := e.do(req{method: "GET", path: "/v1/me", token: fmt.Sprintf("dev:s%d:anonymous", i), headers: ip}); r.status != 200 {
			t.Fatalf("signup %d: %d %s", i, r.status, r.raw)
		}
	}
	if r := e.do(req{method: "GET", path: "/v1/me", token: "dev:s10:anonymous", headers: ip}); r.status != 429 || errCode(r) != "signup_limited" {
		t.Fatalf("11th signup from one IP: %d %s", r.status, r.raw)
	}
	other := map[string]string{"X-Real-IP": "203.0.113.21"}
	if r := e.do(req{method: "GET", path: "/v1/me", token: "dev:s10:anonymous", headers: other}); r.status != 200 {
		t.Fatalf("other IP: %d", r.status)
	}

	// An admin override (app_settings) takes effect after the cache TTL.
	if err := setSetting(e, "maxNewAccountsPerIpPerDay", 12); err != nil {
		t.Fatal(err)
	}
	e.clock.advance(31 * time.Second)
	for i := 11; i <= 12; i++ {
		if r := e.do(req{method: "GET", path: "/v1/me", token: fmt.Sprintf("dev:s%d:anonymous", i), headers: ip}); r.status != 200 {
			t.Fatalf("raised limit, signup %d: %d %s", i, r.status, r.raw)
		}
	}
}

func setSetting(e *env, key string, value int) error {
	// app_settings is writable by riung_app; the admin API (B2) will wrap this.
	return e.store.SetSetting(context.Background(), key, value, "test")
}

func TestAppCheckModes(t *testing.T) {
	enforce := newEnv(t, func(c *config.Config) { c.AppCheckMode = config.AppCheckEnforce })
	if r := enforce.do(req{method: "GET", path: "/v1/config"}); r.status != 401 || errCode(r) != "app_check_failed" {
		t.Fatalf("enforce without token: %d %s", r.status, r.raw)
	}
	if r := enforce.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-Firebase-AppCheck": "dev"}}); r.status != 200 {
		t.Fatalf("enforce with token: %d %s", r.status, r.raw)
	}
	monitor := newEnv(t, func(c *config.Config) { c.AppCheckMode = config.AppCheckMonitor })
	if r := monitor.do(req{method: "GET", path: "/v1/config"}); r.status != 200 {
		t.Fatalf("monitor must not reject: %d", r.status)
	}
	if !strings.Contains(monitor.logs.String(), `"event":"appcheck_failed"`) || !strings.Contains(monitor.logs.String(), `"mode":"monitor"`) {
		t.Fatal("monitor mode must log failures")
	}
	// The access log carries the outcome, so the enforce switch can be judged from Loki.
	monitor.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-Firebase-AppCheck": "dev"}})
	if logs := monitor.logs.String(); !strings.Contains(logs, `"appCheck":"missing"`) || !strings.Contains(logs, `"appCheck":"valid"`) {
		t.Fatalf("access log must record the App Check outcome:\n%s", logs)
	}
	// The waitlist is public: never behind App Check.
	if r := enforce.do(req{method: "POST", path: "/v1/waitlist", body: map[string]string{"email": "a@b.co"}}); r.status != 202 {
		t.Fatalf("waitlist must stay public: %d %s", r.status, r.raw)
	}
}

func TestMinAppVersion(t *testing.T) {
	e := newEnv(t, func(c *config.Config) { c.MinAppVersion = "1.4.0" })
	if r := e.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-App-Version": "1.3.9+40"}}); r.status != 426 || errCode(r) != "upgrade_required" {
		t.Fatalf("old app: %d %s", r.status, r.raw)
	}
	for _, v := range []string{"1.4.0+1", "2.0.0", ""} {
		if r := e.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-App-Version": v}}); r.status != 200 {
			t.Fatalf("version %q: %d", v, r.status)
		}
	}
}

func TestConfig(t *testing.T) {
	e := newEnv(t)
	r := e.do(req{method: "GET", path: "/v1/config"})
	if r.status != 200 || get(r.body, "economy", "earn", "checkin") != float64(5) ||
		get(r.body, "economy", "caps", "journalRewardsPerDay") != float64(3) || r.header.Get("ETag") == "" {
		t.Fatalf("config: %d %s", r.status, r.raw)
	}
	if strings.Contains(r.raw, "_comment") || strings.Contains(r.raw, "newAccountsPerIpPerDay") {
		t.Fatal("internal settings must not be published")
	}
	if r2 := e.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"If-None-Match": r.header.Get("ETag")}}); r2.status != 304 {
		t.Fatalf("revalidation: %d", r2.status)
	}
	// An admin change alters the ETag.
	_ = setSetting(e, "journalRewardsPerDay", 5)
	e.clock.advance(31 * time.Second)
	r3 := e.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"If-None-Match": r.header.Get("ETag")}})
	if r3.status != 200 || get(r3.body, "economy", "caps", "journalRewardsPerDay") != float64(5) {
		t.Fatalf("override: %d %s", r3.status, r3.raw)
	}
}

func TestContent(t *testing.T) {
	e := newEnv(t)
	err := e.store.ReplaceContent(context.Background(), "saboteurs", "id", []store.ContentItem{
		{ID: "waswas", Position: 0, Data: json.RawMessage(`{"id":"waswas","nama":"Si Waswas"}`)},
	})
	if err != nil {
		t.Fatal(err)
	}
	r := e.do(req{method: "GET", path: "/v1/content/saboteurs"})
	items, _ := r.body["items"].([]any)
	if r.status != 200 || len(items) != 1 || r.body["locale"] != "id" {
		t.Fatalf("content: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/content/saboteurs?locale=en"}); r.body["locale"] != "id" {
		t.Fatalf("en must fall back to id: %s", r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/content/users_sample"}); r.status != 404 {
		t.Fatalf("unknown kind: %d", r.status)
	}
	if r := e.do(req{method: "GET", path: "/v1/content/saboteurs?locale=xx"}); r.status != 400 {
		t.Fatalf("bad locale: %d", r.status)
	}
	if r2 := e.do(req{method: "GET", path: "/v1/content/saboteurs", headers: map[string]string{"If-None-Match": r.header.Get("ETag")}}); r2.status != 304 {
		t.Fatalf("etag: %d", r2.status)
	}
}

func TestWaitlist(t *testing.T) {
	e := newEnv(t, func(c *config.Config) { c.CORSLandingOrigin = "https://riung.app" })
	post := func(body any, headers map[string]string) resp {
		return e.do(req{method: "POST", path: "/v1/waitlist", body: body, headers: headers})
	}
	ip := func(n int) map[string]string { return map[string]string{"X-Real-IP": fmt.Sprintf("198.51.100.%d", n)} }

	pre := e.do(req{method: "OPTIONS", path: "/v1/waitlist", headers: map[string]string{"Origin": "https://riung.app", "Access-Control-Request-Method": "POST"}})
	if pre.status != 204 || pre.header.Get("Access-Control-Allow-Origin") != "https://riung.app" {
		t.Fatalf("preflight: %d %v", pre.status, pre.header)
	}
	evil := e.do(req{method: "OPTIONS", path: "/v1/waitlist", headers: map[string]string{"Origin": "https://evil.example"}})
	if evil.header.Get("Access-Control-Allow-Origin") != "" {
		t.Fatal("other origins must not get CORS headers")
	}

	first := post(map[string]string{"email": "Rani@Example.com", "lang": "id", "source": "landing"}, ip(1))
	dup := post(map[string]string{"email": "rani@example.com"}, ip(2))
	bot := post(map[string]string{"email": "bot@example.com", "website": "http://spam"}, ip(3))
	for name, r := range map[string]resp{"new": first, "duplicate": dup, "honeypot": bot} {
		if r.status != 202 || r.raw != first.raw {
			t.Fatalf("%s must look identical: %d %s", name, r.status, r.raw)
		}
	}
	for _, bad := range []any{map[string]string{"email": "not-an-email"}, map[string]any{"email": "a@b.co", "extra": 1}, `{"email":`} {
		if r := post(bad, ip(4)); r.status != 400 {
			t.Fatalf("%v: %d", bad, r.status)
		}
	}
	if r := post(map[string]string{"email": strings.Repeat("a", 3000) + "@b.co"}, ip(5)); r.status != 413 {
		t.Fatalf("2 KB body limit: %d", r.status)
	}
	for i := 0; i < 20; i++ {
		post(map[string]string{"email": fmt.Sprintf("x%d@example.com", i)}, ip(9))
	}
	if r := post(map[string]string{"email": "x99@example.com"}, ip(9)); r.status != 429 {
		t.Fatalf("21st waitlist post per IP per hour: %d", r.status)
	}
	if strings.Contains(strings.ToLower(e.logs.String()), "rani@example.com") {
		t.Fatal("emails must not be logged")
	}
}

// Requests arriving directly (not from the trusted proxy) cannot spoof their
// IP to dodge the per-IP limits.
func TestUntrustedPeerCannotSpoofIP(t *testing.T) {
	e := newEnv(t, func(c *config.Config) { c.TrustedProxies = []netip.Prefix{netip.MustParsePrefix("10.9.9.9/32")} })
	for i := 0; i < 20; i++ {
		e.do(req{method: "POST", path: "/v1/waitlist", body: map[string]string{"email": fmt.Sprintf("y%d@example.com", i)},
			headers: map[string]string{"X-Real-IP": fmt.Sprintf("192.0.2.%d", i), "X-Forwarded-For": fmt.Sprintf("192.0.2.%d", i)}})
	}
	r := e.do(req{method: "POST", path: "/v1/waitlist", body: map[string]string{"email": "y9@example.com"},
		headers: map[string]string{"X-Real-IP": "192.0.2.99"}})
	if r.status != 429 {
		t.Fatalf("spoofed headers must be ignored: %d", r.status)
	}
}

type downAppCheck struct{}

func (downAppCheck) Verify(context.Context, string) (authn.AppCheckToken, error) {
	return authn.AppCheckToken{}, authn.ErrUnavailable
}

// If Google's App Check keys cannot be loaded, monitor mode keeps serving
// and enforce mode asks the client to retry (503), never a hard 401.
func TestAppCheckUnavailable(t *testing.T) {
	monitor := newEnvWith(t, downAppCheck{}, func(c *config.Config) { c.AppCheckMode = config.AppCheckMonitor })
	if r := monitor.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-Firebase-AppCheck": "x"}}); r.status != 200 {
		t.Fatalf("monitor: %d", r.status)
	}
	enforce := newEnvWith(t, downAppCheck{}, func(c *config.Config) { c.AppCheckMode = config.AppCheckEnforce })
	if r := enforce.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-Firebase-AppCheck": "x"}}); r.status != 503 || errCode(r) != "unavailable" {
		t.Fatalf("enforce: %d %s", r.status, r.raw)
	}
}

// Using one endpoint's rate limit must not lock another (separate buckets).
func TestExportDoesNotBlockDeletion(t *testing.T) {
	e := newEnv(t)
	for i := 0; i < 3; i++ {
		if r := e.do(req{method: "GET", path: "/v1/me/export", token: googleToken}); r.status != 200 {
			t.Fatalf("export %d: %d", i, r.status)
		}
	}
	if r := e.do(req{method: "GET", path: "/v1/me/export", token: googleToken}); r.status != 429 {
		t.Fatalf("4th export in an hour: %d", r.status)
	}
	if r := e.do(req{method: "DELETE", path: "/v1/me", token: googleToken}); r.status != 204 {
		t.Fatalf("deletion must still work after exports: %d %s", r.status, r.raw)
	}
}

func TestRevocationCheckedAfterRateLimit(t *testing.T) {
	e := newEnv(t)
	tok := "dev:revoke-me:google.com"
	e.do(req{method: "GET", path: "/v1/me", token: tok})
	before := e.verifier.RevocationChecks()
	// POST /v1/me/link allows 5 per hour: requests over the limit must not
	// reach Firebase's revocation check.
	for range 8 {
		e.do(req{method: "POST", path: "/v1/me/link", token: tok, idemKey: newKey(), body: map[string]any{}})
	}
	if got := e.verifier.RevocationChecks() - before; got != 5 {
		t.Fatalf("revocation checks = %d, want 5 (rate limit first)", got)
	}
	e.verifier.Revoke("revoked-user")
	e.do(req{method: "GET", path: "/v1/me", token: "dev:revoked-user:google.com"})
	if r := e.do(req{method: "POST", path: "/v1/me/link", token: "dev:revoked-user:google.com", idemKey: newKey(), body: map[string]any{}}); r.status != 401 {
		t.Fatalf("revoked token: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/me", token: tok}); r.header.Get("Content-Security-Policy") != "default-src 'none'; frame-ancestors 'none'" {
		t.Fatalf("CSP header: %q", r.header.Get("Content-Security-Policy"))
	}
}

// The app guide tells developers which errors they may retry with the same
// Idempotency-Key: those produced before the idempotency step (429, 401, …)
// are not stored, so a retry with the same key still runs the action once.
func TestIdempotencyKeyReusableAfterRateLimit(t *testing.T) {
	e := newEnv(t)
	tok := "dev:retry-key:anonymous"
	e.do(req{method: "GET", path: "/v1/me", token: tok})
	// Use up the profile limit (20/min) with other keys.
	for range 20 {
		e.do(req{method: "PATCH", path: "/v1/me/profile", token: tok, idemKey: newKey(), body: map[string]any{"displayName": "A"}})
	}
	key := newKey()
	body := map[string]any{"displayName": "Rani"}
	if r := e.do(req{method: "PATCH", path: "/v1/me/profile", token: tok, idemKey: key, body: body}); r.status != 429 {
		t.Fatalf("over the limit: %d", r.status)
	}
	e.clock.advance(time.Minute)
	r := e.do(req{method: "PATCH", path: "/v1/me/profile", token: tok, idemKey: key, body: body})
	if r.status != 200 || get(r.body, "user", "displayName") != "Rani" {
		t.Fatalf("the same key must work after the 429: %d %s", r.status, r.raw)
	}
}
