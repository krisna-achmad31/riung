package authn

import (
	"context"
	"testing"
)

func TestDevAdminManager(t *testing.T) {
	m := DevAdminManager{}
	sub, verified, err := m.LookupEmail(context.Background(), "dev:postman")
	if err != nil || sub != "postman" || !verified {
		t.Fatalf("dev subject: %q %v %v", sub, verified, err)
	}
	for _, bad := range []string{"admin@example.com", "dev:", "dev:a:b"} {
		if _, _, err := m.LookupEmail(context.Background(), bad); err == nil {
			t.Fatalf("%q must be refused", bad)
		}
	}
}
