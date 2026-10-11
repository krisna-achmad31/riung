package rules

import (
	"context"
	"sort"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Shop item types (docs/backend-api-spec.md §3.6).
const (
	ItemCosmetic       = "cosmetic"
	ItemCosmeticBundle = "cosmetic_bundle"
	ItemStreakShield   = "streak_shield"
	ItemFocusPack      = "focus_pack"
)

// PurchaseInput is a coin purchase request.
type PurchaseInput struct {
	ItemType      string `json:"itemType"`
	ItemID        string `json:"itemId"`
	ExpectedPrice int    `json:"expectedPrice"`
}

// PurchaseResult describes what was bought.
type PurchaseResult struct {
	ItemType     string   `json:"itemType"`
	ItemID       string   `json:"itemId"`
	Price        int      `json:"price"`
	Granted      []string `json:"granted"`
	StreakShield *int     `json:"streakShields,omitempty"`
	PrepaidFocus *int     `json:"prepaidFocus,omitempty"`
}

// Purchase spends coins on a catalog item. idemKey (the request's
// Idempotency-Key) keys the ledger row. The client's expectedPrice must match
// the server price, so a price change never charges an unexpected amount.
func (s *Service) Purchase(ctx context.Context, user store.User, in PurchaseInput, idemKey string) (PurchaseResult, store.Wallet, error) {
	res := PurchaseResult{ItemType: in.ItemType, ItemID: in.ItemID, Granted: []string{}}
	var wallet store.Wallet
	err := s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		debit := func(price int, reason string) error {
			if in.ExpectedPrice != price {
				return &PriceChangedError{Price: price}
			}
			res.Price = price
			return tx.Debit(store.Debit{Amount: price, Reason: reason, Ref: in.ItemID, Key: "shop:" + idemKey})
		}
		switch in.ItemType {
		case ItemCosmetic:
			c, ok := s.Catalog.CosmeticByInventoryID(in.ItemID)
			if !ok {
				return ErrNotFound
			}
			owned, err := tx.Inventory()
			if err != nil {
				return err
			}
			if owned[c.InventoryID] {
				return ErrAlreadyOwned
			}
			if err := debit(c.Price, "cosmetic"); err != nil {
				return err
			}
			res.Granted = []string{c.InventoryID}
			if err := tx.AddInventory(res.Granted, "shop"); err != nil {
				return err
			}

		case ItemCosmeticBundle:
			b, ok := s.Catalog.Bundle(in.ItemID)
			if !ok {
				return ErrNotFound
			}
			owned, err := tx.Inventory()
			if err != nil {
				return err
			}
			price, missing := s.Catalog.BundlePrice(b, owned)
			if len(missing) == 0 {
				return ErrAlreadyOwned
			}
			if err := debit(price, "cosmetic_bundle"); err != nil {
				return err
			}
			sort.Strings(missing)
			res.Granted = missing
			if err := tx.AddInventory(missing, "bundle"); err != nil {
				return err
			}

		case ItemStreakShield:
			if in.ItemID != ItemStreakShield {
				return ErrNotFound
			}
			if err := debit(s.Economy.Spend.StreakShield, "streak_shield"); err != nil {
				return err
			}
			n, err := tx.AddConsumable(store.ConsumableStreakShield, 1)
			if err != nil {
				return err
			}
			res.StreakShield = &n

		case ItemFocusPack:
			f, ok := s.Catalog.FocusPack(in.ItemID)
			if !ok {
				return ErrNotFound
			}
			if err := debit(f.Price, "focus_pack"); err != nil {
				return err
			}
			n, err := tx.AddConsumable(store.ConsumablePrepaidFocus, f.Sessions)
			if err != nil {
				return err
			}
			res.PrepaidFocus = &n

		default:
			return invalid("itemType", "itemType must be cosmetic, cosmetic_bundle, streak_shield or focus_pack")
		}
		wallet = tx.Wallet()
		return nil
	})
	return res, wallet, err
}

// --- loadouts ------------------------------------------------------------------------

// SetMonsterLoadout replaces what monster saboteurID wears: owned monster
// cosmetics wearable by that monster, at most one per slot.
func (s *Service) SetMonsterLoadout(ctx context.Context, user store.User, saboteurID string, items []string) ([]string, error) {
	if _, ok := s.Catalog.Monster(saboteurID); !ok {
		return nil, ErrNotFound
	}
	slots := map[string]bool{}
	for _, id := range items {
		c, ok := s.Catalog.MonsterCosmetic(id)
		if !ok {
			return nil, invalid("items", "unknown monster cosmetic "+id)
		}
		if c.Exclusive && c.MonsterID != saboteurID {
			return nil, invalid("items", id+" can only be worn by "+c.MonsterID)
		}
		if slots[c.Slot] {
			return nil, invalid("items", "only one item per slot ("+c.Slot+")")
		}
		slots[c.Slot] = true
	}
	items = append([]string{}, items...)
	sort.Strings(items)
	err := s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		owned, err := tx.Inventory()
		if err != nil {
			return err
		}
		for _, id := range items {
			if !owned[id] {
				return ErrNotOwned
			}
		}
		return tx.SetMonsterLoadout(saboteurID, items)
	})
	return items, err
}

// CharacterLoadoutInput is what a personality character wears.
type CharacterLoadoutInput struct {
	Accessories []string `json:"accessories"`
	CardStyle   *string  `json:"cardStyle"`
}

// SetCharacterLoadout replaces a character's accessories (owned, available
// for that test, one per slot) and card style (free, owned, or any style
// while Premium is active).
func (s *Service) SetCharacterLoadout(ctx context.Context, user store.User, testID string, in CharacterLoadoutInput) (CharacterLoadoutInput, error) {
	if !s.Catalog.PersonalityTest(testID) {
		return in, ErrNotFound
	}
	slots := map[string]bool{}
	var style catalog.CardStyle
	for _, id := range in.Accessories {
		a, ok := s.Catalog.Accessory(id)
		if !ok {
			return in, invalid("accessories", "unknown accessory "+id)
		}
		if !a.AvailableFor(testID) {
			return in, invalid("accessories", id+" is exclusive to another character")
		}
		if slots[a.Slot] {
			return in, invalid("accessories", "only one accessory per slot ("+a.Slot+")")
		}
		slots[a.Slot] = true
	}
	if in.CardStyle != nil {
		var ok bool
		if style, ok = s.Catalog.CardStyle(*in.CardStyle); !ok {
			return in, invalid("cardStyle", "unknown card style")
		}
	}
	out := CharacterLoadoutInput{Accessories: append([]string{}, in.Accessories...), CardStyle: in.CardStyle}
	sort.Strings(out.Accessories)
	err := s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		owned, err := tx.Inventory()
		if err != nil {
			return err
		}
		for _, id := range out.Accessories {
			a, _ := s.Catalog.Accessory(id)
			if !owned[a.InventoryID()] {
				return ErrNotOwned
			}
		}
		if in.CardStyle != nil && !style.Free() && !owned[style.InventoryID()] {
			prem, err := s.premium(tx)
			if err != nil {
				return err
			}
			if !prem.Active() {
				return ErrPremiumRequired
			}
		}
		return tx.SetCharacterLoadout(testID, out.Accessories, out.CardStyle)
	})
	return out, err
}

// --- premium daily coins --------------------------------------------------------------

// DailyCoinsResult is the outcome of a claim.
type DailyCoinsResult struct {
	CoinsGranted int    `json:"coinsGranted"`
	Capped       bool   `json:"capped"`
	CapReason    string `json:"capReason,omitempty"`
	Date         string `json:"date"`
}

// ClaimPremiumDaily grants the yearly-plan daily coins once per local day.
// They go to the purchased bucket, so they cannot pay for Aplikasi Beku
// unlocks (CLAUDE.md ethical guard). Missed days do not accumulate.
func (s *Service) ClaimPremiumDaily(ctx context.Context, user store.User) (DailyCoinsResult, store.Wallet, error) {
	day := LocalDay(s.Now(), user.TZ)
	res := DailyCoinsResult{Date: day.Format(time.DateOnly)}
	var wallet store.Wallet
	err := s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		prem, err := s.premium(tx)
		if err != nil {
			return err
		}
		if !prem.Yearly() {
			return ErrPremiumRequired
		}
		n, err := tx.IncCounter(day, store.CounterPremiumDaily, 1)
		if err != nil {
			return err
		}
		if n > 1 {
			res.Capped, res.CapReason = true, CapDaily
		} else {
			amount := s.Economy.Premium.YearlyDailyCoins
			if _, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketPurchased, Amount: amount,
				Reason: "premium_daily", Ref: res.Date, Key: "premium_daily:" + res.Date}); err != nil {
				return err
			}
			res.CoinsGranted = amount
		}
		wallet = tx.Wallet()
		return nil
	})
	return res, wallet, err
}
