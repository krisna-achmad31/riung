// Package authn verifies who is calling: the Firebase ID token (user) and the
// Firebase App Check token (genuine app). Handlers depend only on the
// Verifier / AppChecker interfaces, so moving off Firebase Auth later means
// adding another implementation, not touching handlers (plan §3.1).
package authn

import (
	"context"
	"errors"
	"time"
)

// Sign-in providers reported in the token.
const (
	ProviderAnonymous = "anonymous"
	ProviderPassword  = "password"
	ProviderGoogle    = "google.com"
	ProviderApple     = "apple.com" // Sign in with Apple (iOS)
)

// IdentityProviderFirebase is the auth_identities.provider value for Firebase.
const IdentityProviderFirebase = "firebase"

// Identity is a verified caller.
type Identity struct {
	// Provider is the identity system ("firebase"); Subject its user id.
	Provider string
	Subject  string
	// SignInProvider is how the user signed in: anonymous, password, google.com, apple.com.
	SignInProvider string
	AuthTime       time.Time
	EmailVerified  bool
	// Admin is the riungAdmin custom claim (set only via `riung admin grant`).
	Admin bool
}

// AdminClaim is the custom claim that marks Admin API users.
const AdminClaim = "riungAdmin"

// IsAnonymous reports whether the session is a Firebase anonymous account.
func (i Identity) IsAnonymous() bool { return i.SignInProvider == ProviderAnonymous }

// Errors returned by verifiers.
var (
	// ErrInvalidToken: missing, malformed, expired, wrong audience or bad signature.
	ErrInvalidToken = errors.New("invalid token")
	// ErrRevoked: token revoked or user disabled (only when checkRevoked).
	ErrRevoked = errors.New("token revoked")
	// ErrUnavailable: the verifier could not reach its key/identity service;
	// the client should retry rather than sign out.
	ErrUnavailable = errors.New("auth service unavailable")
)

// Verifier checks ID tokens and manages the identity provider's accounts.
type Verifier interface {
	// Verify validates token. With checkRevoked it also asks the provider
	// whether the token was revoked or the account disabled.
	Verify(ctx context.Context, token string, checkRevoked bool) (Identity, error)
	// DeleteUser removes the account at the provider. Deleting an account
	// that no longer exists is not an error.
	DeleteUser(ctx context.Context, subject string) error
}

// AdminManager manages admin claims at the identity provider (CLI only).
type AdminManager interface {
	// LookupEmail returns the subject and whether the email is verified.
	LookupEmail(ctx context.Context, email string) (subject string, verified bool, err error)
	// SetAdmin sets or clears the admin claim, keeping other claims.
	SetAdmin(ctx context.Context, subject string, admin bool) error
}

// AppCheckToken is a verified App Check token.
type AppCheckToken struct {
	AppID     string
	JTI       string
	ExpiresAt time.Time
}

// AppChecker verifies Firebase App Check tokens.
type AppChecker interface {
	Verify(ctx context.Context, token string) (AppCheckToken, error)
}
