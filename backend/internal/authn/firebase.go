package authn

import (
	"context"
	"fmt"
	"sync"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/appcheck"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

// FirebaseOptions configures the Firebase-backed verifiers.
type FirebaseOptions struct {
	ProjectID string
	// CredentialsFile is a service account JSON with Firebase Authentication
	// Admin rights. Required for revocation checks and account deletion;
	// without it only signature/claims verification works.
	CredentialsFile string
}

// Firebase implements Verifier and AppChecker with the Firebase Admin SDK.
type Firebase struct {
	app      *firebase.App
	auth     *auth.Client
	hasCreds bool
	// baseCtx outlives requests: the App Check key set refreshes in the
	// background for the life of the process.
	baseCtx context.Context

	acMu      sync.Mutex
	appCheck  *appcheck.Client
	acRetryAt time.Time
}

// NewFirebase builds the Admin SDK clients. No network call is made here;
// public keys are fetched (and cached) on first verification.
func NewFirebase(ctx context.Context, opt FirebaseOptions) (*Firebase, error) {
	if opt.ProjectID == "" {
		return nil, fmt.Errorf("firebase: project id is required")
	}
	var clientOpts []option.ClientOption
	if opt.CredentialsFile != "" {
		// Explicit credential type: only a service account key is accepted.
		clientOpts = append(clientOpts, option.WithAuthCredentialsFile(option.ServiceAccount, opt.CredentialsFile))
	} else {
		clientOpts = append(clientOpts, option.WithoutAuthentication())
	}
	app, err := firebase.NewApp(ctx, &firebase.Config{ProjectID: opt.ProjectID}, clientOpts...)
	if err != nil {
		return nil, fmt.Errorf("firebase: init app: %w", err)
	}
	authClient, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("firebase: init auth: %w", err)
	}
	return &Firebase{app: app, auth: authClient, hasCreds: opt.CredentialsFile != "", baseCtx: ctx}, nil
}

// appCheckClient creates the App Check client on first use. Creating it
// downloads Google's key set; doing that lazily (retrying at most every 30 s)
// means a network blip at start-up cannot keep the whole API down.
func (f *Firebase) appCheckClient() (*appcheck.Client, error) {
	f.acMu.Lock()
	defer f.acMu.Unlock()
	if f.appCheck != nil {
		return f.appCheck, nil
	}
	if time.Now().Before(f.acRetryAt) {
		return nil, fmt.Errorf("%w: app check keys not loaded yet", ErrUnavailable)
	}
	c, err := f.app.AppCheck(f.baseCtx)
	if err != nil {
		f.acRetryAt = time.Now().Add(30 * time.Second)
		return nil, fmt.Errorf("%w: app check init: %w", ErrUnavailable, err)
	}
	f.appCheck = c
	return c, nil
}

// Verify implements Verifier.
func (f *Firebase) Verify(ctx context.Context, token string, checkRevoked bool) (Identity, error) {
	if token == "" {
		return Identity{}, ErrInvalidToken
	}
	var (
		t   *auth.Token
		err error
	)
	if checkRevoked && f.hasCreds {
		t, err = f.auth.VerifyIDTokenAndCheckRevoked(ctx, token)
	} else {
		t, err = f.auth.VerifyIDToken(ctx, token)
	}
	if err != nil {
		return Identity{}, mapAuthError(err)
	}
	if t.UID == "" {
		return Identity{}, ErrInvalidToken
	}
	emailVerified, _ := t.Claims["email_verified"].(bool)
	admin, _ := t.Claims[AdminClaim].(bool)
	return Identity{
		Provider:       IdentityProviderFirebase,
		Subject:        t.UID,
		SignInProvider: t.Firebase.SignInProvider,
		AuthTime:       time.Unix(t.AuthTime, 0).UTC(),
		EmailVerified:  emailVerified,
		Admin:          admin,
	}, nil
}

// LookupEmail implements AdminManager.
func (f *Firebase) LookupEmail(ctx context.Context, email string) (string, bool, error) {
	if !f.hasCreds {
		return "", false, fmt.Errorf("%w: firebase credentials not configured", ErrUnavailable)
	}
	u, err := f.auth.GetUserByEmail(ctx, email)
	if err != nil {
		return "", false, err
	}
	return u.UID, u.EmailVerified, nil
}

// SetAdmin implements AdminManager. Other custom claims are preserved.
func (f *Firebase) SetAdmin(ctx context.Context, subject string, admin bool) error {
	if !f.hasCreds {
		return fmt.Errorf("%w: firebase credentials not configured", ErrUnavailable)
	}
	u, err := f.auth.GetUser(ctx, subject)
	if err != nil {
		return err
	}
	claims := map[string]interface{}{}
	for k, v := range u.CustomClaims {
		claims[k] = v
	}
	if admin {
		claims[AdminClaim] = true
	} else {
		delete(claims, AdminClaim)
	}
	if err := f.auth.SetCustomUserClaims(ctx, subject, claims); err != nil {
		return err
	}
	// Force a fresh sign-in so the claim change applies immediately.
	return f.auth.RevokeRefreshTokens(ctx, subject)
}

func mapAuthError(err error) error {
	switch {
	case auth.IsIDTokenRevoked(err), auth.IsUserDisabled(err):
		return fmt.Errorf("%w: %w", ErrRevoked, err)
	case auth.IsIDTokenExpired(err), auth.IsIDTokenInvalid(err), auth.IsTenantIDMismatch(err), auth.IsUserNotFound(err):
		return fmt.Errorf("%w: %w", ErrInvalidToken, err)
	default:
		// Certificate fetch failures, network, quota: not the caller's fault.
		return fmt.Errorf("%w: %w", ErrUnavailable, err)
	}
}

// DeleteUser implements Verifier.
func (f *Firebase) DeleteUser(ctx context.Context, subject string) error {
	if !f.hasCreds {
		return fmt.Errorf("%w: firebase credentials not configured", ErrUnavailable)
	}
	if err := f.auth.DeleteUser(ctx, subject); err != nil && !auth.IsUserNotFound(err) {
		return fmt.Errorf("%w: %w", ErrUnavailable, err)
	}
	return nil
}

// AppCheck returns the App Check verifier backed by the same app.
func (f *Firebase) AppCheck() AppChecker { return firebaseAppCheck{f: f} }

type firebaseAppCheck struct{ f *Firebase }

func (a firebaseAppCheck) Verify(_ context.Context, token string) (tok AppCheckToken, err error) {
	if token == "" {
		return AppCheckToken{}, ErrInvalidToken
	}
	client, err := a.f.appCheckClient()
	if err != nil {
		return AppCheckToken{}, err
	}
	// The SDK type-asserts claims; never let a malformed token panic us.
	defer func() {
		if recover() != nil {
			tok, err = AppCheckToken{}, ErrInvalidToken
		}
	}()
	d, err := client.VerifyToken(token)
	if err != nil {
		return AppCheckToken{}, fmt.Errorf("%w: %w", ErrInvalidToken, err)
	}
	jti, _ := d.Claims["jti"].(string)
	return AppCheckToken{AppID: d.AppID, JTI: jti, ExpiresAt: d.ExpiresAt}, nil
}
