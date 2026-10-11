// Package economy holds every economy number the server uses (prices,
// rewards, caps), loaded from the embedded economy-props.json — a byte-for-byte
// copy of docs/economy-props.json (see economy_test.go). Handlers never use
// numeric literals for economy values.
package economy

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
)

//go:embed economy-props.json
var raw []byte

// Props mirrors docs/economy-props.json.
type Props struct {
	Version         string          `json:"version"`
	Comment         string          `json:"_comment"`
	Earn            Earn            `json:"earn"`
	MonsterProgress MonsterProgress `json:"monsterProgress"`
	Spend           Spend           `json:"spend"`
	AppBeku         AppBeku         `json:"appbeku"`
	Tickets         Tickets         `json:"tickets"`
	FreeTier        FreeTier        `json:"freeTier"`
	Premium         Premium         `json:"premium"`
	CoinPacks       []CoinPack      `json:"coinPacks"`
	Caps            Caps            `json:"caps"`
}

type Earn struct {
	Checkin            int `json:"checkin"`
	Journal            int `json:"journal"`
	Meditation         int `json:"meditation"`
	Mission            int `json:"mission"`
	MinigameWin        int `json:"minigameWin"`
	MonsterTamed       int `json:"monsterTamed"`
	BettermeLesson     int `json:"bettermeLesson"`
	Streak7            int `json:"streak7"`
	Streak30           int `json:"streak30"`
	PremiumYearlyDaily int `json:"premiumYearlyDaily"`
}

type MonsterProgress struct {
	Focus         int `json:"focus"`
	MinigameWin   int `json:"minigameWin"`
	MinigameLose  int `json:"minigameLose"`
	JournalPrompt int `json:"journalPrompt"`
	Meditation    int `json:"meditation"`
}

type Spend struct {
	Focus25               int `json:"focus25"`
	Focus45               int `json:"focus45"`
	Focus60               int `json:"focus60"`
	FocusBundle5          int `json:"focusBundle5"`
	StreakShield          int `json:"streakShield"`
	CosmeticCommon        int `json:"cosmeticCommon"`
	CosmeticEpic          int `json:"cosmeticEpic"`
	CosmeticLegendary     int `json:"cosmeticLegendary"`
	AccessorySmall        int `json:"accessorySmall"`
	AccessoryRegular      int `json:"accessoryRegular"`
	AccessoryRare         int `json:"accessoryRare"`
	CardStyleRegular      int `json:"cardStyleRegular"`
	CardStyleRare         int `json:"cardStyleRare"`
	BundleDiscountPercent int `json:"bundleDiscountPercent"`
	BundleRounding        int `json:"bundleRounding"`
}

type AppBeku struct {
	Unlock10              int `json:"unlock10"`
	Unlock20              int `json:"unlock20"`
	Unlock30              int `json:"unlock30"`
	Unlock60              int `json:"unlock60"`
	BundleSantai          int `json:"bundleSantai"`
	BundleSosmed          int `json:"bundleSosmed"`
	MaxPaidUnlocksPerDay  int `json:"maxPaidUnlocksPerDay"`
	EscalationPerUnlock   int `json:"escalationPerUnlock"`
	UnlockCooldownSeconds int `json:"unlockCooldownSeconds"`
}

type Tickets struct {
	FreePerDay            int `json:"freePerDay"`
	MaxFromPracticePerDay int `json:"maxFromPracticePerDay"`
	MaxFightsPerDay       int `json:"maxFightsPerDay"`
}

type FreeTier struct {
	Meditations    int `json:"meditations"`
	SleepStories   int `json:"sleepStories"`
	JournalPerDay  int `json:"journalPerDay"`
	MinigamePerDay int `json:"minigamePerDay"`
	FocusPerDay    int `json:"focusPerDay"`
}

type Premium struct {
	MonthlyPriceIdr   int `json:"monthlyPriceIdr"`
	MonthsPaidPerYear int `json:"monthsPaidPerYear"`
	YearlyPriceIdr    int `json:"yearlyPriceIdr"`
	TrialDays         int `json:"trialDays"`
	FocusFreePerDay   int `json:"focusFreePerDay"`
	YearlyDailyCoins  int `json:"yearlyDailyCoins"`
	GraceDays         int `json:"graceDays"`
}

type CoinPack struct {
	ProductID string `json:"productId"`
	Coins     int    `json:"coins"`
	Bonus     int    `json:"bonus"`
	PriceIdr  int    `json:"priceIdr"`
}

// Caps are daily limits. JournalRewardsPerDay, MeditationRewardsPerDay and
// NewAccountsPerIpPerDay are defaults that an admin can override at runtime
// (app_settings).
type Caps struct {
	MissionsPerDay          int `json:"missionsPerDay"`
	JournalRewardsPerDay    int `json:"journalRewardsPerDay"`
	MeditationRewardsPerDay int `json:"meditationRewardsPerDay"`
	NewAccountsPerIpPerDay  int `json:"newAccountsPerIpPerDay"`
}

// Load parses and validates the embedded props.
func Load() (Props, error) {
	return parse(raw)
}

// MustLoad is Load for program start-up: a broken embedded file is a build bug.
func MustLoad() Props {
	p, err := Load()
	if err != nil {
		panic(err)
	}
	return p
}

func parse(b []byte) (Props, error) {
	var p Props
	dec := json.NewDecoder(bytes.NewReader(b))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&p); err != nil {
		return Props{}, fmt.Errorf("economy-props.json: %w", err)
	}
	if err := p.validate(); err != nil {
		return Props{}, fmt.Errorf("economy-props.json: %w", err)
	}
	return p, nil
}

// validate rejects missing (zero) or negative numbers so a typo in the JSON
// cannot silently make something free.
func (p Props) validate() error {
	var errs []error
	if p.Version == "" {
		errs = append(errs, errors.New("version is required"))
	}
	for _, section := range []any{p.Earn, p.MonsterProgress, p.Spend, p.AppBeku, p.Tickets, p.FreeTier, p.Premium, p.Caps} {
		v := reflect.ValueOf(section)
		for i := 0; i < v.NumField(); i++ {
			if n := v.Field(i).Int(); n <= 0 {
				errs = append(errs, fmt.Errorf("%s.%s must be > 0, got %d", v.Type().Name(), v.Type().Field(i).Name, n))
			}
		}
	}
	if len(p.CoinPacks) == 0 {
		errs = append(errs, errors.New("coinPacks is empty"))
	}
	for _, c := range p.CoinPacks {
		if c.ProductID == "" || c.Coins <= 0 || c.Bonus < 0 || c.PriceIdr <= 0 {
			errs = append(errs, fmt.Errorf("invalid coin pack %+v", c))
		}
	}
	if p.Premium.YearlyPriceIdr != p.Premium.MonthlyPriceIdr*p.Premium.MonthsPaidPerYear {
		errs = append(errs, errors.New("premium.yearlyPriceIdr must equal monthlyPriceIdr × monthsPaidPerYear"))
	}
	return errors.Join(errs...)
}
