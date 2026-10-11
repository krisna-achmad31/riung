package api_test

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/api"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

func nowRFC(e *env) string { return e.clock.now().UTC().Format(time.RFC3339) }

func todayJakarta(e *env) string {
	loc, _ := time.LoadLocation("Asia/Jakarta")
	return e.clock.now().In(loc).Format(time.DateOnly)
}

func TestActivitiesEndToEnd(t *testing.T) {
	e := newEnv(t)
	tok := "dev:act:anonymous"
	post := func(body map[string]any) resp {
		body["occurredAt"] = nowRFC(e)
		return e.do(req{method: "POST", path: "/v1/activities", token: tok, idemKey: newKey(), body: body})
	}
	r := post(map[string]any{"type": "checkin", "date": todayJakarta(e)})
	if r.status != 200 || get(r.body, "result", "coinsGranted") != float64(5) || get(r.body, "wallet", "coins") != float64(5) ||
		get(r.body, "result", "streak", "current") != float64(1) {
		t.Fatalf("checkin: %d %s", r.status, r.raw)
	}
	// Same business event with a new Idempotency-Key: replayed, not paid again.
	r = post(map[string]any{"type": "checkin", "date": todayJakarta(e)})
	if get(r.body, "result", "replayed") != true || get(r.body, "wallet", "coins") != float64(5) {
		t.Fatalf("replay: %s", r.raw)
	}
	// The client can never send an amount.
	if r := post(map[string]any{"type": "checkin", "date": todayJakarta(e), "coins": 500}); r.status != 400 {
		t.Fatalf("unknown field must be rejected: %d %s", r.status, r.raw)
	}
	for _, bad := range []map[string]any{
		{"type": "teleport"},
		{"type": "mission_completed", "date": todayJakarta(e), "index": 9},
		{"type": "minigame_finished", "saboteurId": "kabut", "won": true, "ref": "not-a-uuid"},
		{"type": "journal_saved"},
	} {
		if r := post(bad); r.status != 400 || errCode(r) != "invalid_request" {
			t.Fatalf("%v: %d %s", bad, r.status, r.raw)
		}
	}
	old := e.do(req{method: "POST", path: "/v1/activities", token: tok, idemKey: newKey(),
		body: map[string]any{"type": "checkin", "date": "2026-01-01", "occurredAt": "2026-01-01T03:00:00Z"}})
	if old.status != 400 {
		t.Fatalf("events older than 7 days: %d", old.status)
	}
	me := e.do(req{method: "GET", path: "/v1/me", token: tok})
	if get(me.body, "streak", "current") != float64(1) || get(me.body, "wallet", "coins") != float64(5) {
		t.Fatalf("/me reflects activities: %s", me.raw)
	}
}

func TestActivityBatch(t *testing.T) {
	e := newEnv(t)
	tok := "dev:batch:anonymous"
	at := nowRFC(e)
	events := []map[string]any{
		{"type": "checkin", "date": todayJakarta(e), "occurredAt": at},
		{"type": "mission_completed", "date": todayJakarta(e), "index": 0, "occurredAt": at},
		{"type": "teleport", "occurredAt": at},
		{"type": "mission_completed", "date": todayJakarta(e), "index": 0, "occurredAt": at},
	}
	r := e.do(req{method: "POST", path: "/v1/activities/batch", token: tok, idemKey: newKey(), body: map[string]any{"events": events}})
	results, _ := r.body["results"].([]any)
	if r.status != 200 || len(results) != 4 || get(r.body, "wallet", "coins") != float64(8) {
		t.Fatalf("batch: %d %s", r.status, r.raw)
	}
	okOf := func(i int) any { return results[i].(map[string]any)["ok"] }
	if okOf(0) != true || okOf(1) != true || okOf(2) != false || okOf(3) != true {
		t.Fatalf("per-event outcomes: %s", r.raw)
	}
	if results[3].(map[string]any)["result"].(map[string]any)["replayed"] != true {
		t.Fatal("duplicate event in a batch is replayed")
	}
	tooMany := make([]map[string]any, 51)
	for i := range tooMany {
		tooMany[i] = map[string]any{"type": "checkin"}
	}
	if r := e.do(req{method: "POST", path: "/v1/activities/batch", token: tok, idemKey: newKey(), body: map[string]any{"events": tooMany}}); r.status != 400 {
		t.Fatalf("51 events: %d", r.status)
	}
	// A large (but legal) batch body is accepted: the route allows 64 KB.
	big := make([]map[string]any, 50)
	for i := range big {
		big[i] = map[string]any{"type": "journal_saved", "entryId": fmt.Sprintf("entry-%02d-%s", i, strings.Repeat("x", 40)), "occurredAt": at}
	}
	if r := e.do(req{method: "POST", path: "/v1/activities/batch", token: tok, idemKey: newKey(), body: map[string]any{"events": big}}); r.status != 200 {
		t.Fatalf("50-event batch (>16 KB) must pass: %d %s", r.status, r.raw[:min(200, len(r.raw))])
	}
}

func TestShopAndLoadoutEndToEnd(t *testing.T) {
	e := newEnv(t)
	tok := "dev:shopper:google.com"
	me := e.do(req{method: "GET", path: "/v1/me", token: tok})
	userID, _ := get(me.body, "user", "id").(string)

	buy := func(body map[string]any) resp {
		return e.do(req{method: "POST", path: "/v1/shop/purchase", token: tok, idemKey: newKey(), body: body})
	}
	r := buy(map[string]any{"itemType": "cosmetic", "itemId": "topi_rajut", "expectedPrice": 100})
	if r.status != 409 || errCode(r) != "insufficient_coins" || get(r.body, "error", "details", "shortfall") != float64(100) {
		t.Fatalf("no coins: %d %s", r.status, r.raw)
	}
	seed(t, e, userID, 150)
	if r := buy(map[string]any{"itemType": "cosmetic", "itemId": "topi_rajut", "expectedPrice": 1}); r.status != 409 || errCode(r) != "price_changed" || get(r.body, "error", "details", "price") != float64(100) {
		t.Fatalf("stale price: %d %s", r.status, r.raw)
	}
	key := newKey()
	first := e.do(req{method: "POST", path: "/v1/shop/purchase", token: tok, idemKey: key, body: map[string]any{"itemType": "cosmetic", "itemId": "topi_rajut", "expectedPrice": 100}})
	if first.status != 200 || get(first.body, "wallet", "coins") != float64(50) {
		t.Fatalf("buy: %d %s", first.status, first.raw)
	}
	// Retrying the same request (network blip) must not charge twice.
	again := e.do(req{method: "POST", path: "/v1/shop/purchase", token: tok, idemKey: key, body: map[string]any{"itemType": "cosmetic", "itemId": "topi_rajut", "expectedPrice": 100}})
	if again.raw != first.raw || again.header.Get("Idempotent-Replayed") != "true" {
		t.Fatalf("retry: %s", again.raw)
	}
	if r := buy(map[string]any{"itemType": "cosmetic", "itemId": "topi_rajut", "expectedPrice": 100}); errCode(r) != "already_owned" {
		t.Fatalf("owned: %s", r.raw)
	}
	if r := buy(map[string]any{"itemType": "cosmetic", "itemId": "naga_hat", "expectedPrice": 100}); r.status != 404 {
		t.Fatalf("unknown item: %d", r.status)
	}
	if r := e.do(req{method: "PUT", path: "/v1/loadouts/monsters/kabut", token: tok, idemKey: newKey(), body: map[string]any{"items": []string{"topi_rajut"}}}); r.status != 200 {
		t.Fatalf("loadout: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "PUT", path: "/v1/loadouts/monsters/kabut", token: tok, idemKey: newKey(), body: map[string]any{"items": []string{"syal_hangat"}}}); errCode(r) != "not_owned" {
		t.Fatalf("not owned: %s", r.raw)
	}
	if r := e.do(req{method: "PUT", path: "/v1/loadouts/characters/jung", token: tok, idemKey: newKey(), body: map[string]any{"accessories": []string{}, "cardStyle": "aurora"}}); r.status != 403 || errCode(r) != "premium_required" {
		t.Fatalf("premium card style: %d %s", r.status, r.raw)
	}
	me = e.do(req{method: "GET", path: "/v1/me", token: tok})
	if items, _ := get(me.body, "inventory", "items").([]any); len(items) != 1 || get(me.body, "loadouts", "monsters", "kabut") == nil {
		t.Fatalf("/me inventory & loadout: %s", me.raw)
	}

	tx := e.do(req{method: "GET", path: "/v1/wallet/transactions?limit=1", token: tok})
	items, _ := tx.body["items"].([]any)
	if tx.status != 200 || len(items) != 1 || tx.body["nextCursor"] == nil || items[0].(map[string]any)["type"] != "spend" {
		t.Fatalf("transactions: %s", tx.raw)
	}
	next := e.do(req{method: "GET", path: "/v1/wallet/transactions?limit=1&cursor=" + tx.body["nextCursor"].(string), token: tok})
	if items2, _ := next.body["items"].([]any); len(items2) != 1 || items2[0].(map[string]any)["type"] != "earn" {
		t.Fatalf("page 2: %s", next.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/wallet/transactions?cursor=bogus", token: tok}); r.status != 400 {
		t.Fatalf("bad cursor: %d", r.status)
	}
}

// seed credits coins directly (tests only; real coins come from activities and billing).
func seed(t *testing.T, e *env, userID string, amount int) {
	t.Helper()
	err := e.store.WithUserTx(context.Background(), userID, func(tx *store.UserTx) error {
		_, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: amount, Reason: "test", Key: "seed-" + newKey()})
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestJournalAccessAndPremiumDaily(t *testing.T) {
	e := newEnv(t)
	tok := "dev:writer:google.com"
	r := e.do(req{method: "GET", path: "/v1/journal/access", token: tok})
	if r.status != 200 || r.body["canWrite"] != true || r.body["premium"] != false || r.body["freeEntriesPerDay"] != float64(1) {
		t.Fatalf("access: %s", r.raw)
	}
	e.do(req{method: "POST", path: "/v1/activities", token: tok, idemKey: newKey(),
		body: map[string]any{"type": "journal_saved", "entryId": "j1", "promptId": "p_waswas", "occurredAt": nowRFC(e)}})
	r = e.do(req{method: "GET", path: "/v1/journal/access?promptId=p_waswas", token: tok})
	if r.body["canWrite"] != false || r.body["reason"] != "daily_limit" || r.body["entriesToday"] != float64(1) {
		t.Fatalf("after one entry: %s", r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/journal/access?promptId=p_naga", token: tok}); r.status != 404 {
		t.Fatalf("unknown prompt: %d", r.status)
	}

	if r := e.do(req{method: "POST", path: "/v1/premium/daily-coins", token: tok, idemKey: newKey()}); r.status != 403 {
		t.Fatalf("daily coins without yearly plan: %d", r.status)
	}
	me := e.do(req{method: "GET", path: "/v1/me", token: tok})
	exp := e.clock.now().Add(300 * 24 * time.Hour)
	if err := e.store.UpsertSubscription(context.Background(), get(me.body, "user", "id").(string),
		store.Subscription{Plan: "premium_yearly", Status: "active", ExpiresAt: &exp}, nil); err != nil {
		t.Fatal(err)
	}
	r = e.do(req{method: "POST", path: "/v1/premium/daily-coins", token: tok, idemKey: newKey()})
	if r.status != 200 || get(r.body, "result", "coinsGranted") != float64(2) || get(r.body, "wallet", "purchasedCoins") != float64(2) {
		t.Fatalf("claim: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "POST", path: "/v1/premium/daily-coins", token: tok, idemKey: newKey()}); get(r.body, "result", "capped") != true {
		t.Fatalf("second claim: %s", r.raw)
	}
	me = e.do(req{method: "GET", path: "/v1/me", token: tok})
	if get(me.body, "premium", "status") != "active" || get(me.body, "today", "premiumDailyClaimed") != true || get(me.body, "today", "freeFocusLeft") != float64(3) {
		t.Fatalf("/me premium: %s", me.raw)
	}
	if r := e.do(req{method: "POST", path: "/v1/premium/daily-coins", token: "dev:anon-p:anonymous", idemKey: newKey()}); r.status != 403 || errCode(r) != "permanent_account_required" {
		t.Fatalf("anonymous: %d", r.status)
	}
}

func TestConfigCatalog(t *testing.T) {
	e := newEnv(t)
	r := e.do(req{method: "GET", path: "/v1/config"})
	cosmetics, _ := get(r.body, "catalog", "monsterCosmetics").([]any)
	styles, _ := get(r.body, "catalog", "cardStyles").([]any)
	if len(cosmetics) != 16 || len(styles) != 5 || get(r.body, "catalog", "streakShield", "price") != float64(20) {
		t.Fatalf("catalog: %s", r.raw[:min(400, len(r.raw))])
	}
	first := styles[0].(map[string]any)
	if first["id"] != "klasik" || first["free"] != true || first["price"] != nil {
		t.Fatalf("free style: %v", first)
	}
}

// --- Admin API ---------------------------------------------------------------------

func makeAdmin(t *testing.T, e *env, token string) string {
	t.Helper()
	// The admin must exist as a user (opened the app) and be listed.
	me := e.do(req{method: "GET", path: "/v1/me", token: strings.TrimSuffix(token, ":admin")})
	id := get(me.body, "user", "id").(string)
	if err := e.store.GrantAdmin(context.Background(), id, "test", "test setup"); err != nil {
		t.Fatal(err)
	}
	return id
}

func TestAdminAPI(t *testing.T) {
	e := newEnv(t)
	admin := "dev:boss:google.com:admin"
	makeAdmin(t, e, admin)

	// Every gate refuses with the same answer.
	for _, tok := range []string{"", "dev:boss:google.com", "dev:boss:anonymous:admin", "dev:stranger:google.com:admin"} {
		if r := e.do(req{method: "GET", path: "/admin/v1/settings", token: tok}); r.status != 403 && r.status != 401 {
			t.Fatalf("token %q: %d %s", tok, r.status, r.raw)
		}
	}
	if !strings.Contains(e.logs.String(), `"event":"admin_access_denied"`) {
		t.Fatal("denials must be logged")
	}

	r := e.do(req{method: "GET", path: "/admin/v1/settings", token: admin})
	list, _ := r.body["settings"].([]any)
	if r.status != 200 || len(list) != 3 {
		t.Fatalf("list: %d %s", r.status, r.raw)
	}
	put := func(key string, body map[string]any) resp {
		return e.do(req{method: "PUT", path: "/admin/v1/settings/" + key, token: admin, idemKey: newKey(), body: body})
	}
	if r := put("journalRewardsPerDay", map[string]any{"value": 99, "reason": "too much"}); r.status != 400 {
		t.Fatalf("out of range: %d", r.status)
	}
	if r := put("journalRewardsPerDay", map[string]any{"value": 5, "reason": ""}); r.status != 400 {
		t.Fatalf("reason required: %d", r.status)
	}
	if r := put("coinMultiplier", map[string]any{"value": 5, "reason": "nope"}); r.status != 404 {
		t.Fatalf("only allowlisted keys: %d", r.status)
	}
	if r := put("journalRewardsPerDay", map[string]any{"value": 5, "reason": "uji batas baru"}); r.status != 200 || r.body["value"] != float64(5) {
		t.Fatalf("set: %d %s", r.status, r.raw)
	}
	// Applies to the public API immediately (shared cache, no TTL wait).
	if cfg := e.do(req{method: "GET", path: "/v1/config"}); get(cfg.body, "economy", "caps", "journalRewardsPerDay") != float64(5) {
		t.Fatalf("public config after admin change: %s", cfg.raw[:min(300, len(cfg.raw))])
	}
	if r := e.do(req{method: "DELETE", path: "/admin/v1/settings/journalRewardsPerDay", token: admin, idemKey: newKey(), body: map[string]any{"reason": "kembali ke default"}}); r.status != 200 || r.body["value"] != float64(3) {
		t.Fatalf("reset: %d %s", r.status, r.raw)
	}
	audit := e.do(req{method: "GET", path: "/admin/v1/audit", token: admin})
	items, _ := audit.body["items"].([]any)
	if len(items) < 3 || items[0].(map[string]any)["action"] != "setting.reset" || items[1].(map[string]any)["reason"] != "uji batas baru" {
		t.Fatalf("audit: %s", audit.raw)
	}
	if !strings.Contains(e.logs.String(), `"event":"admin_setting_changed"`) {
		t.Fatal("changes must be logged")
	}

	// Stale sign-in (older than 15 minutes) is refused.
	e.clock.advance(20 * time.Minute)
	if r := e.do(req{method: "GET", path: "/admin/v1/settings", token: admin}); r.status != 403 {
		t.Fatalf("stale admin token: %d", r.status)
	}
	// The admin routes do not exist on the public listener.
	if r := e.do(req{method: "GET", path: "/v1/../admin/v1/settings", token: admin}); r.status == 200 {
		t.Fatal("admin API must not be reachable on the public port")
	}
}

func TestAdminSourceAllowlist(t *testing.T) {
	e := newEnv(t)
	// An admin handler that only allows another network.
	h := api.NewAdminHandler(api.Deps{Config: adminOnly("10.0.0.0/8"), Logger: discardLogger(), Store: e.store, Verifier: e.verifier, Economy: econForTest()})
	srv := httptest.NewServer(h)
	defer srv.Close()
	res, err := http.Get(srv.URL + "/admin/v1/settings")
	if err != nil {
		t.Fatal(err)
	}
	_ = res.Body.Close()
	if res.StatusCode != 403 {
		t.Fatalf("connections from outside the allowlist: %d", res.StatusCode)
	}
}

func adminOnly(cidr string) config.Config {
	c, _ := config.Load(func(k string) string {
		return map[string]string{"DEV_AUTH": "true", "ADMIN_LISTEN_ADDR": ":0", "ADMIN_ALLOWED_CIDRS": cidr}[k]
	})
	return c
}

func discardLogger() *slog.Logger { return logx.New(io.Discard, slog.LevelError) }

func econForTest() economy.Props { return economy.MustLoad() }
