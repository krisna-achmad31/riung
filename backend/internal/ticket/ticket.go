// Package ticket signs Focus Mode tickets (docs/backend-api-spec.md §3.7,
// §4.6) with Ed25519 so the app can check a stored ticket offline. The
// server never trusts the signature on redemption: the database row is the
// source of truth and is consumed once.
package ticket

import (
	"crypto/ed25519"
	"encoding/base64"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Ticket is the signed form handed to the app.
type Ticket struct {
	ID          string `json:"id"`
	UserID      string `json:"userId"`
	Source      string `json:"source"`
	DurationMin int    `json:"durationMin"`
	IssuedAt    string `json:"issuedAt"`
	ExpiresAt   string `json:"expiresAt"`
	Kid         string `json:"kid"`
	Sig         string `json:"sig"`
}

// Payload is the exact byte string that is signed:
//
//	riung-focus-ticket.v1|<kid>|<id>|<userId>|<source>|<durationMin>|<issuedAt>|<expiresAt>
//
// with times in RFC 3339 UTC, whole seconds (e.g. 2026-10-12T03:04:05Z).
func (t Ticket) Payload() []byte {
	return []byte(strings.Join([]string{"riung-focus-ticket.v1", t.Kid, t.ID, t.UserID, t.Source,
		strconv.Itoa(t.DurationMin), t.IssuedAt, t.ExpiresAt}, "|"))
}

// Signer holds the current signing key.
type Signer struct {
	kid  string
	priv ed25519.PrivateKey
}

// NewSigner builds a signer from a 32-byte Ed25519 seed.
func NewSigner(kid string, seed []byte) (*Signer, error) {
	if kid == "" || len(kid) > 32 || strings.Contains(kid, "|") {
		return nil, errors.New("ticket key id must be 1–32 characters without '|'")
	}
	if len(seed) != ed25519.SeedSize {
		return nil, errors.New("ticket signing key must be a 32-byte Ed25519 seed")
	}
	return &Signer{kid: kid, priv: ed25519.NewKeyFromSeed(seed)}, nil
}

// Kid is the key id.
func (s *Signer) Kid() string { return s.kid }

// PublicKey is the verification key, base64url without padding.
func (s *Signer) PublicKey() string {
	return base64.RawURLEncoding.EncodeToString(s.priv.Public().(ed25519.PublicKey))
}

// FormatTime is the ticket time format.
func FormatTime(t time.Time) string { return t.UTC().Truncate(time.Second).Format(time.RFC3339) }

// Sign returns the signed ticket for a stored one.
func (s *Signer) Sign(t store.FocusTicket) Ticket {
	out := Ticket{ID: t.ID, UserID: t.UserID, Source: t.Source, DurationMin: t.DurationMin,
		IssuedAt: FormatTime(t.IssuedAt), ExpiresAt: FormatTime(t.ExpiresAt), Kid: s.kid}
	out.Sig = base64.RawURLEncoding.EncodeToString(ed25519.Sign(s.priv, out.Payload()))
	return out
}

// Verify checks a ticket against a base64url public key (what the app does).
func Verify(publicKey string, t Ticket) bool {
	pub, err := base64.RawURLEncoding.DecodeString(publicKey)
	if err != nil || len(pub) != ed25519.PublicKeySize {
		return false
	}
	sig, err := base64.RawURLEncoding.DecodeString(t.Sig)
	if err != nil {
		return false
	}
	return ed25519.Verify(ed25519.PublicKey(pub), t.Payload(), sig)
}
