package api_test

import (
	"context"
	"encoding/json"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/store"
	"github.com/krisna-achmad31/riung/backend/internal/ticket"
)

func issueTicket(e *env, tok string, body map[string]any) resp {
	return e.do(req{method: "POST", path: "/v1/focus/tickets", token: tok, idemKey: newKey(), body: body})
}

// signedTicket decodes the ticket of an issue response.
func signedTicket(t *testing.T, r resp) ticket.Ticket {
	t.Helper()
	raw, _ := json.Marshal(r.body["ticket"])
	var tk ticket.Ticket
	if err := json.Unmarshal(raw, &tk); err != nil || tk.ID == "" {
		t.Fatalf("ticket: %s", r.raw)
	}
	return tk
}

func focusDone(e *env, tok, ticketID string, at time.Time) resp {
	return e.do(req{method: "POST", path: "/v1/activities", token: tok, idemKey: newKey(), body: map[string]any{
		"type": "focus_completed", "ticketId": ticketID, "saboteurId": "nanti", "occurredAt": at.UTC().Format(time.RFC3339),
	}})
}

func TestFocusFreeTicketLifecycle(t *testing.T) {
	e := newEnv(t)
	tok := "dev:focus-free:anonymous"
	cfg := e.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-Firebase-AppCheck": "dev"}})
	keys, _ := cfg.body["focusTicketKeys"].([]any)
	if len(keys) != 1 {
		t.Fatalf("config must publish the ticket key: %s", cfg.raw)
	}
	pub, _ := keys[0].(map[string]any)["publicKey"].(string)

	r := issueTicket(e, tok, map[string]any{"source": "free_daily", "durationMin": 25})
	if r.status != 200 || r.body["freeFocusLeft"] != 0.0 {
		t.Fatalf("issue: %d %s", r.status, r.raw)
	}
	tk := signedTicket(t, r)
	if !ticket.Verify(pub, tk) || tk.Source != "free_daily" || tk.DurationMin != 25 {
		t.Fatalf("ticket must verify with the published key: %+v", tk)
	}
	// Free tickets end at local midnight (Asia/Jakarta by default).
	exp, _ := time.Parse(time.RFC3339, tk.ExpiresAt)
	if exp.In(mustLoc(t, "Asia/Jakarta")).Hour() != 0 || !exp.After(e.clock.now()) || exp.Sub(e.clock.now()) > 24*time.Hour {
		t.Fatalf("free ticket expiry: %s", tk.ExpiresAt)
	}
	// One free ticket a day without Premium.
	r = issueTicket(e, tok, map[string]any{"source": "free_daily", "durationMin": 60})
	if r.status != 409 || errCode(r) != "limit_reached" || get(r.body, "error", "details", "reason") != "free_daily" ||
		get(r.body, "error", "details", "resetsAt") == nil {
		t.Fatalf("second free ticket: %d %s", r.status, r.raw)
	}
	list := e.do(req{method: "GET", path: "/v1/focus/tickets", token: tok})
	if tickets, _ := list.body["tickets"].([]any); list.status != 200 || len(tickets) != 1 {
		t.Fatalf("open tickets: %d %s", list.status, list.raw)
	}

	// A session cannot finish before it could have run.
	if r := focusDone(e, tok, tk.ID, e.clock.now()); r.status != 409 || errCode(r) != "ticket_invalid" ||
		get(r.body, "error", "details", "reason") != "too_early" {
		t.Fatalf("instant completion: %d %s", r.status, r.raw)
	}
	e.clock.advance(25 * time.Minute)
	r = focusDone(e, tok, tk.ID, e.clock.now())
	if r.status != 200 || get(r.body, "result", "monster", "progress") != 4.0 || get(r.body, "result", "coinsGranted") != 0.0 {
		t.Fatalf("completion: %d %s", r.status, r.raw)
	}
	// Reported again (outbox retry): replayed, no extra progress.
	if r := focusDone(e, tok, tk.ID, e.clock.now()); r.status != 200 || get(r.body, "result", "replayed") != true {
		t.Fatalf("replay: %d %s", r.status, r.raw)
	}
	if tickets, _ := e.do(req{method: "GET", path: "/v1/focus/tickets", token: tok}).body["tickets"].([]any); len(tickets) != 0 {
		t.Fatal("a used ticket is no longer open")
	}
	// Someone else's ticket does not exist for this user.
	other := signedTicket(t, issueTicket(e, "dev:focus-other:anonymous", map[string]any{"source": "free_daily", "durationMin": 25}))
	e.clock.advance(30 * time.Minute)
	if r := focusDone(e, tok, other.ID, e.clock.now()); r.status != 409 || get(r.body, "error", "details", "reason") != "not_found" {
		t.Fatalf("foreign ticket: %d %s", r.status, r.raw)
	}
	// The next day brings a new free ticket.
	e.clock.advance(24 * time.Hour)
	if r := issueTicket(e, tok, map[string]any{"source": "free_daily", "durationMin": 45}); r.status != 200 {
		t.Fatalf("next day: %d %s", r.status, r.raw)
	}
	logs := e.logs.String()
	for _, ev := range []string{"focus_ticket_issued", "focus_ticket_redeemed", "focus_ticket_invalid"} {
		if !strings.Contains(logs, `"event":"`+ev+`"`) {
			t.Fatalf("missing %s log", ev)
		}
	}
}

func mustLoc(t *testing.T, name string) *time.Location {
	t.Helper()
	loc, err := time.LoadLocation(name)
	if err != nil {
		t.Fatal(err)
	}
	return loc
}

func TestFocusPremiumGetsThreeFreeTickets(t *testing.T) {
	e := newEnv(t)
	tok := "dev:focus-premium:google.com"
	userID, _ := billingAccount(t, e, tok)
	end := e.clock.now().Add(30 * 24 * time.Hour)
	if err := e.store.UpsertSubscription(context.Background(), userID, store.Subscription{Plan: "premium_monthly", Status: "active",
		ExpiresAt: &end, AutoRenewing: true}, nil); err != nil {
		t.Fatal(err)
	}
	for i := range 3 {
		if r := issueTicket(e, tok, map[string]any{"source": "free_daily", "durationMin": 25}); r.status != 200 || r.body["freeFocusLeft"] != float64(2-i) {
			t.Fatalf("free ticket %d: %d %s", i+1, r.status, r.raw)
		}
	}
	if r := issueTicket(e, tok, map[string]any{"source": "free_daily", "durationMin": 25}); r.status != 409 {
		t.Fatalf("fourth free ticket: %d", r.status)
	}
}

func TestFocusPrepaidAndCoinTickets(t *testing.T) {
	e := newEnv(t)
	tok := "dev:focus-paid:anonymous"
	userID := get(e.do(req{method: "GET", path: "/v1/me", token: tok}).body, "user", "id").(string)

	if r := issueTicket(e, tok, map[string]any{"source": "prepaid", "durationMin": 25}); r.status != 409 ||
		get(r.body, "error", "details", "reason") != "no_prepaid_sessions" {
		t.Fatalf("no prepaid sessions: %d %s", r.status, r.raw)
	}
	seed(t, e, userID, 150)
	if r := e.do(req{method: "POST", path: "/v1/shop/purchase", token: tok, idemKey: newKey(),
		body: map[string]any{"itemType": "focus_pack", "itemId": "focus_5", "expectedPrice": 100}}); r.status != 200 {
		t.Fatalf("focus pack: %d %s", r.status, r.raw)
	}
	r := issueTicket(e, tok, map[string]any{"source": "prepaid", "durationMin": 60})
	if r.status != 200 || r.body["prepaidFocus"] != 4.0 || walletNum(r, "coins") != 50 {
		t.Fatalf("prepaid ticket: %d %s", r.status, r.raw)
	}
	tk := signedTicket(t, r)
	issued, _ := time.Parse(time.RFC3339, tk.IssuedAt)
	if exp, _ := time.Parse(time.RFC3339, tk.ExpiresAt); exp.Sub(issued) != 30*24*time.Hour {
		t.Fatalf("prepaid validity: %+v", tk)
	}

	// Coin tickets: 25/40/50 by duration, expectedPrice required and checked.
	if r := issueTicket(e, tok, map[string]any{"source": "coins", "durationMin": 45}); r.status != 400 {
		t.Fatalf("missing expectedPrice: %d", r.status)
	}
	if r := issueTicket(e, tok, map[string]any{"source": "coins", "durationMin": 45, "expectedPrice": 25}); r.status != 409 ||
		errCode(r) != "price_changed" || get(r.body, "error", "details", "price") != 40.0 {
		t.Fatalf("stale price: %d %s", r.status, r.raw)
	}
	r = issueTicket(e, tok, map[string]any{"source": "coins", "durationMin": 45, "expectedPrice": 40})
	if r.status != 200 || r.body["price"] != 40.0 || walletNum(r, "coins") != 10 {
		t.Fatalf("coin ticket: %d %s", r.status, r.raw)
	}
	coinTicket := signedTicket(t, r)
	if r := issueTicket(e, tok, map[string]any{"source": "coins", "durationMin": 60, "expectedPrice": 50}); r.status != 409 ||
		errCode(r) != "insufficient_coins" {
		t.Fatalf("not enough coins: %d %s", r.status, r.raw)
	}
	for _, bad := range []map[string]any{{"source": "coins", "durationMin": 30, "expectedPrice": 30}, {"source": "gift", "durationMin": 25}} {
		if r := issueTicket(e, tok, bad); r.status != 400 {
			t.Fatalf("%v: %d", bad, r.status)
		}
	}

	// A ticket whose session would start after it expired cannot be redeemed.
	e.clock.advance(31 * 24 * time.Hour)
	if r := focusDone(e, tok, coinTicket.ID, e.clock.now()); r.status != 409 || get(r.body, "error", "details", "reason") != "expired" {
		t.Fatalf("expired ticket: %d %s", r.status, r.raw)
	}
	// In a batch, a bad ticket is reported per event and does not stop the rest.
	batch := e.do(req{method: "POST", path: "/v1/activities/batch", token: tok, idemKey: newKey(), body: map[string]any{"events": []any{
		map[string]any{"type": "focus_completed", "ticketId": coinTicket.ID, "saboteurId": "nanti", "occurredAt": e.clock.now().UTC().Format(time.RFC3339)},
		map[string]any{"type": "mission_completed", "date": todayJakarta(e), "index": 0, "occurredAt": e.clock.now().UTC().Format(time.RFC3339)},
	}}})
	results, _ := batch.body["results"].([]any)
	if batch.status != 200 || len(results) != 2 || get(results[0].(map[string]any), "error", "code") != "ticket_invalid" ||
		results[1].(map[string]any)["ok"] != true {
		t.Fatalf("batch: %d %s", batch.status, batch.raw)
	}
}

func unlock(e *env, tok string, body map[string]any) resp {
	return e.do(req{method: "POST", path: "/v1/appbeku/unlocks", token: tok, idemKey: newKey(), body: body})
}

const (
	instagram = "com.instagram.android"
	tiktok    = "com.zhiliaoapp.musically"
	youtube   = "com.google.android.youtube"
)

func TestAppBekuEthicalGuard(t *testing.T) {
	e := newEnv(t)
	tok := "dev:beku:anonymous"
	userID := get(e.do(req{method: "GET", path: "/v1/me", token: tok}).body, "user", "id").(string)
	seed(t, e, userID, 300)

	r := unlock(e, tok, map[string]any{"appId": instagram, "minutes": 10, "expectedPrice": 15})
	if r.status != 200 || get(r.body, "result", "price") != 15.0 || get(r.body, "result", "paidUnlocksUsed") != 1.0 ||
		get(r.body, "result", "paidUnlocksLeft") != 2.0 || walletNum(r, "coins") != 285 {
		t.Fatalf("first unlock: %d %s", r.status, r.raw)
	}
	if grants, _ := get(r.body, "result", "grants").([]any); len(grants) != 1 || grants[0].(map[string]any)["minutes"] != 10.0 {
		t.Fatalf("grants: %s", r.raw)
	}
	// A pause between paid unlocks keeps the decision deliberate.
	if r := unlock(e, tok, map[string]any{"appId": instagram, "minutes": 20, "expectedPrice": 35}); r.status != 409 ||
		errCode(r) != "cooldown" || get(r.body, "error", "details", "retryAfterSeconds") == nil {
		t.Fatalf("cooldown: %d %s", r.status, r.raw)
	}
	e.clock.advance(61 * time.Second)
	// Each unlock today costs +10 more.
	if r := unlock(e, tok, map[string]any{"appId": instagram, "minutes": 20, "expectedPrice": 25}); r.status != 409 ||
		errCode(r) != "price_changed" || get(r.body, "error", "details", "price") != 35.0 {
		t.Fatalf("escalated price: %d %s", r.status, r.raw)
	}
	if r := unlock(e, tok, map[string]any{"appId": instagram, "minutes": 20, "expectedPrice": 35}); r.status != 200 {
		t.Fatalf("second unlock: %d %s", r.status, r.raw)
	}
	e.clock.advance(61 * time.Second)
	// A bundle is one unlock, charged once.
	r = unlock(e, tok, map[string]any{"bundleId": "santai", "expectedPrice": 55})
	if grants, _ := get(r.body, "result", "grants").([]any); r.status != 200 || len(grants) != 2 || get(r.body, "result", "paidUnlocksLeft") != 0.0 {
		t.Fatalf("santai bundle: %d %s", r.status, r.raw)
	}
	e.clock.advance(61 * time.Second)
	if r := unlock(e, tok, map[string]any{"appId": tiktok, "minutes": 10, "expectedPrice": 45}); r.status != 409 ||
		errCode(r) != "limit_reached" || get(r.body, "error", "details", "limit") != 3.0 {
		t.Fatalf("fourth unlock: %d %s", r.status, r.raw)
	}
	// Tomorrow the count and the price start over.
	e.clock.advance(24 * time.Hour)
	if r := unlock(e, tok, map[string]any{"bundleId": "sosmed", "appIds": []string{instagram, youtube}, "expectedPrice": 75}); r.status != 200 ||
		get(r.body, "result", "paidUnlocksUsed") != 1.0 {
		t.Fatalf("next day: %d %s", r.status, r.raw)
	}

	// No app-usage history: neither logs nor the ledger name the apps.
	tx := e.do(req{method: "GET", path: "/v1/wallet/transactions", token: tok})
	if strings.Contains(tx.raw, "com.") || strings.Contains(e.logs.String(), instagram) {
		t.Fatalf("app ids must not be stored or logged: %s", tx.raw)
	}
}

func TestAppBekuOnlyPracticeCoins(t *testing.T) {
	e := newEnv(t)
	tok := "dev:beku-bought:anonymous"
	userID := get(e.do(req{method: "GET", path: "/v1/me", token: tok}).body, "user", "id").(string)
	err := e.store.WithUserTx(context.Background(), userID, func(tx *store.UserTx) error {
		_, err := tx.Credit(store.Credit{Type: "purchase", Bucket: store.BucketPurchased, Amount: 500, Reason: "test", Key: "buy-" + newKey()})
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	r := unlock(e, tok, map[string]any{"appId": instagram, "minutes": 10, "expectedPrice": 15})
	if r.status != 409 || errCode(r) != "insufficient_coins" || get(r.body, "error", "details", "earnedOnly") != true {
		t.Fatalf("bought coins cannot unlock: %d %s", r.status, r.raw)
	}
	if !strings.Contains(e.logs.String(), `"reason":"earned_only"`) {
		t.Fatal("blocked unlock must be logged")
	}
	// A refused unlock does not count toward the daily limit or the pause.
	seed(t, e, userID, 15)
	if r := unlock(e, tok, map[string]any{"appId": instagram, "minutes": 10, "expectedPrice": 15}); r.status != 200 ||
		walletNum(r, "purchasedCoins") != 500 {
		t.Fatalf("practice coins unlock: %d %s", r.status, r.raw)
	}
}

func TestAppBekuValidation(t *testing.T) {
	e := newEnv(t)
	tok := "dev:beku-bad:anonymous"
	for _, body := range []map[string]any{
		{"appId": "com.whatsapp", "minutes": 10, "expectedPrice": 15},                                    // not freezable
		{"appId": "com.example.anything", "minutes": 10, "expectedPrice": 15},                            // not in catalog
		{"appId": instagram, "minutes": 15, "expectedPrice": 15},                                         // no such unit
		{"appId": instagram, "minutes": 10, "bundleId": "santai", "expectedPrice": 15},                   // both
		{"bundleId": "santai", "appIds": []string{instagram, youtube}, "expectedPrice": 35},              // wrong apps
		{"bundleId": "sosmed", "expectedPrice": 75},                                                      // which apps?
		{"bundleId": "sosmed", "appIds": []string{instagram, "com.mobile.legends"}, "expectedPrice": 75}, // not sosmed
		{"bundleId": "sosmed", "appIds": []string{instagram, instagram}, "expectedPrice": 75},            // duplicate
		{"bundleId": "liburan", "expectedPrice": 75},
		{"expectedPrice": 15},
	} {
		if r := unlock(e, tok, body); r.status != 400 {
			t.Fatalf("%v: %d %s", body, r.status, r.raw)
		}
	}
	cfg := e.do(req{method: "GET", path: "/v1/config", headers: map[string]string{"X-Firebase-AppCheck": "dev"}})
	units, _ := get(cfg.body, "catalog", "appbeku", "units").([]any)
	bundles, _ := get(cfg.body, "catalog", "appbeku", "bundles").([]any)
	if len(units) != 4 || units[0].(map[string]any)["price"] != 15.0 || len(bundles) != 2 {
		t.Fatalf("config appbeku catalog: %s", cfg.raw)
	}
}

func TestFocusAndAppBekuUnderConcurrency(t *testing.T) {
	e := newEnv(t)
	tok := "dev:race:anonymous"
	userID := get(e.do(req{method: "GET", path: "/v1/me", token: tok}).body, "user", "id").(string)
	seed(t, e, userID, 500)

	parallel := func(n int, call func() resp) map[int]int {
		statuses := make(chan int, n)
		var wg sync.WaitGroup
		for range n {
			wg.Go(func() { statuses <- call().status })
		}
		wg.Wait()
		close(statuses)
		count := map[int]int{}
		for s := range statuses {
			count[s]++
		}
		return count
	}
	if got := parallel(8, func() resp { return issueTicket(e, tok, map[string]any{"source": "free_daily", "durationMin": 25}) }); got[200] != 1 || got[409] != 7 {
		t.Fatalf("free tickets in parallel: %v", got)
	}
	if got := parallel(8, func() resp {
		return unlock(e, tok, map[string]any{"appId": instagram, "minutes": 10, "expectedPrice": 15})
	}); got[200] != 1 || got[409] != 7 {
		t.Fatalf("paid unlocks in parallel: %v", got)
	}
	w := e.do(req{method: "GET", path: "/v1/wallet", token: tok})
	if walletNum(w, "coins") != 485 {
		t.Fatalf("charged once: %s", w.raw)
	}
}

func TestFocusSessionsCannotOverlap(t *testing.T) {
	e := newEnv(t)
	tok := "dev:focus-overlap:anonymous"
	userID := get(e.do(req{method: "GET", path: "/v1/me", token: tok}).body, "user", "id").(string)
	seed(t, e, userID, 200)
	coin := func() ticket.Ticket {
		return signedTicket(t, issueTicket(e, tok, map[string]any{"source": "coins", "durationMin": 25, "expectedPrice": 25}))
	}
	a, b, c := coin(), coin(), coin()

	// occurredAt may run ahead of the server, but the server clock must also
	// have reached the end of the session.
	e.clock.advance(21 * time.Minute)
	if r := focusDone(e, tok, a.ID, e.clock.now().Add(4*time.Minute)); r.status != 409 ||
		get(r.body, "error", "details", "reason") != "too_early" {
		t.Fatalf("reported ahead of the server clock: %d %s", r.status, r.raw)
	}
	e.clock.advance(4 * time.Minute)
	end := e.clock.now()
	if r := focusDone(e, tok, a.ID, end); r.status != 200 {
		t.Fatalf("first session: %d %s", r.status, r.raw)
	}
	// Several tickets cannot pay for the same 25 minutes.
	if r := focusDone(e, tok, b.ID, end); r.status != 409 || get(r.body, "error", "details", "reason") != "overlap" {
		t.Fatalf("overlapping session: %d %s", r.status, r.raw)
	}
	// Back-to-back sessions are fine (a minute of clock slack either way).
	e.clock.advance(25 * time.Minute)
	if r := focusDone(e, tok, b.ID, end.Add(25*time.Minute-30*time.Second)); r.status != 200 {
		t.Fatalf("next session: %d %s", r.status, r.raw)
	}
	// A session cannot have ended before its ticket existed.
	if r := focusDone(e, tok, c.ID, end.Add(-25*time.Minute)); r.status != 409 || get(r.body, "error", "details", "reason") != "too_early" {
		t.Fatalf("session before the ticket: %d %s", r.status, r.raw)
	}
}
