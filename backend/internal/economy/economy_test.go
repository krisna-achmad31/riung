package economy

import (
	"bytes"
	"os"
	"strings"
	"testing"
)

func TestEmbeddedPropsLoad(t *testing.T) {
	p, err := Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	// Spot-check values pinned by CLAUDE.md §3.
	if p.Earn.Checkin != 5 || p.Earn.Journal != 4 || p.Earn.MonsterTamed != 50 {
		t.Errorf("unexpected earn values: %+v", p.Earn)
	}
	if p.AppBeku.MaxPaidUnlocksPerDay != 3 || p.AppBeku.EscalationPerUnlock != 10 || p.AppBeku.UnlockCooldownSeconds != 60 {
		t.Errorf("unexpected Aplikasi Beku guards: %+v", p.AppBeku)
	}
	if p.Premium.YearlyPriceIdr != 590000 || p.Caps.MissionsPerDay != 3 {
		t.Errorf("unexpected premium/caps: %+v %+v", p.Premium, p.Caps)
	}
}

// The server copy must stay identical to the documented source of truth.
func TestMatchesDocsCopy(t *testing.T) {
	docs, err := os.ReadFile("../../../docs/economy-props.json")
	if os.IsNotExist(err) {
		t.Skip("docs/economy-props.json not present (built outside the monorepo)")
	}
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(docs, raw) {
		t.Fatal("backend/internal/economy/economy-props.json differs from docs/economy-props.json — copy the docs file over")
	}
}

func TestValidateRejectsZeroAndUnknown(t *testing.T) {
	bad := strings.Replace(string(raw), `"checkin": 5`, `"checkin": 0`, 1)
	if _, err := parse([]byte(bad)); err == nil || !strings.Contains(err.Error(), "Checkin") {
		t.Fatalf("zero reward must be rejected, got %v", err)
	}
	unknown := strings.Replace(string(raw), `"checkin": 5`, `"checkin": 5, "typo": 1`, 1)
	if _, err := parse([]byte(unknown)); err == nil {
		t.Fatal("unknown fields must be rejected")
	}
	price := strings.Replace(string(raw), `"yearlyPriceIdr": 590000`, `"yearlyPriceIdr": 500000`, 1)
	if _, err := parse([]byte(price)); err == nil {
		t.Fatal("yearly price must be derived from monthly × 10")
	}
}
