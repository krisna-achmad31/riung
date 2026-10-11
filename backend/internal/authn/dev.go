package authn

import (
	"context"
	"strings"
	"sync"
	"time"
)

// DevVerifier accepts tokens of the form "dev:<uid>:<signInProvider>", e.g.
// "dev:alice:anonymous" or "dev:bob:google.com" (append ":admin" for the admin
// claim), for local development and tests without Firebase. config.Load
// refuses DEV_AUTH outside RIUNG_ENV=dev, so it can never be enabled in
// production.
type DevVerifier struct {
	mu      sync.Mutex
	deleted []string
}

// Verify implements Verifier.
func (d *DevVerifier) Verify(_ context.Context, token string, _ bool) (Identity, error) {
	parts := strings.Split(token, ":")
	admin := false
	if len(parts) == 4 && parts[3] == "admin" {
		parts, admin = parts[:3], true
	}
	if len(parts) != 3 || parts[0] != "dev" || parts[1] == "" || len(parts[1]) > 128 {
		return Identity{}, ErrInvalidToken
	}
	switch parts[2] {
	case ProviderAnonymous, ProviderPassword, ProviderGoogle:
	default:
		return Identity{}, ErrInvalidToken
	}
	return Identity{
		Provider:       IdentityProviderFirebase,
		Subject:        parts[1],
		SignInProvider: parts[2],
		AuthTime:       time.Now().UTC(),
		EmailVerified:  parts[2] != ProviderAnonymous,
		Admin:          admin,
	}, nil
}

// DeleteUser implements Verifier.
func (d *DevVerifier) DeleteUser(_ context.Context, subject string) error {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.deleted = append(d.deleted, subject)
	return nil
}

// DeletedSubjects returns the subjects passed to DeleteUser (for tests).
func (d *DevVerifier) DeletedSubjects() []string {
	d.mu.Lock()
	defer d.mu.Unlock()
	return append([]string(nil), d.deleted...)
}

// DevAppChecker accepts the literal token "dev" (and nothing else).
type DevAppChecker struct{}

// Verify implements AppChecker.
func (DevAppChecker) Verify(_ context.Context, token string) (AppCheckToken, error) {
	if token != "dev" {
		return AppCheckToken{}, ErrInvalidToken
	}
	return AppCheckToken{AppID: "dev", ExpiresAt: time.Now().Add(time.Hour)}, nil
}
