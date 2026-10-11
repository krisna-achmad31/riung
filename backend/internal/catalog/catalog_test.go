package catalog

import (
	"bytes"
	"os"
	"strings"
	"testing"

	"github.com/krisna-achmad31/riung/backend/internal/economy"
)

func load(t *testing.T) *Catalog {
	t.Helper()
	c, err := Load(economy.MustLoad())
	if err != nil {
		t.Fatalf("Load: %v", err)
	}
	return c
}

func TestMatchesDocsCopy(t *testing.T) {
	docs, err := os.ReadFile("../../../docs/catalog.json")
	if os.IsNotExist(err) {
		t.Skip("docs/catalog.json not present")
	}
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(docs, raw) {
		t.Fatal("backend/internal/catalog/catalog.json differs from docs/catalog.json — copy the docs file over")
	}
}

func TestPricesResolveFromEconomy(t *testing.T) {
	c := load(t)
	cases := map[string]int{
		"topi_rajut": 100, "bantal_mini": 300, "bingkai_emas": 500, "batu_tenang": 300,
		"acc_beanie": 60, "acc_witchHat": 100, "acc_halo": 300,
		"cardstyle_taman": 100, "cardstyle_aurora": 300,
	}
	for id, want := range cases {
		got, ok := c.CosmeticByInventoryID(id)
		if !ok || got.Price != want {
			t.Errorf("%s: got %+v ok=%v, want price %d", id, got, ok, want)
		}
	}
	for _, id := range []string{"cardstyle_klasik", "acc_", "beanie", "unknown", "cardstyle_"} {
		if _, ok := c.CosmeticByInventoryID(id); ok {
			t.Errorf("%q must not be purchasable", id)
		}
	}
	if f, _ := c.FocusPack("focus_5"); f.Price != 100 || f.Sessions != 5 {
		t.Errorf("focus_5: %+v", f)
	}
}

func TestBundlePriceMatchesApp(t *testing.T) {
	c := load(t)
	cozy, _ := c.Bundle("cozy") // beanie 60 + scarf 60 + roundGlasses 60 = 180 → 144 → 145
	if p, missing := c.BundlePrice(cozy, map[string]bool{}); p != 145 || len(missing) != 3 {
		t.Fatalf("cozy: %d %v", p, missing)
	}
	// Owned items are not charged: scarf + roundGlasses = 120 → 96 → 95.
	if p, missing := c.BundlePrice(cozy, map[string]bool{"acc_beanie": true}); p != 95 || len(missing) != 2 {
		t.Fatalf("cozy minus beanie: %d %v", p, missing)
	}
	all := map[string]bool{"acc_beanie": true, "acc_scarf": true, "acc_roundGlasses": true}
	if p, missing := c.BundlePrice(cozy, all); p != 0 || missing != nil {
		t.Fatalf("fully owned: %d %v", p, missing)
	}
	jung, _ := c.Bundle("jungSet") // 300 + 100 + 100 + 300 = 800 → 640
	if p, _ := c.BundlePrice(jung, nil); p != 640 {
		t.Fatalf("jungSet: %d", p)
	}
}

func TestLookups(t *testing.T) {
	c := load(t)
	if m, ok := c.Monster("bara"); !ok || m.Family != "habit" {
		t.Error("habit monsters must be known")
	}
	if a, _ := c.Accessory("jungCrown"); a.AvailableFor("temperament") || !a.AvailableFor("jung") {
		t.Error("exclusive accessory availability")
	}
	if m, _ := c.Meditation("body_scan"); !m.Premium {
		t.Error("only the first three meditations are free")
	}
	if len(c.LessonsOfLevel(1)) != 7 || len(c.LessonsOfLevel(3)) != 8 {
		t.Error("Better Me levels")
	}
}

func TestValidation(t *testing.T) {
	e := economy.MustLoad()
	bad := strings.Replace(string(raw), `"priceTier": "cosmeticCommon"`, `"priceTier": "free"`, 1)
	if _, err := parse([]byte(bad), e); err == nil || !strings.Contains(err.Error(), "unknown priceTier") {
		t.Fatalf("unknown tier must fail: %v", err)
	}
	bad = strings.Replace(string(raw), `"monsterId": "kabut",`, `"monsterId": "naga",`, 1)
	if _, err := parse([]byte(bad), e); err == nil || !strings.Contains(err.Error(), "unknown monster") {
		t.Fatalf("unknown monster must fail: %v", err)
	}
}
