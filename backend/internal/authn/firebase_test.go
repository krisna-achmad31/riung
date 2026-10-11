package authn

import (
	"context"
	"errors"
	"testing"
)

// Garbage tokens are rejected locally as invalid (no network needed), and
// creating the verifier makes no network call.
func TestFirebaseRejectsMalformedTokens(t *testing.T) {
	fb, err := NewFirebase(context.Background(), FirebaseOptions{ProjectID: "riung-test"})
	if err != nil {
		t.Fatalf("NewFirebase: %v", err)
	}
	for _, tok := range []string{"", "not-a-jwt", "a.b.c"} {
		if _, err := fb.Verify(context.Background(), tok, false); !errors.Is(err, ErrInvalidToken) {
			t.Errorf("token %q: want ErrInvalidToken, got %v", tok, err)
		}
	}
	if err := fb.DeleteUser(context.Background(), "uid"); !errors.Is(err, ErrUnavailable) {
		t.Errorf("delete without credentials must be unavailable, got %v", err)
	}
	if _, err := fb.AppCheck().Verify(context.Background(), ""); !errors.Is(err, ErrInvalidToken) {
		t.Errorf("empty App Check token: %v", err)
	}
}

func TestNewFirebaseRequiresProject(t *testing.T) {
	if _, err := NewFirebase(context.Background(), FirebaseOptions{}); err == nil {
		t.Fatal("project id is required")
	}
}

func TestDevVerifier(t *testing.T) {
	d := &DevVerifier{}
	id, err := d.Verify(context.Background(), "dev:alice:google.com", true)
	if err != nil || id.Subject != "alice" || id.IsAnonymous() || id.Provider != IdentityProviderFirebase {
		t.Fatalf("got %+v %v", id, err)
	}
	if id, _ := d.Verify(context.Background(), "dev:boss:google.com:admin", false); !id.Admin {
		t.Error("dev admin token must carry the admin claim")
	}
	for _, bad := range []string{"alice", "dev::anonymous", "dev:a:facebook.com", "prod:a:anonymous", "dev:a:anonymous:x"} {
		if _, err := d.Verify(context.Background(), bad, false); !errors.Is(err, ErrInvalidToken) {
			t.Errorf("%q must be rejected", bad)
		}
	}
	if _, err := (DevAppChecker{}).Verify(context.Background(), "nope"); !errors.Is(err, ErrInvalidToken) {
		t.Error("dev app check must only accept \"dev\"")
	}
}
