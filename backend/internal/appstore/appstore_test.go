package appstore_test

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"encoding/pem"
	"errors"
	"math/big"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/appstore"
	"github.com/krisna-achmad31/riung/backend/internal/appstore/appstoretest"
)

var signedAt = time.Date(2026, 10, 19, 8, 0, 0, 0, time.UTC).UnixMilli()

func sampleTxn() appstore.Transaction {
	return appstore.Transaction{TransactionID: "2000000123", OriginalTransactionID: "2000000123", BundleID: "id.riung.riung",
		ProductID: "coin_pack_small", Type: appstore.TypeConsumable, Quantity: 1, Environment: appstore.EnvSandbox,
		AppAccountToken: "6F9619FF-8B86-D011-B42D-00C04FC964FF", SignedDate: signedAt}
}

func TestAppleRootIsPinned(t *testing.T) {
	der, err := os.ReadFile("AppleRootCA-G3.cer")
	if err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256(der)
	if got := hex.EncodeToString(sum[:]); got != "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179" {
		t.Fatalf("Apple Root CA - G3 fingerprint changed: %s", got)
	}
	_ = appstore.NewAppleVerifier() // panics if the embedded root does not parse
}

func TestDecodeAcceptsAppleShapedJWS(t *testing.T) {
	ca := appstoretest.NewCA(t)
	var got appstore.Transaction
	if err := ca.Verifier(t).Decode(ca.Sign(t, sampleTxn()), &got); err != nil {
		t.Fatal(err)
	}
	if got.TransactionID != "2000000123" || got.AccountToken() != "6f9619ff-8b86-d011-b42d-00c04fc964ff" || !got.Test() {
		t.Fatalf("decoded %+v", got)
	}

	// Chains are checked at signedDate (as Apple's library does): an old
	// transaction stays valid after its signing certificate expired.
	old := appstoretest.NewCAWith(t, appstoretest.CertOptions{
		NotBefore: time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC), NotAfter: time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)})
	txn := sampleTxn()
	txn.SignedDate = time.Date(2024, 6, 1, 0, 0, 0, 0, time.UTC).UnixMilli()
	if err := old.Verifier(t).Decode(old.Sign(t, txn), &got); err != nil {
		t.Fatalf("signed while the certificate was valid: %v", err)
	}
}

func TestDecodeRejects(t *testing.T) {
	ca := appstoretest.NewCA(t)
	good := ca.Sign(t, sampleTxn())
	parts := strings.Split(good, ".")
	other := appstoretest.NewCA(t)

	tampered := sampleTxn()
	tampered.ProductID = "coin_pack_large"
	tamperedBody := base64.RawURLEncoding.EncodeToString(mustJSON(t, tampered))

	noneHeader := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"none"}`))
	expired := appstoretest.NewCAWith(t, appstoretest.CertOptions{
		NotBefore: time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC), NotAfter: time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)})

	cases := map[string]struct {
		jws      string
		verifier *appstore.Verifier
	}{
		"payload changed after signing": {parts[0] + "." + tamperedBody + "." + parts[2], ca.Verifier(t)},
		"signed by another root":        {other.Sign(t, sampleTxn()), ca.Verifier(t)},
		"real Apple root, test chain":   {good, appstore.NewAppleVerifier()},
		"alg none":                      {noneHeader + "." + parts[1] + ".", ca.Verifier(t)},
		"not a JWS":                     {"abc", ca.Verifier(t)},
		"no leaf marker":                {appstoretest.NewCAWith(t, appstoretest.CertOptions{NoLeafMarker: true}).Sign(t, sampleTxn()), nil},
		"no intermediate marker":        {appstoretest.NewCAWith(t, appstoretest.CertOptions{NoIntermediateMarker: true}).Sign(t, sampleTxn()), nil},
		"leaf expired at signedDate":    {expired.Sign(t, sampleTxn()), expired.Verifier(t)},
	}
	for name, c := range cases {
		v := c.verifier
		if v == nil {
			v = verifierFor(t, c.jws)
		}
		var out appstore.Transaction
		if err := v.Decode(c.jws, &out); !errors.Is(err, appstore.ErrInvalidSignature) {
			t.Errorf("%s: want ErrInvalidSignature, got %v", name, err)
		}
	}
}

// verifierFor trusts the root inside a JWS (to test the marker checks alone).
func verifierFor(t *testing.T, jws string) *appstore.Verifier {
	hdrRaw, _ := base64.RawURLEncoding.DecodeString(strings.Split(jws, ".")[0])
	var hdr struct {
		X5C []string `json:"x5c"`
	}
	_ = json.Unmarshal(hdrRaw, &hdr)
	root, _ := base64.StdEncoding.DecodeString(hdr.X5C[2])
	v, err := appstore.NewVerifier(root)
	if err != nil {
		t.Fatal(err)
	}
	return v
}

func mustJSON(t *testing.T, v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// --- App Store Server API client -------------------------------------------------------

func testKey(t *testing.T) (*ecdsa.PrivateKey, []byte) {
	k, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	der, err := x509.MarshalPKCS8PrivateKey(k)
	if err != nil {
		t.Fatal(err)
	}
	return k, pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: der})
}

// checkAuth verifies the bearer JWT the client sends.
func checkAuth(t *testing.T, r *http.Request, pub *ecdsa.PublicKey) {
	t.Helper()
	tok := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	parts := strings.Split(tok, ".")
	if len(parts) != 3 {
		t.Errorf("auth header %q", r.Header.Get("Authorization"))
		return
	}
	var hdr map[string]string
	var claims map[string]any
	h, _ := base64.RawURLEncoding.DecodeString(parts[0])
	c, _ := base64.RawURLEncoding.DecodeString(parts[1])
	_ = json.Unmarshal(h, &hdr)
	_ = json.Unmarshal(c, &claims)
	if hdr["alg"] != "ES256" || hdr["kid"] != "KEY123" || claims["iss"] != "issuer-uuid" ||
		claims["aud"] != "appstoreconnect-v1" || claims["bid"] != "id.riung.riung" {
		t.Errorf("jwt header %v claims %v", hdr, claims)
	}
	if exp, iat := claims["exp"].(float64), claims["iat"].(float64); exp-iat > 3600 || exp <= iat {
		t.Errorf("jwt lifetime iat=%v exp=%v", iat, exp)
	}
	sig, _ := base64.RawURLEncoding.DecodeString(parts[2])
	digest := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if len(sig) != 64 || !ecdsa.Verify(pub, digest[:], new(big.Int).SetBytes(sig[:32]), new(big.Int).SetBytes(sig[32:])) {
		t.Error("jwt signature does not verify")
	}
}

func newClient(t *testing.T, ca *appstoretest.CA, prod, sandbox http.Handler) *appstore.Client {
	key, pemKey := testKey(t)
	wrap := func(h http.Handler) *httptest.Server {
		s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			checkAuth(t, r, &key.PublicKey)
			h.ServeHTTP(w, r)
		}))
		t.Cleanup(s.Close)
		return s
	}
	c, err := appstore.NewClient(appstore.ClientOptions{BundleID: "id.riung.riung", IssuerID: "issuer-uuid", KeyID: "KEY123",
		PrivateKeyPEM: pemKey, Verifier: ca.Verifier(t), ProductionURL: wrap(prod).URL, SandboxURL: wrap(sandbox).URL})
	if err != nil {
		t.Fatal(err)
	}
	return c
}

func status(code int, body string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(code)
		_, _ = w.Write([]byte(body))
	})
}

func TestClientFallsBackToSandbox(t *testing.T) {
	ca := appstoretest.NewCA(t)
	var sandboxHits atomic.Int32
	sandbox := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sandboxHits.Add(1)
		if r.URL.Path != "/inApps/v1/transactions/2000000123" {
			t.Errorf("path %s", r.URL.Path)
		}
		_ = json.NewEncoder(w).Encode(map[string]string{"signedTransactionInfo": ca.Sign(t, sampleTxn())})
	})
	c := newClient(t, ca, status(404, `{"errorCode":4040010}`), sandbox)
	got, err := c.Transaction(context.Background(), "2000000123")
	if err != nil || got.ProductID != "coin_pack_small" || sandboxHits.Load() != 1 {
		t.Fatalf("got %+v err %v sandbox hits %d", got, err, sandboxHits.Load())
	}
}

func TestClientErrors(t *testing.T) {
	ca := appstoretest.NewCA(t)
	otherBundle := sampleTxn()
	otherBundle.BundleID = "com.other.app"
	signedOther := ca.Sign(t, otherBundle)
	cases := map[string]struct {
		prod, sandbox http.Handler
		want          error
	}{
		"unknown everywhere":   {status(404, `{}`), status(404, `{}`), appstore.ErrNotFound},
		"invalid id":           {status(400, `{"errorCode":4000006}`), status(400, `{"errorCode":4000006}`), appstore.ErrNotFound},
		"key rejected":         {status(401, ``), status(404, `{}`), appstore.ErrAuth},
		"apple down":           {status(503, ``), status(404, `{}`), appstore.ErrUnavailable},
		"rate limited":         {status(429, ``), status(404, `{}`), appstore.ErrUnavailable},
		"another app's bundle": {status(200, `{"signedTransactionInfo":"`+signedOther+`"}`), status(404, `{}`), appstore.ErrNotFound},
		"forged signature":     {status(200, `{"signedTransactionInfo":"`+appstoretest.NewCA(t).Sign(t, sampleTxn())+`"}`), status(404, `{}`), appstore.ErrInvalidSignature},
	}
	for name, c := range cases {
		_, err := newClient(t, ca, c.prod, c.sandbox).Transaction(context.Background(), "2000000123")
		if !errors.Is(err, c.want) {
			t.Errorf("%s: want %v, got %v", name, c.want, err)
		}
	}
}

func TestClientSubscription(t *testing.T) {
	ca := appstoretest.NewCA(t)
	txn := sampleTxn()
	txn.TransactionID, txn.OriginalTransactionID = "2000000200", "2000000100"
	txn.ProductID, txn.Type = "premium_yearly", appstore.TypeAutoRenewing
	txn.ExpiresDate = time.Date(2027, 10, 19, 0, 0, 0, 0, time.UTC).UnixMilli()
	renewal := appstore.RenewalInfo{OriginalTransactionID: "2000000100", AutoRenewStatus: 1, SignedDate: signedAt}
	other := sampleTxn()
	prod := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/inApps/v1/subscriptions/2000000100" {
			t.Errorf("path %s", r.URL.Path)
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"data": []any{map[string]any{"lastTransactions": []any{
			map[string]any{"originalTransactionId": "1999", "status": 2, "signedTransactionInfo": ca.Sign(t, other)},
			map[string]any{"originalTransactionId": "2000000100", "status": 1,
				"signedTransactionInfo": ca.Sign(t, txn), "signedRenewalInfo": ca.Sign(t, renewal)},
		}}}})
	})
	st, err := newClient(t, ca, prod, status(404, `{}`)).Subscription(context.Background(), "2000000100")
	if err != nil || st.Status != appstore.StatusActive || st.Transaction.ProductID != "premium_yearly" ||
		st.Renewal.AutoRenewStatus != 1 || !st.Transaction.Expires().Equal(time.Date(2027, 10, 19, 0, 0, 0, 0, time.UTC)) {
		t.Fatalf("got %+v err %v", st, err)
	}
}

func TestNewClientRejectsBadKeys(t *testing.T) {
	_, rsaLike := testKey(t)
	for name, pemKey := range map[string][]byte{"empty": nil, "not pem": []byte("nope")} {
		if _, err := appstore.NewClient(appstore.ClientOptions{BundleID: "b", IssuerID: "i", KeyID: "k", PrivateKeyPEM: pemKey}); err == nil {
			t.Errorf("%s: want error", name)
		}
	}
	if _, err := appstore.NewClient(appstore.ClientOptions{BundleID: "b", IssuerID: "i", PrivateKeyPEM: rsaLike}); err == nil {
		t.Error("missing key id must fail")
	}
}

func TestFakeDevIDs(t *testing.T) {
	f := appstore.NewFake("id.riung.riung")
	tok := "6f9619ff-8b86-8011-b42d-00c04fc964ff"
	coin, err := f.Transaction(context.Background(), "dev-coin:"+tok+":coin_pack_small:1")
	if err != nil || coin.Type != appstore.TypeConsumable || coin.AccountToken() != tok || coin.ProductID != "coin_pack_small" {
		t.Fatalf("coin %+v %v", coin, err)
	}
	id := "dev-sub:" + tok + ":premium_monthly:30:1"
	sub, err := f.Subscription(context.Background(), id)
	if err != nil || sub.Status != appstore.StatusActive || sub.Transaction.OriginalTransactionID != id {
		t.Fatalf("sub %+v %v", sub, err)
	}
	if _, err := f.Transaction(context.Background(), "123"); !errors.Is(err, appstore.ErrNotFound) {
		t.Fatalf("unknown id: %v", err)
	}
}
