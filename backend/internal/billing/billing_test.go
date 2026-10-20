package billing

import (
	"context"
	"encoding/base64"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"google.golang.org/api/option"
)

func TestAccountIDIsStableAndKeyed(t *testing.T) {
	a := AccountID([]byte("key-one"), "user-1")
	if a != AccountID([]byte("key-one"), "user-1") || !strings.HasPrefix(a, "ba_") || len(a) != 35 {
		t.Fatalf("account id: %q", a)
	}
	if a == AccountID([]byte("key-two"), "user-1") || a == AccountID([]byte("key-one"), "user-2") {
		t.Fatal("account id must depend on key and user")
	}
}

func TestLedgerKeyFitsColumn(t *testing.T) {
	k := ledgerKey("purchase", strings.Repeat("x", 600))
	if len(k) > 160 || k != ledgerKey("purchase", strings.Repeat("x", 600)) {
		t.Fatalf("ledger key: %q", k)
	}
}

func TestDecodePush(t *testing.T) {
	data := base64.StdEncoding.EncodeToString([]byte(`{"packageName":"id.riung.riung",
		"subscriptionNotification":{"notificationType":2,"purchaseToken":"abc","subscriptionId":"premium_yearly"}}`))
	var env PushEnvelope
	env.Message.Data, env.Message.MessageID = data, "123"
	n, err := DecodePush(env)
	if err != nil || n.SubscriptionNotification == nil || n.SubscriptionNotification.NotificationType != 2 {
		t.Fatalf("decode: %+v %v", n, err)
	}
	env.Message.MessageID = ""
	if _, err := DecodePush(env); err == nil {
		t.Fatal("message id is required")
	}
	env.Message.MessageID, env.Message.Data = "1", "not base64!"
	if _, err := DecodePush(env); err == nil {
		t.Fatal("bad base64 must fail")
	}
}

func TestGooglePushVerifierNeedsConfiguration(t *testing.T) {
	ctx := context.Background()
	for _, v := range []GooglePushVerifier{{}, {Audience: "https://x"}, {ServiceAccount: "a@b"}} {
		if err := v.Verify(ctx, "token"); !errors.Is(err, ErrBadPush) {
			t.Fatalf("%+v must refuse: %v", v, err)
		}
	}
	v := GooglePushVerifier{Audience: "https://riung.e55techlab.com/v1/webhooks/google-play", ServiceAccount: "rtdn@x.iam.gserviceaccount.com"}
	if err := v.Verify(ctx, ""); !errors.Is(err, ErrBadPush) {
		t.Fatal("empty bearer must be refused")
	}
	if err := v.Verify(ctx, "not.a.jwt"); !errors.Is(err, ErrBadPush) {
		t.Fatal("garbage bearer must be refused")
	}
}

func TestFakePublisherDevTokens(t *testing.T) {
	f := NewFakePublisher()
	ctx := context.Background()
	p, err := f.GetProduct(ctx, "coin_pack_small", "dev-coin:ba_x:coin_pack_small:1")
	if err != nil || p.ObfuscatedAccount != "ba_x" || p.PurchaseState != ProductPurchased {
		t.Fatalf("dev coin: %+v %v", p, err)
	}
	if _, err := f.GetProduct(ctx, "coin_pack_large", "dev-coin:ba_x:coin_pack_small:1"); !errors.Is(err, ErrPurchaseNotFound) {
		t.Fatal("product id must match the token")
	}
	s, err := f.GetSubscription(ctx, "dev-sub:ba_x:premium_monthly:30:1")
	if err != nil || s.State != SubActive || s.ExpiresAt == nil || s.ProductID != "premium_monthly" {
		t.Fatalf("dev sub: %+v %v", s, err)
	}
	if _, err := f.GetSubscription(ctx, "dev-sub:ba_x:premium_monthly:9999:1"); !errors.Is(err, ErrPurchaseNotFound) {
		t.Fatal("absurd durations are refused")
	}
}

// playStub serves the Android Publisher endpoints the client calls.
func playStub(t *testing.T, routes map[string]func(w http.ResponseWriter)) *GooglePublisher {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		for suffix, h := range routes {
			if strings.HasSuffix(r.URL.Path, suffix) {
				w.Header().Set("Content-Type", "application/json")
				h(w)
				return
			}
		}
		http.NotFound(w, r)
	}))
	t.Cleanup(srv.Close)
	g, err := newGooglePublisher(context.Background(), "id.riung.riung", option.WithEndpoint(srv.URL), option.WithoutAuthentication())
	if err != nil {
		t.Fatal(err)
	}
	return g
}

func TestGooglePublisherParsesPlayResponses(t *testing.T) {
	g := playStub(t, map[string]func(http.ResponseWriter){
		"/products/coin_pack_medium/tokens/tok-1": func(w http.ResponseWriter) {
			_, _ = w.Write([]byte(`{"purchaseState":0,"acknowledgementState":1,"consumptionState":0,"orderId":"GPA.1",
				"obfuscatedExternalAccountId":"ba_abc","purchaseType":0}`))
		},
		"/subscriptionsv2/tokens/tok-2": func(w http.ResponseWriter) {
			_, _ = w.Write([]byte(`{"subscriptionState":"SUBSCRIPTION_STATE_CANCELED","linkedPurchaseToken":"tok-0",
				"acknowledgementState":"ACKNOWLEDGEMENT_STATE_PENDING","latestOrderId":"GPA.2",
				"externalAccountIdentifiers":{"obfuscatedExternalAccountId":"ba_abc"},
				"lineItems":[{"productId":"premium_yearly","expiryTime":"2027-10-12T03:04:05.678Z","autoRenewingPlan":{"autoRenewEnabled":false}}]}`))
		},
		"/products/coin_pack_small/tokens/gone": func(w http.ResponseWriter) {
			w.WriteHeader(http.StatusGone)
			_, _ = w.Write([]byte(`{"error":{"code":410,"message":"gone"}}`))
		},
		"/subscriptionsv2/tokens/boom": func(w http.ResponseWriter) {
			w.WriteHeader(http.StatusInternalServerError)
			_, _ = w.Write([]byte(`{"error":{"code":500,"message":"boom"}}`))
		},
		"/voidedpurchases": func(w http.ResponseWriter) {
			_, _ = w.Write([]byte(`{"voidedPurchases":[{"purchaseToken":"tok-1","orderId":"GPA.1","voidedTimeMillis":"1760000000000"}]}`))
		},
	})
	ctx := context.Background()
	p, err := g.GetProduct(ctx, "coin_pack_medium", "tok-1")
	if err != nil || !p.Acknowledged || p.Consumed || p.ObfuscatedAccount != "ba_abc" || !p.Test || p.Quantity != 1 {
		t.Fatalf("product: %+v %v", p, err)
	}
	s, err := g.GetSubscription(ctx, "tok-2")
	want := time.Date(2027, 10, 12, 3, 4, 5, 678e6, time.UTC)
	if err != nil || s.State != SubCanceled || s.ProductID != "premium_yearly" || s.ExpiresAt == nil || !s.ExpiresAt.Equal(want) ||
		s.AutoRenewing || s.Acknowledged || s.LinkedToken != "tok-0" || s.ObfuscatedAccount != "ba_abc" {
		t.Fatalf("subscription: %+v %v", s, err)
	}
	if _, err := g.GetProduct(ctx, "coin_pack_small", "gone"); !errors.Is(err, ErrPurchaseNotFound) {
		t.Fatalf("410 must be not found: %v", err)
	}
	if _, err := g.GetSubscription(ctx, "boom"); !errors.Is(err, ErrPlayUnavailable) {
		t.Fatalf("500 must be unavailable: %v", err)
	}
	v, err := g.ListVoided(ctx, time.Now().Add(-time.Hour))
	if err != nil || len(v) != 1 || v[0].Token != "tok-1" || v[0].Quantity != 1 || v[0].VoidedAt.UnixMilli() != 1760000000000 {
		t.Fatalf("voided: %+v %v", v, err)
	}
}
