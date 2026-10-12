// Package catalog holds the items and content that economy rules depend on
// (cosmetics, accessories, card styles, bundles, focus packs, journal prompts,
// meditations, Better Me lessons), loaded from the embedded catalog.json — a
// byte-for-byte copy of docs/catalog.json. Prices are not stored here: each
// item names a tier that resolves to a number in economy-props.json.
package catalog

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"math"

	"github.com/krisna-achmad31/riung/backend/internal/economy"
)

//go:embed catalog.json
var raw []byte

// Inventory id prefixes (match the app's ownedCosmetics ids).
const (
	AccessoryPrefix = "acc_"
	CardStylePrefix = "cardstyle_"
)

// Monster is one tameable monster.
type Monster struct {
	ID     string `json:"id"`
	Family string `json:"family"` // saboteur | habit
}

// MonsterCosmetic is a cosmetic worn by monsters.
type MonsterCosmetic struct {
	ID        string `json:"id"`
	MonsterID string `json:"monsterId"`
	Slot      string `json:"slot"`
	PriceTier string `json:"priceTier"`
	// Exclusive items can only be worn by MonsterID.
	Exclusive bool `json:"exclusive"`
	Price     int  `json:"-"`
}

// Accessory is a personality-character accessory.
type Accessory struct {
	ID          string  `json:"id"`
	Slot        string  `json:"slot"`
	PriceTier   string  `json:"priceTier"`
	ExclusiveTo *string `json:"exclusiveTo"`
	Price       int     `json:"-"`
}

// InventoryID is the owned-item id of the accessory.
func (a Accessory) InventoryID() string { return AccessoryPrefix + a.ID }

// AvailableFor reports whether the accessory may be worn by test's character.
func (a Accessory) AvailableFor(test string) bool {
	return a.ExclusiveTo == nil || *a.ExclusiveTo == test
}

// AccessoryBundle is a discounted set of accessories.
type AccessoryBundle struct {
	ID          string   `json:"id"`
	Items       []string `json:"items"`
	ExclusiveTo *string  `json:"exclusiveTo"`
}

// CardStyle is a character card look; a nil PriceTier means free.
type CardStyle struct {
	ID        string  `json:"id"`
	PriceTier *string `json:"priceTier"`
	Price     int     `json:"-"`
}

// Free reports whether the style needs no purchase.
func (c CardStyle) Free() bool { return c.PriceTier == nil }

// InventoryID is the owned-item id of the card style.
func (c CardStyle) InventoryID() string { return CardStylePrefix + c.ID }

// FocusPack is a bundle of prepaid Focus sessions.
type FocusPack struct {
	ID        string `json:"id"`
	Sessions  int    `json:"sessions"`
	PriceTier string `json:"priceTier"`
	Price     int    `json:"-"`
}

// AppBekuApp is an app that can be frozen. The id is the Android package
// name from the app's catalog; nothing else about the app is known here.
type AppBekuApp struct {
	ID    string `json:"id"`
	Group string `json:"group"`
}

// AppBekuUnit is a single-app unlock of fixed length.
type AppBekuUnit struct {
	Minutes   int    `json:"minutes"`
	PriceTier string `json:"priceTier"`
	Price     int    `json:"-"`
}

// AppBekuGrant is minutes unlocked for one app.
type AppBekuGrant struct {
	AppID   string `json:"appId"`
	Minutes int    `json:"minutes"`
}

// AppBekuBundle unlocks several apps at once: either a fixed list (Apps) or
// MinutesPerApp for each app of Group the user chooses.
type AppBekuBundle struct {
	ID            string         `json:"id"`
	PriceTier     string         `json:"priceTier"`
	Apps          []AppBekuGrant `json:"apps,omitempty"`
	Group         string         `json:"group,omitempty"`
	MinutesPerApp int            `json:"minutesPerApp,omitempty"`
	Price         int            `json:"-"`
}

// AppBeku is the Aplikasi Beku catalog.
type AppBeku struct {
	Apps    []AppBekuApp    `json:"apps"`
	Units   []AppBekuUnit   `json:"units"`
	Bundles []AppBekuBundle `json:"bundles"`
}

// JournalPrompt is a guided CBT journal prompt.
type JournalPrompt struct {
	ID        string `json:"id"`
	MonsterID string `json:"monsterId"`
	Premium   bool   `json:"premium"`
}

// Meditation is a guided meditation session.
type Meditation struct {
	ID              string `json:"id"`
	TargetMonsterID string `json:"targetMonsterId"`
	Premium         bool   `json:"premium"`
}

// BettermeLesson is one Better Me session.
type BettermeLesson struct {
	ID    string `json:"id"`
	Level int    `json:"level"`
}

// Betterme is the Better Me programme.
type Betterme struct {
	PremiumFromLevel int              `json:"premiumFromLevel"`
	Lessons          []BettermeLesson `json:"lessons"`
}

// Catalog is the parsed catalog.json with prices resolved.
type Catalog struct {
	Version          string            `json:"version"`
	Comment          string            `json:"_comment"`
	Monsters         []Monster         `json:"monsters"`
	MonsterCosmetics []MonsterCosmetic `json:"monsterCosmetics"`
	PersonalityTests []string          `json:"personalityTests"`
	Accessories      []Accessory       `json:"accessories"`
	AccessoryBundles []AccessoryBundle `json:"accessoryBundles"`
	CardStyles       []CardStyle       `json:"cardStyles"`
	FocusPacks       []FocusPack       `json:"focusPacks"`
	AppBeku          AppBeku           `json:"appbeku"`
	JournalPrompts   []JournalPrompt   `json:"journalPrompts"`
	Meditations      []Meditation      `json:"meditations"`
	Betterme         Betterme          `json:"betterme"`

	discountPercent int
	rounding        int

	monsters     map[string]Monster
	cosmetics    map[string]MonsterCosmetic
	accessories  map[string]Accessory
	bundles      map[string]AccessoryBundle
	cardStyles   map[string]CardStyle
	focusPacks   map[string]FocusPack
	appbekuApps  map[string]AppBekuApp
	appbekuUnits map[int]AppBekuUnit
	appbekuBunds map[string]AppBekuBundle
	prompts      map[string]JournalPrompt
	meditations  map[string]Meditation
	lessons      map[string]BettermeLesson
	tests        map[string]bool
	lessonsByLvl map[int][]string
}

// Load parses the embedded catalog and resolves prices from e.
func Load(e economy.Props) (*Catalog, error) { return parse(raw, e) }

// MustLoad is Load for start-up.
func MustLoad(e economy.Props) *Catalog {
	c, err := Load(e)
	if err != nil {
		panic(err)
	}
	return c
}

func parse(b []byte, e economy.Props) (*Catalog, error) {
	var c Catalog
	dec := json.NewDecoder(bytes.NewReader(b))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&c); err != nil {
		return nil, fmt.Errorf("catalog.json: %w", err)
	}
	if err := c.index(e); err != nil {
		return nil, fmt.Errorf("catalog.json: %w", err)
	}
	return &c, nil
}

func tierPrices(s economy.Spend) map[string]int {
	return map[string]int{
		"cosmeticCommon": s.CosmeticCommon, "cosmeticEpic": s.CosmeticEpic, "cosmeticLegendary": s.CosmeticLegendary,
		"accessorySmall": s.AccessorySmall, "accessoryRegular": s.AccessoryRegular, "accessoryRare": s.AccessoryRare,
		"cardStyleRegular": s.CardStyleRegular, "cardStyleRare": s.CardStyleRare,
		"focus25": s.Focus25, "focusBundle5": s.FocusBundle5,
	}
}

var monsterSlots = map[string]bool{"head": true, "neck": true, "base": true, "side": true, "none": true}
var accessorySlots = map[string]bool{"head": true, "face": true, "neck": true, "back": true}

func (c *Catalog) index(e economy.Props) error {
	var errs []error
	fail := func(format string, a ...any) { errs = append(errs, fmt.Errorf(format, a...)) }
	prices := tierPrices(e.Spend)
	price := func(tier, what string) int {
		p, ok := prices[tier]
		if !ok {
			fail("%s: unknown priceTier %q", what, tier)
		}
		return p
	}
	c.discountPercent, c.rounding = e.Spend.BundleDiscountPercent, e.Spend.BundleRounding
	if c.Version == "" {
		fail("version is required")
	}

	c.monsters = map[string]Monster{}
	for _, m := range c.Monsters {
		if m.Family != "saboteur" && m.Family != "habit" {
			fail("monster %s: bad family %q", m.ID, m.Family)
		}
		c.monsters[m.ID] = m
	}
	c.tests = map[string]bool{}
	for _, t := range c.PersonalityTests {
		c.tests[t] = true
	}

	seen := map[string]bool{}
	unique := func(id string) {
		if seen[id] {
			fail("duplicate inventory id %q", id)
		}
		seen[id] = true
	}

	c.cosmetics = map[string]MonsterCosmetic{}
	for i := range c.MonsterCosmetics {
		m := &c.MonsterCosmetics[i]
		m.Price = price(m.PriceTier, m.ID)
		if _, ok := c.monsters[m.MonsterID]; !ok {
			fail("cosmetic %s: unknown monster %q", m.ID, m.MonsterID)
		}
		if !monsterSlots[m.Slot] {
			fail("cosmetic %s: bad slot %q", m.ID, m.Slot)
		}
		unique(m.ID)
		c.cosmetics[m.ID] = *m
	}
	c.accessories = map[string]Accessory{}
	for i := range c.Accessories {
		a := &c.Accessories[i]
		a.Price = price(a.PriceTier, a.ID)
		if !accessorySlots[a.Slot] {
			fail("accessory %s: bad slot %q", a.ID, a.Slot)
		}
		if a.ExclusiveTo != nil && !c.tests[*a.ExclusiveTo] {
			fail("accessory %s: unknown test %q", a.ID, *a.ExclusiveTo)
		}
		unique(a.InventoryID())
		c.accessories[a.ID] = *a
	}
	c.bundles = map[string]AccessoryBundle{}
	for _, b := range c.AccessoryBundles {
		if len(b.Items) < 2 {
			fail("bundle %s: needs at least 2 items", b.ID)
		}
		for _, it := range b.Items {
			a, ok := c.accessories[it]
			if !ok {
				fail("bundle %s: unknown accessory %q", b.ID, it)
				continue
			}
			if b.ExclusiveTo != nil && !a.AvailableFor(*b.ExclusiveTo) {
				fail("bundle %s: %s is not available for %s", b.ID, it, *b.ExclusiveTo)
			}
		}
		c.bundles[b.ID] = b
	}
	c.cardStyles = map[string]CardStyle{}
	for i := range c.CardStyles {
		s := &c.CardStyles[i]
		if s.PriceTier != nil {
			s.Price = price(*s.PriceTier, s.ID)
		}
		unique(s.InventoryID())
		c.cardStyles[s.ID] = *s
	}
	c.focusPacks = map[string]FocusPack{}
	for i := range c.FocusPacks {
		f := &c.FocusPacks[i]
		f.Price = price(f.PriceTier, f.ID)
		if f.Sessions < 1 {
			fail("focus pack %s: sessions must be >= 1", f.ID)
		}
		c.focusPacks[f.ID] = *f
	}
	c.indexAppBeku(e.AppBeku, fail)
	c.prompts = map[string]JournalPrompt{}
	for _, p := range c.JournalPrompts {
		if _, ok := c.monsters[p.MonsterID]; !ok {
			fail("prompt %s: unknown monster %q", p.ID, p.MonsterID)
		}
		c.prompts[p.ID] = p
	}
	c.meditations = map[string]Meditation{}
	for _, m := range c.Meditations {
		if _, ok := c.monsters[m.TargetMonsterID]; !ok {
			fail("meditation %s: unknown monster %q", m.ID, m.TargetMonsterID)
		}
		c.meditations[m.ID] = m
	}
	c.lessons = map[string]BettermeLesson{}
	c.lessonsByLvl = map[int][]string{}
	for _, l := range c.Betterme.Lessons {
		if l.Level < 1 {
			fail("lesson %s: bad level", l.ID)
		}
		c.lessons[l.ID] = l
		c.lessonsByLvl[l.Level] = append(c.lessonsByLvl[l.Level], l.ID)
	}
	if c.Betterme.PremiumFromLevel < 2 {
		fail("betterme.premiumFromLevel must be >= 2 (level 1 is always free)")
	}
	return errors.Join(errs...)
}

func (c *Catalog) indexAppBeku(e economy.AppBeku, fail func(string, ...any)) {
	prices := map[string]int{"unlock10": e.Unlock10, "unlock20": e.Unlock20, "unlock30": e.Unlock30,
		"unlock60": e.Unlock60, "bundleSantai": e.BundleSantai, "bundleSosmed": e.BundleSosmed}
	price := func(tier, what string) int {
		p, ok := prices[tier]
		if !ok {
			fail("appbeku %s: unknown priceTier %q", what, tier)
		}
		return p
	}
	a := &c.AppBeku
	c.appbekuApps = map[string]AppBekuApp{}
	groups := map[string]int{}
	for _, app := range a.Apps {
		if app.ID == "" || app.Group == "" {
			fail("appbeku app %q: id and group are required", app.ID)
		}
		if _, dup := c.appbekuApps[app.ID]; dup {
			fail("appbeku app %q: duplicate", app.ID)
		}
		c.appbekuApps[app.ID] = app
		groups[app.Group]++
	}
	c.appbekuUnits = map[int]AppBekuUnit{}
	for i := range a.Units {
		u := &a.Units[i]
		u.Price = price(u.PriceTier, fmt.Sprintf("unit %d", u.Minutes))
		if u.Minutes < 1 {
			fail("appbeku unit: minutes must be >= 1")
		}
		c.appbekuUnits[u.Minutes] = *u
	}
	c.appbekuBunds = map[string]AppBekuBundle{}
	for i := range a.Bundles {
		b := &a.Bundles[i]
		b.Price = price(b.PriceTier, "bundle "+b.ID)
		switch {
		case len(b.Apps) > 0 && b.Group == "":
			for _, g := range b.Apps {
				if _, ok := c.appbekuApps[g.AppID]; !ok || g.Minutes < 1 {
					fail("appbeku bundle %s: bad app %q", b.ID, g.AppID)
				}
			}
		case len(b.Apps) == 0 && groups[b.Group] > 0 && b.MinutesPerApp > 0:
		default:
			fail("appbeku bundle %s: needs either apps or a known group with minutesPerApp", b.ID)
		}
		c.appbekuBunds[b.ID] = *b
	}
}

// Lookups.

func (c *Catalog) Monster(id string) (Monster, bool) { m, ok := c.monsters[id]; return m, ok }
func (c *Catalog) PersonalityTest(id string) bool    { return c.tests[id] }
func (c *Catalog) MonsterCosmetic(id string) (MonsterCosmetic, bool) {
	m, ok := c.cosmetics[id]
	return m, ok
}
func (c *Catalog) Accessory(id string) (Accessory, bool)    { a, ok := c.accessories[id]; return a, ok }
func (c *Catalog) Bundle(id string) (AccessoryBundle, bool) { b, ok := c.bundles[id]; return b, ok }
func (c *Catalog) CardStyle(id string) (CardStyle, bool)    { s, ok := c.cardStyles[id]; return s, ok }
func (c *Catalog) FocusPack(id string) (FocusPack, bool)    { f, ok := c.focusPacks[id]; return f, ok }
func (c *Catalog) AppBekuApp(id string) (AppBekuApp, bool)  { a, ok := c.appbekuApps[id]; return a, ok }
func (c *Catalog) AppBekuUnit(minutes int) (AppBekuUnit, bool) {
	u, ok := c.appbekuUnits[minutes]
	return u, ok
}
func (c *Catalog) AppBekuBundle(id string) (AppBekuBundle, bool) {
	b, ok := c.appbekuBunds[id]
	return b, ok
}
func (c *Catalog) JournalPrompt(id string) (JournalPrompt, bool) {
	p, ok := c.prompts[id]
	return p, ok
}
func (c *Catalog) Meditation(id string) (Meditation, bool) { m, ok := c.meditations[id]; return m, ok }
func (c *Catalog) BettermeLesson(id string) (BettermeLesson, bool) {
	l, ok := c.lessons[id]
	return l, ok
}

// LessonsOfLevel returns the lesson ids of a Better Me level.
func (c *Catalog) LessonsOfLevel(level int) []string { return c.lessonsByLvl[level] }

// Cosmetic is any single purchasable look, identified by its inventory id.
type Cosmetic struct {
	InventoryID string
	Kind        string // monster | accessory | card_style
	Price       int
}

// CosmeticByInventoryID resolves a monster cosmetic id, "acc_<id>" or
// "cardstyle_<id>". Free card styles are not purchasable.
func (c *Catalog) CosmeticByInventoryID(id string) (Cosmetic, bool) {
	if m, ok := c.cosmetics[id]; ok {
		return Cosmetic{InventoryID: id, Kind: "monster", Price: m.Price}, true
	}
	if len(id) > len(AccessoryPrefix) && id[:len(AccessoryPrefix)] == AccessoryPrefix {
		if a, ok := c.accessories[id[len(AccessoryPrefix):]]; ok {
			return Cosmetic{InventoryID: id, Kind: "accessory", Price: a.Price}, true
		}
	}
	if len(id) > len(CardStylePrefix) && id[:len(CardStylePrefix)] == CardStylePrefix {
		if s, ok := c.cardStyles[id[len(CardStylePrefix):]]; ok && !s.Free() {
			return Cosmetic{InventoryID: id, Kind: "card_style", Price: s.Price}, true
		}
	}
	return Cosmetic{}, false
}

// BundlePrice prices a bundle from the items the user does not own yet:
// their full price minus the bundle discount, rounded half away from zero to
// the rounding step (same formula as the app's AccessoryBundle.price).
func (c *Catalog) BundlePrice(b AccessoryBundle, owned map[string]bool) (price int, missing []string) {
	full := 0
	for _, it := range b.Items {
		a := c.accessories[it]
		if owned[a.InventoryID()] {
			continue
		}
		missing = append(missing, a.InventoryID())
		full += a.Price
	}
	if full == 0 {
		return 0, nil
	}
	discounted := float64(full) * float64(100-c.discountPercent) / 100
	step := float64(c.rounding)
	return int(math.Round(discounted/step) * step), missing
}
