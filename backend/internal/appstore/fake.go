package appstore

import (
	"context"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Fake stands in for the App Store in local development and tests.
// Transactions can be registered with Put*; in addition it understands
// self-describing dev transaction ids so the dev stack works with curl:
//
//	dev-coin:<appAccountToken>:<productId>:<nonce>
//	dev-sub:<appAccountToken>:<productId>:<days>:<nonce>
//
// config refuses DEV_BILLING outside RIUNG_ENV=dev.
type Fake struct {
	BundleID string
	Now      func() time.Time

	mu   sync.Mutex
	txns map[string]Transaction
	subs map[string]SubscriptionStatus
	fail map[string]error
}

// NewFake returns an empty fake for bundleID.
func NewFake(bundleID string) *Fake {
	return &Fake{BundleID: bundleID, Now: time.Now, txns: map[string]Transaction{},
		subs: map[string]SubscriptionStatus{}, fail: map[string]error{}}
}

// PutTransaction registers (or replaces) a transaction.
func (f *Fake) PutTransaction(t Transaction) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.txns[t.TransactionID] = t
}

// PutSubscription registers (or replaces) a subscription state; its latest
// transaction is also returned by Transaction.
func (f *Fake) PutSubscription(s SubscriptionStatus) {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.subs[s.Transaction.OriginalTransactionID] = s
	f.txns[s.Transaction.TransactionID] = s.Transaction
}

// Fail makes every call for id return err (nil clears it).
func (f *Fake) Fail(id string, err error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if err == nil {
		delete(f.fail, id)
		return
	}
	f.fail[id] = err
}

// Transaction implements API.
func (f *Fake) Transaction(_ context.Context, id string) (Transaction, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if err := f.fail[id]; err != nil {
		return Transaction{}, err
	}
	if t, ok := f.txns[id]; ok {
		return t, nil
	}
	if t, ok := f.devTransaction(id); ok {
		return t, nil
	}
	return Transaction{}, ErrNotFound
}

// Subscription implements API.
func (f *Fake) Subscription(_ context.Context, original string) (SubscriptionStatus, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if err := f.fail[original]; err != nil {
		return SubscriptionStatus{}, err
	}
	if s, ok := f.subs[original]; ok {
		return s, nil
	}
	if t, ok := f.devTransaction(original); ok && t.Type == TypeAutoRenewing {
		return SubscriptionStatus{Status: StatusActive, Transaction: t,
			Renewal: RenewalInfo{OriginalTransactionID: original, AutoRenewProductID: t.ProductID, AutoRenewStatus: 1,
				Environment: EnvSandbox}}, nil
	}
	return SubscriptionStatus{}, ErrNotFound
}

func (f *Fake) devTransaction(id string) (Transaction, bool) {
	parts := strings.Split(id, ":")
	now := f.Now()
	t := Transaction{TransactionID: id, OriginalTransactionID: id, BundleID: f.BundleID, Quantity: 1,
		PurchaseDate: now.UnixMilli(), InAppOwnershipType: "PURCHASED", Environment: EnvSandbox, SignedDate: now.UnixMilli()}
	switch {
	case len(parts) == 4 && parts[0] == "dev-coin":
		t.AppAccountToken, t.ProductID, t.Type = parts[1], parts[2], TypeConsumable
		return t, true
	case len(parts) == 5 && parts[0] == "dev-sub":
		days, err := strconv.Atoi(parts[3])
		if err != nil || days <= 0 || days > 400 {
			return Transaction{}, false
		}
		t.AppAccountToken, t.ProductID, t.Type = parts[1], parts[2], TypeAutoRenewing
		t.ExpiresDate = now.Add(time.Duration(days) * 24 * time.Hour).UnixMilli()
		return t, true
	}
	return Transaction{}, false
}
