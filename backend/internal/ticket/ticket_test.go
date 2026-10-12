package ticket

import (
	"bytes"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/store"
)

func TestSignAndVerify(t *testing.T) {
	s, err := NewSigner("k1", bytes.Repeat([]byte{7}, 32))
	if err != nil {
		t.Fatal(err)
	}
	issued := time.Date(2026, 10, 12, 3, 4, 5, 999, time.UTC)
	tk := s.Sign(store.FocusTicket{ID: "a5e0", UserID: "u1", Source: "free_daily", DurationMin: 25,
		IssuedAt: issued, ExpiresAt: issued.Add(time.Hour)})
	if tk.IssuedAt != "2026-10-12T03:04:05Z" || tk.Kid != "k1" || !Verify(s.PublicKey(), tk) {
		t.Fatalf("ticket: %+v", tk)
	}
	if got := string(tk.Payload()); got != "riung-focus-ticket.v1|k1|a5e0|u1|free_daily|25|2026-10-12T03:04:05Z|2026-10-12T04:04:05Z" {
		t.Fatalf("payload: %s", got)
	}
	for _, mutate := range []func(*Ticket){
		func(x *Ticket) { x.DurationMin = 60 },
		func(x *Ticket) { x.UserID = "u2" },
		func(x *Ticket) { x.ExpiresAt = "2027-01-01T00:00:00Z" },
		func(x *Ticket) { x.Sig = "AAAA" },
	} {
		forged := tk
		mutate(&forged)
		if Verify(s.PublicKey(), forged) {
			t.Fatalf("tampered ticket verified: %+v", forged)
		}
	}
	other, _ := NewSigner("k2", bytes.Repeat([]byte{8}, 32))
	if Verify(other.PublicKey(), tk) {
		t.Fatal("another key must not verify")
	}
}

func TestNewSignerValidates(t *testing.T) {
	if _, err := NewSigner("k1", []byte("short")); err == nil {
		t.Fatal("short seed must fail")
	}
	if _, err := NewSigner("a|b", bytes.Repeat([]byte{1}, 32)); err == nil {
		t.Fatal("kid with separator must fail")
	}
}
