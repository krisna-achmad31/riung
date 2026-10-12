// Package billing verifies Google Play purchases on the server (CLAUDE.md §6)
// and keeps coins and Premium in sync with Play: purchase verification,
// Real-time Developer Notifications (RTDN) and refunds.
package billing

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"google.golang.org/api/androidpublisher/v3"
	"google.golang.org/api/googleapi"
	"google.golang.org/api/option"
)

// Errors returned by a Publisher.
var (
	// ErrPurchaseNotFound: Play does not know the token (forged, wrong app, expired).
	ErrPurchaseNotFound = errors.New("purchase not found at Google Play")
	// ErrPlayUnavailable: Play could not be reached or refused our credentials.
	ErrPlayUnavailable = errors.New("google play unavailable")
)

// Product purchase states (Android Publisher purchases.products).
const (
	ProductPurchased = 0
	ProductCanceled  = 1
	ProductPending   = 2
)

// ProductPurchase is the part of a one-time purchase we use.
type ProductPurchase struct {
	ProductID         string
	OrderID           string
	PurchaseState     int64
	Acknowledged      bool
	Consumed          bool
	Quantity          int64
	ObfuscatedAccount string
	Test              bool
}

// Subscription states (Android Publisher subscriptionsv2).
const (
	SubActive        = "SUBSCRIPTION_STATE_ACTIVE"
	SubCanceled      = "SUBSCRIPTION_STATE_CANCELED"
	SubInGrace       = "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
	SubOnHold        = "SUBSCRIPTION_STATE_ON_HOLD"
	SubPaused        = "SUBSCRIPTION_STATE_PAUSED"
	SubExpired       = "SUBSCRIPTION_STATE_EXPIRED"
	SubPending       = "SUBSCRIPTION_STATE_PENDING"
	SubPendingCancel = "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED"
)

// SubscriptionPurchase is the part of a subscription we use.
type SubscriptionPurchase struct {
	State             string
	ProductID         string
	ExpiresAt         *time.Time
	AutoRenewing      bool
	Acknowledged      bool
	LinkedToken       string
	ObfuscatedAccount string
	OrderID           string
	Test              bool
}

// VoidedPurchase is a refunded / charged-back / revoked purchase.
type VoidedPurchase struct {
	Token    string
	OrderID  string
	VoidedAt time.Time
	Quantity int64
}

// Publisher is the Google Play Developer API surface we need.
type Publisher interface {
	GetProduct(ctx context.Context, productID, token string) (ProductPurchase, error)
	GetSubscription(ctx context.Context, token string) (SubscriptionPurchase, error)
	AcknowledgeSubscription(ctx context.Context, productID, token string) error
	AcknowledgeProduct(ctx context.Context, productID, token string) error
	// ListVoided returns purchases voided since `since` (Play keeps 30 days).
	ListVoided(ctx context.Context, since time.Time) ([]VoidedPurchase, error)
}

// --- Google implementation -------------------------------------------------------

// GooglePublisher calls the Android Publisher API with a service account that
// is linked to the app in Play Console (API access: view financial data,
// manage orders and subscriptions).
type GooglePublisher struct {
	svc         *androidpublisher.Service
	packageName string
}

// NewGooglePublisher builds the client. No network call is made here.
func NewGooglePublisher(ctx context.Context, packageName, credentialsFile string) (*GooglePublisher, error) {
	return newGooglePublisher(ctx, packageName,
		option.WithAuthCredentialsFile(option.ServiceAccount, credentialsFile),
		option.WithScopes(androidpublisher.AndroidpublisherScope))
}

func newGooglePublisher(ctx context.Context, packageName string, opts ...option.ClientOption) (*GooglePublisher, error) {
	svc, err := androidpublisher.NewService(ctx, opts...)
	if err != nil {
		return nil, fmt.Errorf("android publisher: %w", err)
	}
	return &GooglePublisher{svc: svc, packageName: packageName}, nil
}

func playError(err error) error {
	var gerr *googleapi.Error
	if errors.As(err, &gerr) {
		switch gerr.Code {
		case http.StatusNotFound, http.StatusGone, http.StatusBadRequest:
			return fmt.Errorf("%w: %w", ErrPurchaseNotFound, err)
		}
	}
	return fmt.Errorf("%w: %w", ErrPlayUnavailable, err)
}

// GetProduct implements Publisher.
func (g *GooglePublisher) GetProduct(ctx context.Context, productID, token string) (ProductPurchase, error) {
	p, err := g.svc.Purchases.Products.Get(g.packageName, productID, token).Context(ctx).Do()
	if err != nil {
		return ProductPurchase{}, playError(err)
	}
	q := p.Quantity
	if q < 1 {
		q = 1
	}
	return ProductPurchase{
		ProductID: productID, OrderID: p.OrderId, PurchaseState: p.PurchaseState,
		Acknowledged: p.AcknowledgementState == 1, Consumed: p.ConsumptionState == 1, Quantity: q,
		ObfuscatedAccount: p.ObfuscatedExternalAccountId,
		Test:              p.PurchaseType != nil && *p.PurchaseType == 0,
	}, nil
}

// GetSubscription implements Publisher.
func (g *GooglePublisher) GetSubscription(ctx context.Context, token string) (SubscriptionPurchase, error) {
	s, err := g.svc.Purchases.Subscriptionsv2.Get(g.packageName, token).Context(ctx).Do()
	if err != nil {
		return SubscriptionPurchase{}, playError(err)
	}
	out := SubscriptionPurchase{
		State: s.SubscriptionState, LinkedToken: s.LinkedPurchaseToken, OrderID: s.LatestOrderId,
		Acknowledged: s.AcknowledgementState == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
		Test:         s.TestPurchase != nil,
	}
	if s.ExternalAccountIdentifiers != nil {
		out.ObfuscatedAccount = s.ExternalAccountIdentifiers.ObfuscatedExternalAccountId
	}
	// One base plan per subscription in Riung: use the line item that lasts longest.
	for _, li := range s.LineItems {
		exp, err := time.Parse(time.RFC3339Nano, li.ExpiryTime)
		if err != nil {
			continue
		}
		if out.ExpiresAt == nil || exp.After(*out.ExpiresAt) {
			e := exp.UTC()
			out.ExpiresAt, out.ProductID = &e, li.ProductId
			out.AutoRenewing = li.AutoRenewingPlan != nil && li.AutoRenewingPlan.AutoRenewEnabled
		}
	}
	return out, nil
}

// AcknowledgeSubscription implements Publisher.
func (g *GooglePublisher) AcknowledgeSubscription(ctx context.Context, productID, token string) error {
	err := g.svc.Purchases.Subscriptions.Acknowledge(g.packageName, productID, token,
		&androidpublisher.SubscriptionPurchasesAcknowledgeRequest{}).Context(ctx).Do()
	if err != nil {
		return playError(err)
	}
	return nil
}

// AcknowledgeProduct implements Publisher (acknowledge only, never consume).
func (g *GooglePublisher) AcknowledgeProduct(ctx context.Context, productID, token string) error {
	err := g.svc.Purchases.Products.Acknowledge(g.packageName, productID, token,
		&androidpublisher.ProductPurchasesAcknowledgeRequest{}).Context(ctx).Do()
	if err != nil {
		return playError(err)
	}
	return nil
}

// ListVoided implements Publisher (one-time products and subscriptions).
func (g *GooglePublisher) ListVoided(ctx context.Context, since time.Time) ([]VoidedPurchase, error) {
	var out []VoidedPurchase
	page := ""
	for {
		call := g.svc.Purchases.Voidedpurchases.List(g.packageName).StartTime(since.UnixMilli()).Type(1).MaxResults(1000).Context(ctx)
		if page != "" {
			call = call.Token(page)
		}
		res, err := call.Do()
		if err != nil {
			return nil, playError(err)
		}
		for _, v := range res.VoidedPurchases {
			q := v.VoidedQuantity
			if q < 1 {
				q = 1
			}
			out = append(out, VoidedPurchase{Token: v.PurchaseToken, OrderID: v.OrderId, VoidedAt: time.UnixMilli(v.VoidedTimeMillis).UTC(), Quantity: q})
		}
		if res.TokenPagination == nil || res.TokenPagination.NextPageToken == "" {
			return out, nil
		}
		page = res.TokenPagination.NextPageToken
	}
}

// --- fake (dev & tests) ---------------------------------------------------------------

// FakePublisher stands in for Play in local development and tests. Tokens can
// be registered with Put*; in addition it understands self-describing dev
// tokens so the dev stack can be exercised with curl:
//
//	dev-coin:<billingAccountId>:<productId>:<nonce>
//	dev-sub:<billingAccountId>:<productId>:<days>:<nonce>
//
// config refuses DEV_BILLING outside RIUNG_ENV=dev.
type FakePublisher struct {
	mu     sync.Mutex
	prods  map[string]ProductPurchase
	subs   map[string]SubscriptionPurchase
	voided []VoidedPurchase
	acked  []string
}

// NewFakePublisher returns an empty fake.
func NewFakePublisher() *FakePublisher {
	return &FakePublisher{prods: map[string]ProductPurchase{}, subs: map[string]SubscriptionPurchase{}}
}

// PutProduct registers a one-time purchase.
func (f *FakePublisher) PutProduct(token string, p ProductPurchase) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.prods[token] = p
}

// PutSubscription registers (or updates) a subscription.
func (f *FakePublisher) PutSubscription(token string, s SubscriptionPurchase) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.subs[token] = s
}

// Void adds a voided purchase.
func (f *FakePublisher) Void(v VoidedPurchase) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.voided = append(f.voided, v)
}

// Acked returns tokens acknowledged by the server.
func (f *FakePublisher) Acked() []string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]string(nil), f.acked...)
}

// GetProduct implements Publisher.
func (f *FakePublisher) GetProduct(_ context.Context, productID, token string) (ProductPurchase, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if p, ok := f.prods[token]; ok {
		if p.ProductID != productID {
			return ProductPurchase{}, ErrPurchaseNotFound
		}
		return p, nil
	}
	parts := strings.Split(token, ":")
	if len(parts) == 4 && parts[0] == "dev-coin" && parts[2] == productID {
		return ProductPurchase{ProductID: productID, OrderID: "GPA.DEV-" + parts[3], PurchaseState: ProductPurchased,
			Quantity: 1, ObfuscatedAccount: parts[1], Test: true}, nil
	}
	return ProductPurchase{}, ErrPurchaseNotFound
}

// GetSubscription implements Publisher.
func (f *FakePublisher) GetSubscription(_ context.Context, token string) (SubscriptionPurchase, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if s, ok := f.subs[token]; ok {
		return s, nil
	}
	parts := strings.Split(token, ":")
	if len(parts) == 5 && parts[0] == "dev-sub" {
		days, err := strconv.Atoi(parts[3])
		if err == nil && days > 0 && days <= 400 {
			exp := time.Now().UTC().Add(time.Duration(days) * 24 * time.Hour)
			return SubscriptionPurchase{State: SubActive, ProductID: parts[2], ExpiresAt: &exp, AutoRenewing: true,
				ObfuscatedAccount: parts[1], OrderID: "GPA.DEV-" + parts[4], Test: true}, nil
		}
	}
	return SubscriptionPurchase{}, ErrPurchaseNotFound
}

// AcknowledgeSubscription implements Publisher.
func (f *FakePublisher) AcknowledgeSubscription(_ context.Context, _, token string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.acked = append(f.acked, token)
	if s, ok := f.subs[token]; ok {
		s.Acknowledged = true
		f.subs[token] = s
	}
	return nil
}

// AcknowledgeProduct implements Publisher.
func (f *FakePublisher) AcknowledgeProduct(_ context.Context, _, token string) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.acked = append(f.acked, token)
	if p, ok := f.prods[token]; ok {
		p.Acknowledged = true
		f.prods[token] = p
	}
	return nil
}

// ListVoided implements Publisher.
func (f *FakePublisher) ListVoided(_ context.Context, since time.Time) ([]VoidedPurchase, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	var out []VoidedPurchase
	for _, v := range f.voided {
		if !v.VoidedAt.Before(since) {
			out = append(out, v)
		}
	}
	return out, nil
}
