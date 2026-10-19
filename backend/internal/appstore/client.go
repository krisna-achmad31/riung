package appstore

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

// Errors from the App Store Server API.
var (
	// ErrNotFound: neither production nor sandbox knows the id for our app.
	ErrNotFound = errors.New("app store: transaction not found")
	// ErrUnavailable: network error, 429 or 5xx — retry later.
	ErrUnavailable = errors.New("app store: unavailable")
	// ErrAuth: Apple rejected our API key (configuration problem).
	ErrAuth = errors.New("app store: API key rejected")
)

// API is what billing needs from Apple. Client (App Store Server API) and
// Fake (dev stack, tests) implement it.
type API interface {
	// Transaction returns one verified transaction.
	Transaction(ctx context.Context, transactionID string) (Transaction, error)
	// Subscription returns the current state of a subscription.
	Subscription(ctx context.Context, originalTransactionID string) (SubscriptionStatus, error)
}

// App Store Server API hosts.
const (
	ProductionURL = "https://api.storekit.itunes.apple.com"
	SandboxURL    = "https://api.storekit-sandbox.itunes.apple.com"
)

// ClientOptions configures Client. The key is an In-App Purchase key from
// App Store Connect (Users and Access → Integrations).
type ClientOptions struct {
	BundleID      string
	IssuerID      string
	KeyID         string
	PrivateKeyPEM []byte // the .p8 file: PKCS#8 EC P-256
	Verifier      *Verifier
	HTTP          *http.Client
	Now           func() time.Time
	// ProductionURL / SandboxURL override the hosts (tests).
	ProductionURL string
	SandboxURL    string
}

// Client calls the App Store Server API. Every answer is a JWS verified with
// Verifier and checked against BundleID.
type Client struct {
	opts ClientOptions
	key  *ecdsa.PrivateKey
}

// NewClient parses the key and fills defaults.
func NewClient(o ClientOptions) (*Client, error) {
	if o.BundleID == "" || o.IssuerID == "" || o.KeyID == "" {
		return nil, errors.New("app store: bundle id, issuer id and key id are required")
	}
	block, _ := pem.Decode(o.PrivateKeyPEM)
	if block == nil {
		return nil, errors.New("app store: private key is not PEM")
	}
	k, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("app store: private key: %w", err)
	}
	key, ok := k.(*ecdsa.PrivateKey)
	if !ok || key.Curve != elliptic.P256() {
		return nil, errors.New("app store: private key must be EC P-256")
	}
	if o.Verifier == nil {
		o.Verifier = NewAppleVerifier()
	}
	if o.HTTP == nil {
		// 5 s per call (as for Google Play): production + sandbox stay inside
		// the server's 15 s write timeout.
		o.HTTP = &http.Client{Timeout: 5 * time.Second}
	}
	if o.Now == nil {
		o.Now = time.Now
	}
	if o.ProductionURL == "" {
		o.ProductionURL = ProductionURL
	}
	if o.SandboxURL == "" {
		o.SandboxURL = SandboxURL
	}
	return &Client{opts: o, key: key}, nil
}

// Transaction implements API (GET /inApps/v1/transactions/{transactionId}).
func (c *Client) Transaction(ctx context.Context, transactionID string) (Transaction, error) {
	var r struct {
		SignedTransactionInfo string `json:"signedTransactionInfo"`
	}
	if err := c.get(ctx, "/inApps/v1/transactions/"+url.PathEscape(transactionID), &r); err != nil {
		return Transaction{}, err
	}
	var t Transaction
	if err := c.opts.Verifier.Decode(r.SignedTransactionInfo, &t); err != nil {
		return Transaction{}, err
	}
	if t.BundleID != c.opts.BundleID || t.TransactionID != transactionID {
		return Transaction{}, ErrNotFound
	}
	return t, nil
}

// Subscription implements API (GET /inApps/v1/subscriptions/{transactionId}).
func (c *Client) Subscription(ctx context.Context, originalTransactionID string) (SubscriptionStatus, error) {
	var r struct {
		Data []struct {
			LastTransactions []struct {
				OriginalTransactionID string `json:"originalTransactionId"`
				Status                int    `json:"status"`
				SignedTransactionInfo string `json:"signedTransactionInfo"`
				SignedRenewalInfo     string `json:"signedRenewalInfo"`
			} `json:"lastTransactions"`
		} `json:"data"`
	}
	if err := c.get(ctx, "/inApps/v1/subscriptions/"+url.PathEscape(originalTransactionID), &r); err != nil {
		return SubscriptionStatus{}, err
	}
	for _, group := range r.Data {
		for _, lt := range group.LastTransactions {
			if lt.OriginalTransactionID != originalTransactionID {
				continue
			}
			st := SubscriptionStatus{Status: lt.Status}
			if err := c.opts.Verifier.Decode(lt.SignedTransactionInfo, &st.Transaction); err != nil {
				return SubscriptionStatus{}, err
			}
			if lt.SignedRenewalInfo != "" {
				if err := c.opts.Verifier.Decode(lt.SignedRenewalInfo, &st.Renewal); err != nil {
					return SubscriptionStatus{}, err
				}
			}
			if st.Transaction.BundleID != c.opts.BundleID || st.Transaction.OriginalTransactionID != originalTransactionID {
				return SubscriptionStatus{}, ErrNotFound
			}
			return st, nil
		}
	}
	return SubscriptionStatus{}, ErrNotFound
}

// get asks production first and the sandbox when production does not know
// the id — Apple's advice, since App Review buys with sandbox accounts in
// production builds.
func (c *Client) get(ctx context.Context, path string, out any) error {
	for _, base := range []string{c.opts.ProductionURL, c.opts.SandboxURL} {
		err := c.getOnce(ctx, base+path, out)
		if !errors.Is(err, ErrNotFound) {
			return err
		}
	}
	return ErrNotFound
}

func (c *Client) getOnce(ctx context.Context, u string, out any) error {
	tok, err := c.authToken()
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+tok)
	resp, err := c.opts.HTTP.Do(req)
	if err != nil {
		return fmt.Errorf("%w: %w", ErrUnavailable, err)
	}
	defer func() { _ = resp.Body.Close() }()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return fmt.Errorf("%w: %w", ErrUnavailable, err)
	}
	switch {
	case resp.StatusCode == http.StatusOK:
		if err := json.Unmarshal(body, out); err != nil {
			return fmt.Errorf("app store: decode response: %w", err)
		}
		return nil
	case resp.StatusCode == http.StatusNotFound:
		return ErrNotFound
	case resp.StatusCode == http.StatusBadRequest:
		var e struct {
			ErrorCode int `json:"errorCode"`
		}
		_ = json.Unmarshal(body, &e)
		if e.ErrorCode == 4000006 || e.ErrorCode == 4000008 { // invalid transaction / original transaction id
			return ErrNotFound
		}
		return fmt.Errorf("app store: bad request (errorCode %d)", e.ErrorCode)
	case resp.StatusCode == http.StatusUnauthorized:
		return ErrAuth
	case resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500:
		return fmt.Errorf("%w: status %d", ErrUnavailable, resp.StatusCode)
	}
	return fmt.Errorf("app store: unexpected status %d", resp.StatusCode)
}

// authToken signs the short-lived JWT the API requires (ES256, 5 minutes).
func (c *Client) authToken() (string, error) {
	now := c.opts.Now()
	header, _ := json.Marshal(map[string]string{"alg": "ES256", "kid": c.opts.KeyID, "typ": "JWT"})
	claims, _ := json.Marshal(map[string]any{
		"iss": c.opts.IssuerID, "iat": now.Unix(), "exp": now.Add(5 * time.Minute).Unix(),
		"aud": "appstoreconnect-v1", "bid": c.opts.BundleID,
	})
	input := base64.RawURLEncoding.EncodeToString(header) + "." + base64.RawURLEncoding.EncodeToString(claims)
	digest := sha256.Sum256([]byte(input))
	r, s, err := ecdsa.Sign(rand.Reader, c.key, digest[:])
	if err != nil {
		return "", err
	}
	sig := make([]byte, 64)
	r.FillBytes(sig[:32])
	s.FillBytes(sig[32:])
	return input + "." + base64.RawURLEncoding.EncodeToString(sig), nil
}
