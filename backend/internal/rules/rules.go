// Package rules implements the economy and progress rules (CLAUDE.md §3,
// docs/backend-api-spec.md §3.3–3.6, §5): what a practice event is worth,
// daily caps, streaks, taming, shop prices and what may be worn. The app
// reports what happened; only this package decides coins and progress.
package rules

import (
	"context"
	"errors"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Settings reads admin-adjustable values (implemented by *settings.Cache).
type Settings interface {
	Int(ctx context.Context, key string) int
}

// Service applies the rules against the store.
type Service struct {
	Store    *store.Store
	Economy  economy.Props
	Catalog  *catalog.Catalog
	Settings Settings
	Now      func() time.Time
}

// ValidationError is a client mistake (400).
type ValidationError struct {
	Field   string
	Message string
}

func (e *ValidationError) Error() string { return e.Message }

func invalid(field, msg string) error { return &ValidationError{Field: field, Message: msg} }

// Errors mapped to API codes by the handlers.
var (
	ErrNotFound        = errors.New("not found")
	ErrAlreadyOwned    = errors.New("already owned")
	ErrNotOwned        = errors.New("item not owned")
	ErrPremiumRequired = errors.New("premium required")
)

// PriceChangedError: the client's expectedPrice is stale.
type PriceChangedError struct{ Price int }

func (e *PriceChangedError) Error() string { return "price changed" }

// LocalDay returns the calendar date of t in time zone tz (UTC-midnight value).
func LocalDay(t time.Time, tz string) time.Time {
	loc, err := time.LoadLocation(tz)
	if err != nil {
		loc, _ = time.LoadLocation("Asia/Jakarta")
	}
	y, m, d := t.In(loc).Date()
	return time.Date(y, m, d, 0, 0, 0, 0, time.UTC)
}

// Premium is the effective subscription state.
type Premium struct {
	Status       string // none | active | in_grace | expired | canceled | on_hold | paused | revoked
	Plan         *string
	ExpiresAt    *time.Time
	AutoRenewing bool
}

// Active reports whether premium perks apply now.
func (p Premium) Active() bool { return p.Status == "active" || p.Status == "in_grace" }

// Yearly reports an active yearly plan (daily coins perk).
func (p Premium) Yearly() bool { return p.Active() && p.Plan != nil && *p.Plan == "premium_yearly" }

// PremiumStatus derives the effective status: past expiry an active
// subscription is in grace for graceDays, then expired. A canceled
// subscription (auto-renew turned off) stays active until the paid period ends.
func PremiumStatus(sub *store.Subscription, now time.Time, graceDays int) Premium {
	if sub == nil {
		return Premium{Status: "none"}
	}
	p := Premium{Status: sub.Status, Plan: &sub.Plan, ExpiresAt: sub.ExpiresAt, AutoRenewing: sub.AutoRenewing}
	if p.Status == "canceled" && sub.ExpiresAt != nil && now.Before(*sub.ExpiresAt) {
		p.Status, p.AutoRenewing = "active", false
	}
	if sub.ExpiresAt != nil {
		grace := time.Duration(graceDays) * 24 * time.Hour
		switch {
		case now.After(sub.ExpiresAt.Add(grace)):
			p.Status = "expired"
		case now.After(*sub.ExpiresAt) && p.Status == "active":
			p.Status = "in_grace"
		}
	}
	return p
}

func (s *Service) premium(tx *store.UserTx) (Premium, error) {
	sub, err := tx.Subscription()
	if err != nil {
		return Premium{}, err
	}
	return PremiumStatus(sub, s.Now(), s.Economy.Premium.GraceDays), nil
}
