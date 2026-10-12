package rules

import (
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/store"
)

func TestPremiumStatusCanceledKeepsPaidPeriod(t *testing.T) {
	now := time.Date(2026, 10, 12, 0, 0, 0, 0, time.UTC)
	end := now.Add(10 * 24 * time.Hour)
	sub := &store.Subscription{Plan: "premium_yearly", Status: "canceled", ExpiresAt: &end, AutoRenewing: true}
	if p := PremiumStatus(sub, now, 3); !p.Active() || p.AutoRenewing || !p.Yearly() {
		t.Fatalf("canceled within paid period: %+v", p)
	}
	if p := PremiumStatus(sub, end.Add(time.Hour), 3); p.Active() {
		t.Fatalf("canceled after expiry gets no grace: %+v", p)
	}
	if p := PremiumStatus(sub, end.Add(4*24*time.Hour), 3); p.Status != "expired" {
		t.Fatalf("eventually expired: %+v", p)
	}
	revoked := &store.Subscription{Plan: "premium_monthly", Status: "revoked", ExpiresAt: &end}
	if p := PremiumStatus(revoked, now, 3); p.Active() {
		t.Fatalf("revoked is never active: %+v", p)
	}
}
