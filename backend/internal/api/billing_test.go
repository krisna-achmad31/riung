package api_test

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"strings"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// billingAccount returns the user's id and obfuscated Play account id.
func billingAccount(t *testing.T, e *env, token string) (string, string) {
	t.Helper()
	me := e.do(req{method: "GET", path: "/v1/me", token: token})
	id, _ := get(me.body, "user", "id").(string)
	ba, _ := get(me.body, "user", "billingAccountId").(string)
	if id == "" || !strings.HasPrefix(ba, "ba_") {
		t.Fatalf("me: %s", me.raw)
	}
	return id, ba
}

func verify(e *env, token, productID, purchaseToken string) resp {
	return e.do(req{method: "POST", path: "/v1/billing/verify", token: token, idemKey: newKey(),
		body: map[string]string{"productId": productID, "purchaseToken": purchaseToken}})
}

func walletNum(r resp, field string) int {
	v, ok := get(r.body, "wallet", field).(float64)
	if !ok { // GET /v1/wallet answers the wallet itself
		v, _ = r.body[field].(float64)
	}
	return int(v)
}

func TestBillingVerifyCoinPack(t *testing.T) {
	e := newEnv(t)
	tok := "dev:buyer:google.com"
	_, ba := billingAccount(t, e, tok)
	e.play.PutProduct("tok-coins-medium-0001", billing.ProductPurchase{ProductID: "coin_pack_medium", OrderID: "GPA.1",
		PurchaseState: billing.ProductPurchased, Quantity: 1, ObfuscatedAccount: ba})

	// Anonymous accounts cannot buy (purchases must be restorable).
	if r := verify(e, anonToken, "coin_pack_medium", "tok-coins-medium-0001"); r.status != 403 || errCode(r) != "permanent_account_required" {
		t.Fatalf("anonymous: %d %s", r.status, r.raw)
	}

	r := verify(e, tok, "coin_pack_medium", "tok-coins-medium-0001")
	if r.status != 200 || get(r.body, "result", "status") != "credited" || get(r.body, "result", "coinsGranted") != 330.0 ||
		walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("verify: %d %s", r.status, r.raw)
	}
	// Verifying again (app retry, restore) never credits twice.
	r = verify(e, tok, "coin_pack_medium", "tok-coins-medium-0001")
	if r.status != 200 || get(r.body, "result", "status") != "already_credited" || walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("second verify: %d %s", r.status, r.raw)
	}
	// Another account cannot claim the same token.
	if r := verify(e, "dev:thief:google.com", "coin_pack_medium", "tok-coins-medium-0001"); r.status != 409 || errCode(r) != "purchase_invalid" {
		t.Fatalf("other account: %d %s", r.status, r.raw)
	}
	// Bought with another account id (e.g. a token copied from another user).
	e.play.PutProduct("tok-coins-small-other", billing.ProductPurchase{ProductID: "coin_pack_small",
		PurchaseState: billing.ProductPurchased, Quantity: 1, ObfuscatedAccount: "ba_someoneelse"})
	if r := verify(e, tok, "coin_pack_small", "tok-coins-small-other"); r.status != 409 || errCode(r) != "purchase_invalid" {
		t.Fatalf("account mismatch: %d %s", r.status, r.raw)
	}
	// Unknown to Play, wrong product, canceled.
	if r := verify(e, tok, "coin_pack_small", "tok-never-bought-1"); r.status != 409 {
		t.Fatalf("unknown token: %d %s", r.status, r.raw)
	}
	if r := verify(e, tok, "coin_pack_large", "tok-coins-medium-0001"); r.status != 409 {
		t.Fatalf("wrong product: %d %s", r.status, r.raw)
	}
	e.play.PutProduct("tok-coins-canceled", billing.ProductPurchase{ProductID: "coin_pack_small",
		PurchaseState: billing.ProductCanceled, Quantity: 1, ObfuscatedAccount: ba})
	if r := verify(e, tok, "coin_pack_small", "tok-coins-canceled"); r.status != 409 {
		t.Fatalf("canceled purchase: %d %s", r.status, r.raw)
	}
	// Pending (e.g. cash payment not completed yet): nothing granted.
	e.play.PutProduct("tok-coins-pending", billing.ProductPurchase{ProductID: "coin_pack_small",
		PurchaseState: billing.ProductPending, Quantity: 1, ObfuscatedAccount: ba})
	if r := verify(e, tok, "coin_pack_small", "tok-coins-pending"); r.status != 200 || get(r.body, "result", "status") != "pending" ||
		walletNum(r, "purchasedCoins") != 330 {
		t.Fatalf("pending: %d %s", r.status, r.raw)
	}
	if r := verify(e, tok, "gems_pack", "tok-coins-medium-0001"); r.status != 400 {
		t.Fatalf("unknown product: %d %s", r.status, r.raw)
	}
	if r := verify(e, tok, "coin_pack_small", "short"); r.status != 400 {
		t.Fatalf("invalid token: %d %s", r.status, r.raw)
	}

	logs := e.logs.String()
	if !strings.Contains(logs, `"event":"purchase_verified"`) || !strings.Contains(logs, `"event":"purchase_rejected"`) ||
		!strings.Contains(logs, `"tokenTail":"m-0001"`) || strings.Contains(logs, "tok-coins-medium-0001") {
		t.Fatalf("billing logs must carry only the token tail:\n%s", logs)
	}
}

func TestBillingRestore(t *testing.T) {
	e := newEnv(t)
	tok := "dev:restorer:google.com"
	_, ba := billingAccount(t, e, tok)
	e.play.PutProduct("tok-restore-small-1", billing.ProductPurchase{ProductID: "coin_pack_small",
		PurchaseState: billing.ProductPurchased, Quantity: 1, ObfuscatedAccount: ba})
	exp := e.clock.now().Add(20 * 24 * time.Hour).UTC()
	e.play.PutSubscription("tok-restore-sub-1", billing.SubscriptionPurchase{State: billing.SubActive, ProductID: "premium_monthly",
		ExpiresAt: &exp, AutoRenewing: true, ObfuscatedAccount: ba})

	body := map[string]any{"purchases": []map[string]string{
		{"productId": "coin_pack_small", "purchaseToken": "tok-restore-small-1"},
		{"productId": "premium_monthly", "purchaseToken": "tok-restore-sub-1"},
		{"productId": "coin_pack_small", "purchaseToken": "tok-restore-bogus"},
	}}
	r := e.do(req{method: "POST", path: "/v1/billing/restore", token: tok, idemKey: newKey(), body: body})
	if r.status != 200 || walletNum(r, "purchasedCoins") != 80 || get(r.body, "premium", "status") != "active" {
		t.Fatalf("restore: %d %s", r.status, r.raw)
	}
	results, _ := r.body["results"].([]any)
	if len(results) != 3 || results[0].(map[string]any)["ok"] != true || results[2].(map[string]any)["ok"] != false {
		t.Fatalf("restore results: %s", r.raw)
	}
	// Restoring again grants nothing new.
	r = e.do(req{method: "POST", path: "/v1/billing/restore", token: tok, idemKey: newKey(), body: body})
	if walletNum(r, "purchasedCoins") != 80 {
		t.Fatalf("second restore: %s", r.raw)
	}
	tooMany := make([]map[string]string, 21)
	for i := range tooMany {
		tooMany[i] = map[string]string{"productId": "coin_pack_small", "purchaseToken": "tok-restore-small-1"}
	}
	if r := e.do(req{method: "POST", path: "/v1/billing/restore", token: tok, idemKey: newKey(),
		body: map[string]any{"purchases": tooMany}}); r.status != 400 {
		t.Fatalf("21 items: %d", r.status)
	}
}

// push sends an RTDN notification through the webhook.
func push(e *env, bearer, messageID string, notification map[string]any) resp {
	raw, _ := json.Marshal(notification)
	return e.do(req{method: "POST", path: "/v1/webhooks/google-play", token: bearer, body: map[string]any{
		"message":      map[string]any{"data": base64.StdEncoding.EncodeToString(raw), "messageId": messageID, "publishTime": "2026-10-12T00:00:00Z"},
		"subscription": "projects/riung-5e979/subscriptions/play-rtdn",
	}})
}

func subNotification(token string, typ int) map[string]any {
	return map[string]any{"version": "1.0", "packageName": "com.riung.riung", "eventTimeMillis": "1760000000000",
		"subscriptionNotification": map[string]any{"version": "1.0", "notificationType": typ, "purchaseToken": token}}
}

func premium(t *testing.T, e *env, tok string) map[string]any {
	t.Helper()
	r := e.do(req{method: "GET", path: "/v1/billing/subscription", token: tok})
	if r.status != 200 {
		t.Fatalf("subscription: %d %s", r.status, r.raw)
	}
	p, _ := r.body["premium"].(map[string]any)
	return p
}

func TestBillingSubscriptionLifecycle(t *testing.T) {
	e := newEnv(t)
	tok := "dev:subscriber:google.com"
	_, ba := billingAccount(t, e, tok)
	if p := premium(t, e, tok); p["status"] != "none" {
		t.Fatalf("no subscription yet: %v", p)
	}

	monthEnd := e.clock.now().Add(30 * 24 * time.Hour).UTC().Truncate(time.Second)
	e.play.PutSubscription("tok-sub-monthly-1", billing.SubscriptionPurchase{State: billing.SubActive, ProductID: "premium_monthly",
		ExpiresAt: &monthEnd, AutoRenewing: true, ObfuscatedAccount: ba})
	r := verify(e, tok, "premium_monthly", "tok-sub-monthly-1")
	if r.status != 200 || get(r.body, "result", "status") != "active" || get(r.body, "premium", "status") != "active" {
		t.Fatalf("verify subscription: %d %s", r.status, r.raw)
	}

	// Upgrade to yearly from the Play Store: the new token links the old one
	// and arrives by RTDN before the app calls verify.
	yearEnd := e.clock.now().Add(365 * 24 * time.Hour).UTC().Truncate(time.Second)
	e.play.PutSubscription("tok-sub-yearly-2", billing.SubscriptionPurchase{State: billing.SubActive, ProductID: "premium_yearly",
		ExpiresAt: &yearEnd, AutoRenewing: true, ObfuscatedAccount: ba, LinkedToken: "tok-sub-monthly-1"})
	if r := push(e, "dev-pubsub", "msg-1", subNotification("tok-sub-yearly-2", 4)); r.status != 204 {
		t.Fatalf("rtdn upgrade: %d %s", r.status, r.raw)
	}
	if p := premium(t, e, tok); p["plan"] != "premium_yearly" || p["status"] != "active" {
		t.Fatalf("after upgrade: %v", p)
	}
	// The old token expiring later must not take Premium away.
	e.play.PutSubscription("tok-sub-monthly-1", billing.SubscriptionPurchase{State: billing.SubExpired, ProductID: "premium_monthly",
		ExpiresAt: &monthEnd, ObfuscatedAccount: ba})
	push(e, "dev-pubsub", "msg-2", subNotification("tok-sub-monthly-1", 13))
	if r := verify(e, tok, "premium_monthly", "tok-sub-monthly-1"); r.status != 200 {
		t.Fatalf("old token verify: %d %s", r.status, r.raw)
	}
	if p := premium(t, e, tok); p["plan"] != "premium_yearly" || p["status"] != "active" {
		t.Fatalf("superseded token overwrote premium: %v", p)
	}

	// Turning auto-renew off keeps Premium until the paid period ends.
	e.play.PutSubscription("tok-sub-yearly-2", billing.SubscriptionPurchase{State: billing.SubCanceled, ProductID: "premium_yearly",
		ExpiresAt: &yearEnd, ObfuscatedAccount: ba, LinkedToken: "tok-sub-monthly-1"})
	push(e, "dev-pubsub", "msg-3", subNotification("tok-sub-yearly-2", 3))
	if p := premium(t, e, tok); p["status"] != "active" || p["autoRenewing"] != false {
		t.Fatalf("canceled but paid: %v", p)
	}
	e.clock.advance(366 * 24 * time.Hour)
	if p := premium(t, e, tok); p["status"] == "active" || p["status"] == "in_grace" {
		t.Fatalf("after expiry: %v", p)
	}

	// Duplicate Pub/Sub deliveries are processed once.
	before := strings.Count(e.logs.String(), `"event":"rtdn_received"`)
	push(e, "dev-pubsub", "msg-3", subNotification("tok-sub-yearly-2", 3))
	if after := strings.Count(e.logs.String(), `"event":"rtdn_received"`); after != before {
		t.Fatal("duplicate message must not be processed again")
	}
}

func TestBillingWebhookRejectsBadPushes(t *testing.T) {
	e := newEnv(t)
	if r := push(e, "", "msg-x", subNotification("tok-x-000000", 4)); r.status != 401 {
		t.Fatalf("no token: %d", r.status)
	}
	if r := push(e, "forged", "msg-x", subNotification("tok-x-000000", 4)); r.status != 401 {
		t.Fatalf("bad token: %d", r.status)
	}
	// Undecodable messages are acknowledged (204) so Pub/Sub stops retrying.
	if r := e.do(req{method: "POST", path: "/v1/webhooks/google-play", token: "dev-pubsub", body: `{"message":{"data":"%%%","messageId":"m"}}`}); r.status != 204 {
		t.Fatalf("garbage: %d", r.status)
	}
	other := subNotification("tok-x-000000", 4)
	other["packageName"] = "com.example.other"
	if r := push(e, "dev-pubsub", "msg-other", other); r.status != 204 || !strings.Contains(e.logs.String(), `"action":"other_package"`) {
		t.Fatalf("other package: %d", r.status)
	}
	test := map[string]any{"packageName": "com.riung.riung", "testNotification": map[string]any{"version": "1.0"}}
	if r := push(e, "dev-pubsub", "msg-test", test); r.status != 204 {
		t.Fatalf("test notification: %d", r.status)
	}
	// Notifications for tokens nobody verified yet wait for /billing/verify.
	if r := push(e, "dev-pubsub", "msg-unknown", subNotification("tok-not-in-play", 4)); r.status != 204 {
		t.Fatalf("unknown token: %d", r.status)
	}
}

func TestBillingRefundClawsBackAndRecordsDebt(t *testing.T) {
	e := newEnv(t)
	tok := "dev:refunder:google.com"
	userID, ba := billingAccount(t, e, tok)
	e.play.PutProduct("tok-refund-small-1", billing.ProductPurchase{ProductID: "coin_pack_small",
		PurchaseState: billing.ProductPurchased, Quantity: 1, ObfuscatedAccount: ba})
	if r := verify(e, tok, "coin_pack_small", "tok-refund-small-1"); walletNum(r, "purchasedCoins") != 80 {
		t.Fatalf("verify: %s", r.raw)
	}
	// Earn 20, then spend 70 (purchased coins first): 10 purchased + 20 earned left.
	seed(t, e, userID, 20)
	err := e.store.WithUserTx(context.Background(), userID, func(tx *store.UserTx) error {
		return tx.Debit(store.Debit{Amount: 70, Reason: "test", Key: "spend-" + newKey()})
	})
	if err != nil {
		t.Fatal(err)
	}

	// Refund by RTDN: 30 coins remain to take back, 50 become debt.
	voided := map[string]any{"packageName": "com.riung.riung", "eventTimeMillis": "1760000000000",
		"voidedPurchaseNotification": map[string]any{"purchaseToken": "tok-refund-small-1", "orderId": "GPA.9", "productType": 2, "refundType": 1}}
	if r := push(e, "dev-pubsub", "msg-void-1", voided); r.status != 204 {
		t.Fatalf("voided rtdn: %d %s", r.status, r.raw)
	}
	w := e.do(req{method: "GET", path: "/v1/wallet", token: tok})
	if walletNum(w, "coins") != 0 || walletNum(w, "debtCoins") != 50 {
		t.Fatalf("after refund: %s", w.raw)
	}
	if !strings.Contains(e.logs.String(), `"event":"refund_applied"`) {
		t.Fatal("refund must be logged")
	}
	// The daily sync sees the same refund: nothing happens twice.
	e.play.Void(billing.VoidedPurchase{Token: "tok-refund-small-1", VoidedAt: e.clock.now().UTC(), Quantity: 1})
	res, err := e.billing.Sync(context.Background())
	if err != nil || len(res.Refunded) != 0 {
		t.Fatalf("sync: %+v %v", res, err)
	}
	// A refunded token cannot be verified again.
	if r := verify(e, tok, "coin_pack_small", "tok-refund-small-1"); r.status != 409 {
		t.Fatalf("verify after refund: %d %s", r.status, r.raw)
	}
	// Debt is repaid from the next earnings.
	seed(t, e, userID, 30)
	w = e.do(req{method: "GET", path: "/v1/wallet", token: tok})
	if walletNum(w, "coins") != 0 || walletNum(w, "debtCoins") != 20 {
		t.Fatalf("debt repayment: %s", w.raw)
	}
	bad, _, err := e.store.Reconcile(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	for _, m := range bad {
		if m.UserID == userID {
			t.Fatalf("wallet does not match ledger: %+v", m)
		}
	}
}

func TestBillingSyncRefundsSubscriptionAndAcknowledges(t *testing.T) {
	e := newEnv(t)
	tok := "dev:syncer:google.com"
	_, ba := billingAccount(t, e, tok)
	end := e.clock.now().Add(30 * 24 * time.Hour).UTC()
	e.play.PutSubscription("tok-sync-sub-1", billing.SubscriptionPurchase{State: billing.SubActive, ProductID: "premium_monthly",
		ExpiresAt: &end, AutoRenewing: true, ObfuscatedAccount: ba})
	e.play.PutProduct("tok-sync-coins-1", billing.ProductPurchase{ProductID: "coin_pack_large",
		PurchaseState: billing.ProductPurchased, Quantity: 1, ObfuscatedAccount: ba})
	verify(e, tok, "premium_monthly", "tok-sync-sub-1")
	if r := verify(e, tok, "coin_pack_large", "tok-sync-coins-1"); walletNum(r, "purchasedCoins") != 820 {
		t.Fatalf("large pack: %s", r.raw)
	}

	// The app never acknowledged either purchase: sync does it (no consume).
	res, err := e.billing.Sync(context.Background())
	if err != nil || res.Acknowledged != 2 {
		t.Fatalf("acknowledge: %+v %v", res, err)
	}
	if acked := e.play.Acked(); len(acked) != 2 {
		t.Fatalf("acked at Play: %v", acked)
	}
	if res, _ := e.billing.Sync(context.Background()); res.Acknowledged != 0 {
		t.Fatalf("acknowledged twice: %+v", res)
	}

	// Refund + revoke of the subscription: Play reports it expired.
	e.play.PutSubscription("tok-sync-sub-1", billing.SubscriptionPurchase{State: billing.SubExpired, ProductID: "premium_monthly",
		ExpiresAt: &end, ObfuscatedAccount: ba, Acknowledged: true})
	e.play.Void(billing.VoidedPurchase{Token: "tok-sync-sub-1", VoidedAt: e.clock.now().UTC(), Quantity: 1})
	res, err = e.billing.Sync(context.Background())
	if err != nil || len(res.Refunded) != 1 || !res.Refunded[0].Revoked {
		t.Fatalf("subscription refund: %+v %v", res, err)
	}
	if p := premium(t, e, tok); p["status"] == "active" {
		t.Fatalf("premium must end after revoke: %v", p)
	}
	if res, _ := e.billing.Sync(context.Background()); len(res.Refunded) != 0 {
		t.Fatalf("refund reported twice: %+v", res)
	}
}

func TestBillingUnavailableWithoutPublisher(t *testing.T) {
	e := newEnv(t, func(c *config.Config) { c.DevBilling = false })
	if r := verify(e, "dev:nopub:google.com", "coin_pack_small", "tok-nopub-00001"); r.status != 503 {
		t.Fatalf("no publisher: %d %s", r.status, r.raw)
	}
}
