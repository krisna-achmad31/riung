package api_test

import (
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/appstore/appstoretest"
	"github.com/krisna-achmad31/riung/backend/internal/config"
)

const bundleID = "id.riung.riung"

var uuidV8 = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`)

// appAccount returns the user's appAccountToken from GET /v1/me.
func appAccount(t *testing.T, e *env, token string) string {
	t.Helper()
	me := e.do(req{method: "GET", path: "/v1/me", token: token})
	aat, _ := get(me.body, "user", "appAccountToken").(string)
	if !uuidV8.MatchString(aat) {
		t.Fatalf("appAccountToken %q: %s", aat, me.raw)
	}
	return aat
}

func verifyApple(e *env, token, productID, transactionID string) resp {
	return e.do(req{method: "POST", path: "/v1/billing/appstore/verify", token: token, idemKey: newKey(),
		body: map[string]string{"productId": productID, "transactionId": transactionID}})
}

func coinTxn(id, productID, accountToken string) appstore.Transaction {
	return appstore.Transaction{TransactionID: id, OriginalTransactionID: id, BundleID: bundleID, ProductID: productID,
		Type: appstore.TypeConsumable, Quantity: 1, AppAccountToken: accountToken, Environment: appstore.EnvProduction}
}

func subStatus(e *env, status int, autoRenew int, latestID, originalID, plan, accountToken string, days int) appstore.SubscriptionStatus {
	return appstore.SubscriptionStatus{Status: status,
		Transaction: appstore.Transaction{TransactionID: latestID, OriginalTransactionID: originalID, BundleID: bundleID,
			ProductID: plan, Type: appstore.TypeAutoRenewing, AppAccountToken: accountToken, Environment: appstore.EnvSandbox,
			ExpiresDate: e.clock.now().Add(time.Duration(days) * 24 * time.Hour).UnixMilli()},
		Renewal: appstore.RenewalInfo{OriginalTransactionID: originalID, AutoRenewProductID: plan, AutoRenewStatus: autoRenew}}
}

func TestAppStoreVerifyCoinPack(t *testing.T) {
	e := newEnv(t)
	tok := "dev:ios-buyer:apple.com"
	aat := appAccount(t, e, tok)
	if other := appAccount(t, e, googleToken); other == aat {
		t.Fatal("appAccountToken must differ per user")
	}
	// StoreKit may report the UUID in upper case.
	e.apple.PutTransaction(coinTxn("2000000001", "coin_pack_medium", strings.ToUpper(aat)))

	if r := verifyApple(e, anonToken, "coin_pack_medium", "2000000001"); r.status != 403 || errCode(r) != "permanent_account_required" {
		t.Fatalf("anonymous: %d %s", r.status, r.raw)
	}
	r := verifyApple(e, tok, "coin_pack_medium", "2000000001")
	if r.status != 200 || get(r.body, "result", "status") != "credited" || get(r.body, "result", "coinsGranted") != 330.0 ||
		get(r.body, "result", "test") != false || walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("verify: %d %s", r.status, r.raw)
	}
	r = verifyApple(e, tok, "coin_pack_medium", "2000000001")
	if r.status != 200 || get(r.body, "result", "status") != "already_credited" || walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("second verify: %d %s", r.status, r.raw)
	}
	// Someone else sending the same transaction gets nothing.
	if r := verifyApple(e, googleToken, "coin_pack_medium", "2000000001"); r.status != 409 || errCode(r) != "purchase_invalid" {
		t.Fatalf("other user: %d %s", r.status, r.raw)
	}

	revoked := coinTxn("2000000003", "coin_pack_small", aat)
	revoked.RevocationDate = e.clock.now().UnixMilli()
	e.apple.PutTransaction(revoked)
	e.apple.PutTransaction(coinTxn("2000000004", "coin_pack_small", "00000000-0000-8000-8000-000000000000"))
	e.apple.PutTransaction(coinTxn("2000000005", "coin_pack_small", ""))
	for name, c := range map[string][2]string{
		"revoked":                {"coin_pack_small", "2000000003"},
		"other account token":    {"coin_pack_small", "2000000004"},
		"no account token":       {"coin_pack_small", "2000000005"},
		"product does not match": {"coin_pack_large", "2000000001"},
		"unknown at Apple":       {"coin_pack_small", "2000000999"},
	} {
		if r := verifyApple(e, tok, c[0], c[1]); r.status != 409 || errCode(r) != "purchase_invalid" {
			t.Errorf("%s: %d %s", name, r.status, r.raw)
		}
	}
	if r := verifyApple(e, tok, "gems_pack", "2000000001"); r.status != 400 {
		t.Fatalf("unknown product: %d", r.status)
	}
	if r := verifyApple(e, tok, "coin_pack_small", "bad id with spaces"); r.status != 400 {
		t.Fatalf("invalid transactionId: %d", r.status)
	}
	e.apple.Fail("2000000006", appstore.ErrUnavailable)
	if r := verifyApple(e, tok, "coin_pack_small", "2000000006"); r.status != 503 || !strings.Contains(e.logs.String(), `"dependency":"app_store"`) {
		t.Fatalf("apple down: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/wallet", token: tok}); walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("wallet: %s", r.raw)
	}
}

func TestAppStoreSubscription(t *testing.T) {
	e := newEnv(t)
	tok := "dev:ios-sub:apple.com"
	aat := appAccount(t, e, tok)
	e.apple.PutSubscription(subStatus(e, appstore.StatusActive, 1, "3000000002", "3000000001", "premium_yearly", aat, 365))

	// The app may send any transaction of the subscription (here: the renewal).
	r := verifyApple(e, tok, "premium_yearly", "3000000002")
	if r.status != 200 || get(r.body, "result", "status") != "active" || get(r.body, "result", "test") != true ||
		get(r.body, "premium", "status") != "active" || get(r.body, "premium", "plan") != "premium_yearly" ||
		get(r.body, "premium", "autoRenewing") != true {
		t.Fatalf("verify: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "POST", path: "/v1/premium/daily-coins", token: tok, idemKey: newKey()}); r.status != 200 {
		t.Fatalf("yearly App Store plan must earn daily coins: %d %s", r.status, r.raw)
	}
	if r := verifyApple(e, googleToken, "premium_yearly", "3000000002"); r.status != 409 {
		t.Fatalf("other user: %d %s", r.status, r.raw)
	}

	// Auto-renew turned off: Premium continues until the paid period ends.
	e.apple.PutSubscription(subStatus(e, appstore.StatusActive, 0, "3000000002", "3000000001", "premium_yearly", aat, 365))
	r = verifyApple(e, tok, "premium_yearly", "3000000002")
	if get(r.body, "result", "status") != "active" || get(r.body, "premium", "status") != "active" || get(r.body, "premium", "autoRenewing") != false {
		t.Fatalf("canceled: %s", r.raw)
	}

	// Resubscribed from the App Store settings (no appAccountToken): accepted
	// for the owner only.
	e.apple.PutSubscription(subStatus(e, appstore.StatusActive, 1, "3000000003", "3000000001", "premium_monthly", "", 30))
	if r := verifyApple(e, tok, "premium_monthly", "3000000003"); r.status != 200 || get(r.body, "premium", "plan") != "premium_monthly" {
		t.Fatalf("owner resubscribe: %d %s", r.status, r.raw)
	}
	e.apple.PutSubscription(subStatus(e, appstore.StatusActive, 1, "3100000002", "3100000001", "premium_monthly", "", 30))
	if r := verifyApple(e, tok, "premium_monthly", "3100000002"); r.status != 409 {
		t.Fatalf("unowned subscription without account token: %d %s", r.status, r.raw)
	}

	// Billing retry (no access) answers inactive.
	e.apple.PutSubscription(subStatus(e, appstore.StatusBillingRetry, 1, "3000000003", "3000000001", "premium_monthly", aat, -1))
	if r := verifyApple(e, tok, "premium_monthly", "3000000003"); get(r.body, "result", "status") != "inactive" {
		t.Fatalf("billing retry: %s", r.raw)
	}
}

func TestAppStoreRestore(t *testing.T) {
	e := newEnv(t)
	tok := "dev:ios-restore:apple.com"
	aat := appAccount(t, e, tok)
	e.apple.PutTransaction(coinTxn("4000000001", "coin_pack_small", aat))
	e.apple.PutSubscription(subStatus(e, appstore.StatusActive, 1, "4000000011", "4000000010", "premium_monthly", aat, 30))
	r := e.do(req{method: "POST", path: "/v1/billing/appstore/restore", token: tok, idemKey: newKey(), body: map[string]any{
		"purchases": []map[string]string{
			{"productId": "coin_pack_small", "transactionId": "4000000001"},
			{"productId": "premium_monthly", "transactionId": "4000000011"},
			{"productId": "coin_pack_small", "transactionId": "4999999999"},
			{"productId": "coin_pack_small", "transactionId": "not valid!"},
		}}})
	results, _ := r.body["results"].([]any)
	if r.status != 200 || len(results) != 4 {
		t.Fatalf("restore: %d %s", r.status, r.raw)
	}
	want := []struct{ id, status, code string }{
		{"4000000001", "credited", ""}, {"4000000011", "active", ""}, {"4999999999", "", "purchase_invalid"}, {"not valid!", "", "invalid_request"},
	}
	for i, w := range want {
		row := results[i].(map[string]any)
		if row["transactionId"] != w.id {
			t.Errorf("row %d transactionId = %v, want %s", i, row["transactionId"], w.id)
		}
		if w.status != "" && (row["ok"] != true || get(row, "result", "status") != w.status) {
			t.Errorf("row %d: %v", i, row)
		}
		if w.code != "" && (row["ok"] != false || get(row, "error", "code") != w.code) {
			t.Errorf("row %d: %v", i, row)
		}
	}
	if walletNum(r, "purchasedCoins") != 80 || get(r.body, "premium", "status") != "active" {
		t.Fatalf("restore totals: %s", r.raw)
	}
	if r := e.do(req{method: "POST", path: "/v1/billing/appstore/restore", token: tok, idemKey: newKey(),
		body: map[string]any{"purchases": []any{}}}); r.status != 400 {
		t.Fatalf("empty restore: %d", r.status)
	}
}

// notify posts a signed App Store Server Notification V2.
func notify(e *env, signer interface {
	Sign(testing.TB, any) string
}, n map[string]any) resp {
	return e.do(req{method: "POST", path: "/v1/webhooks/app-store", body: map[string]string{"signedPayload": signer.Sign(e.t, n)}})
}

func notification(uuid, kind string, data map[string]any) map[string]any {
	return map[string]any{"notificationType": kind, "notificationUUID": uuid, "version": "2.0", "data": data}
}

func TestAppStoreWebhookRefundsCoins(t *testing.T) {
	e := newEnv(t)
	tok := "dev:ios-refund:apple.com"
	aat := appAccount(t, e, tok)
	txn := coinTxn("5000000001", "coin_pack_medium", aat)
	e.apple.PutTransaction(txn)
	if r := verifyApple(e, tok, "coin_pack_medium", "5000000001"); walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("verify: %s", r.raw)
	}
	txn.RevocationDate = e.clock.now().UnixMilli()
	refund := notification("11111111-1111-4111-8111-111111111111", "REFUND", map[string]any{
		"bundleId": bundleID, "environment": "Production", "signedTransactionInfo": e.appleCA.Sign(t, txn)})
	if r := notify(e, e.appleCA, refund); r.status != 200 {
		t.Fatalf("refund: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/wallet", token: tok}); walletNum(r, "purchasedCoins") != 0 || walletNum(r, "debtCoins") != 0 {
		t.Fatalf("after refund: %s", r.raw)
	}
	logs := e.logs.String()
	if !strings.Contains(logs, `"event":"refund_applied"`) || !strings.Contains(logs, `"store":"app_store"`) {
		t.Fatalf("refund must be logged:\n%s", logs)
	}
	// Apple retries: the same notification never claws back twice.
	if r := notify(e, e.appleCA, refund); r.status != 200 {
		t.Fatalf("duplicate: %d", r.status)
	}
	again := notification("22222222-2222-4222-8222-222222222222", "REFUND", refund["data"].(map[string]any))
	if r := notify(e, e.appleCA, again); r.status != 200 {
		t.Fatalf("second refund notification: %d", r.status)
	}
	if r := e.do(req{method: "GET", path: "/v1/wallet", token: tok}); walletNum(r, "debtCoins") != 0 {
		t.Fatalf("refund applied twice: %s", r.raw)
	}
	// A refunded transaction cannot be verified again.
	if r := verifyApple(e, tok, "coin_pack_medium", "5000000001"); r.status != 409 {
		t.Fatalf("verify after refund: %d %s", r.status, r.raw)
	}
}

func TestAppStoreWebhookSubscriptionEvents(t *testing.T) {
	e := newEnv(t)
	tok := "dev:ios-events:apple.com"
	aat := appAccount(t, e, tok)
	active := subStatus(e, appstore.StatusActive, 1, "6000000002", "6000000001", "premium_monthly", aat, 30)
	e.apple.PutSubscription(active)
	if r := verifyApple(e, tok, "premium_monthly", "6000000002"); get(r.body, "premium", "status") != "active" {
		t.Fatalf("verify: %s", r.raw)
	}
	data := map[string]any{"bundleId": bundleID, "environment": "Sandbox", "signedTransactionInfo": e.appleCA.Sign(t, active.Transaction)}

	// The handler re-reads Apple: the notification only says "look again".
	e.apple.PutSubscription(subStatus(e, appstore.StatusExpired, 0, "6000000002", "6000000001", "premium_monthly", aat, -2))
	if r := notify(e, e.appleCA, notification("33333333-3333-4333-8333-333333333333", "EXPIRED", data)); r.status != 200 {
		t.Fatalf("expired: %d %s", r.status, r.raw)
	}
	if r := e.do(req{method: "GET", path: "/v1/billing/subscription", token: tok}); get(r.body, "premium", "status") != "expired" {
		t.Fatalf("after EXPIRED: %s", r.raw)
	}

	e.apple.PutSubscription(subStatus(e, appstore.StatusActive, 1, "6000000003", "6000000001", "premium_monthly", aat, 30))
	if r := notify(e, e.appleCA, notification("44444444-4444-4444-8444-444444444444", "DID_RENEW", data)); r.status != 200 {
		t.Fatalf("renew: %d", r.status)
	}
	if r := e.do(req{method: "GET", path: "/v1/billing/subscription", token: tok}); get(r.body, "premium", "status") != "active" {
		t.Fatalf("after DID_RENEW: %s", r.raw)
	}

	e.apple.PutSubscription(subStatus(e, appstore.StatusRevoked, 0, "6000000003", "6000000001", "premium_monthly", aat, 30))
	if r := notify(e, e.appleCA, notification("55555555-5555-4555-8555-555555555555", "REFUND", data)); r.status != 200 {
		t.Fatalf("refund: %d", r.status)
	}
	if r := e.do(req{method: "GET", path: "/v1/billing/subscription", token: tok}); get(r.body, "premium", "status") != "revoked" {
		t.Fatalf("after REFUND: %s", r.raw)
	}
	if !strings.Contains(e.logs.String(), `"premiumRevoked":true`) {
		t.Fatal("a refund that ends Premium must be logged as refund_applied")
	}

	// A subscription nobody verified waits for the app.
	unknown := subStatus(e, appstore.StatusActive, 1, "6100000002", "6100000001", "premium_monthly", aat, 30)
	data["signedTransactionInfo"] = e.appleCA.Sign(t, unknown.Transaction)
	if r := notify(e, e.appleCA, notification("66666666-6666-4666-8666-666666666666", "SUBSCRIBED", data)); r.status != 200 ||
		!strings.Contains(e.logs.String(), `"action":"awaiting_verify"`) {
		t.Fatalf("unknown subscription: %d", r.status)
	}
}

func TestAppStoreWebhookRejects(t *testing.T) {
	e := newEnv(t)
	n := notification("77777777-7777-4777-8777-777777777777", "TEST", map[string]any{"bundleId": bundleID, "environment": "Sandbox"})
	if r := notify(e, e.appleCA, n); r.status != 200 || !strings.Contains(e.logs.String(), `"kind":"test"`) {
		t.Fatalf("test notification: %d %s", r.status, r.raw)
	}
	if r := notify(e, appstoretest.NewCA(t), n); r.status != 400 || !strings.Contains(e.logs.String(), `"reason":"signature"`) {
		t.Fatalf("forged: %d %s", r.status, r.raw)
	}
	for _, body := range []string{`{}`, `not json`, `{"signedPayload":"a.b.c"}`} {
		if r := e.do(req{method: "POST", path: "/v1/webhooks/app-store", body: body}); r.status != 400 {
			t.Fatalf("%s: %d", body, r.status)
		}
	}
	other := notification("88888888-8888-4888-8888-888888888888", "DID_RENEW", map[string]any{"bundleId": "com.other.app", "environment": "Production"})
	if r := notify(e, e.appleCA, other); r.status != 200 || !strings.Contains(e.logs.String(), `"action":"other_bundle"`) {
		t.Fatalf("other bundle: %d", r.status)
	}
	summary := map[string]any{"notificationType": "RENEWAL_EXTENSION", "subtype": "SUMMARY",
		"notificationUUID": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa", "version": "2.0"}
	if r := notify(e, e.appleCA, summary); r.status != 200 || !strings.Contains(e.logs.String(), `"action":"no_data"`) {
		t.Fatalf("notification without data: %d", r.status)
	}
	if strings.Contains(e.logs.String(), `"level":"ERROR"`) {
		t.Fatalf("rejections must not log errors:\n%s", e.logs.String())
	}

	pinned := newEnv(t, func(c *config.Config) { c.AppStoreAppAppleID = 1234567890 })
	wrongApp := notification("99999999-9999-4999-8999-999999999999", "TEST",
		map[string]any{"bundleId": bundleID, "environment": "Production", "appAppleId": 42})
	if r := notify(pinned, pinned.appleCA, wrongApp); r.status != 200 || !strings.Contains(pinned.logs.String(), `"action":"other_app"`) {
		t.Fatalf("other appAppleId: %d", r.status)
	}

	off := newEnv(t, func(c *config.Config) { c.DevBilling, c.AppStoreBundleID = false, "" })
	if r := notify(off, off.appleCA, n); r.status != 404 {
		t.Fatalf("app store off: %d", r.status)
	}
	if r := verifyApple(off, "dev:ios-off:apple.com", "coin_pack_small", "1"); r.status != 503 {
		t.Fatalf("verify while off: %d", r.status)
	}
}
