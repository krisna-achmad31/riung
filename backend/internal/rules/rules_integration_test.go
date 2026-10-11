package rules_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/rules"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

// Fixed "now": 2026-10-12 10:00 in Jakarta.
var base = time.Date(2026, 10, 12, 3, 0, 0, 0, time.UTC)

type fixture struct {
	t    *testing.T
	svc  *rules.Service
	st   *store.Store
	user store.User
	now  time.Time
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	st := store.New(testdb.Pool(t))
	e := economy.MustLoad()
	f := &fixture{t: t, st: st, now: base}
	f.svc = &rules.Service{Store: st, Economy: e, Catalog: catalog.MustLoad(e),
		Settings: settings.NewCache(st, e.Caps, 0, func() time.Time { return f.now }), Now: func() time.Time { return f.now }}
	u, _, err := st.ResolveUser(context.Background(), store.ResolveParams{Provider: "firebase", Subject: t.Name(), Create: true,
		IPHash: "ip", Day: base, SignupLimit: 1000})
	if err != nil {
		t.Fatal(err)
	}
	f.user = u
	return f
}

func (f *fixture) act(in rules.ActivityInput) rules.ActivityResult {
	f.t.Helper()
	if in.OccurredAt.IsZero() {
		in.OccurredAt = f.now
	}
	res, _, err := f.svc.ApplyActivity(context.Background(), f.user, in)
	if err != nil {
		f.t.Fatalf("%s: %v", in.Type, err)
	}
	return res
}

func (f *fixture) coins() store.Wallet {
	f.t.Helper()
	w, err := f.st.Wallet(context.Background(), f.user.ID)
	if err != nil {
		f.t.Fatal(err)
	}
	return w
}

func (f *fixture) premium(plan string) {
	f.t.Helper()
	exp := f.now.Add(30 * 24 * time.Hour)
	if err := f.st.UpsertSubscription(context.Background(), f.user.ID, store.Subscription{Plan: plan, Status: "active", ExpiresAt: &exp}, nil); err != nil {
		f.t.Fatal(err)
	}
}

func day(n int) string { return base.AddDate(0, 0, n).Format(time.DateOnly) }

func ptr[T any](v T) *T { return &v }

func checkin(f *fixture, offset int) rules.ActivityResult {
	f.now = base.AddDate(0, 0, offset)
	return f.act(rules.ActivityInput{Type: rules.TypeCheckin, Date: day(offset)})
}

func TestCheckinStreakShieldAndMilestone(t *testing.T) {
	f := newFixture(t)
	r := checkin(f, 0)
	if r.CoinsGranted != 5 || r.Streak.Current != 1 {
		t.Fatalf("first check-in: %+v", r)
	}
	if again := f.act(rules.ActivityInput{Type: rules.TypeCheckin, Date: day(0)}); !again.Replayed || again.CoinsGranted != 5 || f.coins().Coins() != 5 {
		t.Fatalf("replay must not pay twice: %+v wallet=%d", again, f.coins().Coins())
	}
	for i := 1; i <= 5; i++ {
		checkin(f, i)
	}
	// Day 6 missed, day 7 without a shield: streak resets.
	if r := checkin(f, 7); r.Streak.Current != 1 || r.Streak.Longest != 6 {
		t.Fatalf("missed day without shield must reset: %+v", r.Streak)
	}
	// Buy a shield (enough coins by now), miss day 8, check in day 9.
	if _, _, err := f.svc.Purchase(context.Background(), f.user, rules.PurchaseInput{ItemType: "streak_shield", ItemID: "streak_shield", ExpectedPrice: 20}, "k-shield"); err != nil {
		t.Fatal(err)
	}
	if r := checkin(f, 9); !r.Streak.ShieldUsed || r.Streak.Current != 2 {
		t.Fatalf("shield must bridge one missed day: %+v", r.Streak)
	}
	// Two missed days are too many even with shields left.
	if r := checkin(f, 12); r.Streak.Current != 1 || r.Streak.ShieldUsed {
		t.Fatalf("two missed days: %+v", r.Streak)
	}
	// Seven consecutive days pay the milestone once.
	var milestone rules.ActivityResult
	for i := 13; i <= 18; i++ {
		milestone = checkin(f, i)
	}
	if milestone.Streak.Current != 7 || milestone.Streak.MilestoneBonus != 20 || milestone.CoinsGranted != 25 {
		t.Fatalf("7-day milestone: %+v", milestone)
	}
	// A late offline report for an older, missed day (day 11) pays the
	// check-in but does not rewrite the current streak.
	late := f.act(rules.ActivityInput{Type: rules.TypeCheckin, Date: day(11), OccurredAt: base.AddDate(0, 0, 11)})
	if late.Replayed || late.CoinsGranted != 5 || late.Streak.Current != 7 || late.Streak.ShieldUsed {
		t.Fatalf("late report: %+v %+v", late, late.Streak)
	}
}

func TestCheckinCannotBackfillOldDays(t *testing.T) {
	f := newFixture(t)
	checkin(f, 0)
	// Day 1 and 2 missed; on day 3 the client reports day 1 and day 2 late.
	f.now = base.AddDate(0, 0, 3)
	r1 := f.act(rules.ActivityInput{Type: rules.TypeCheckin, Date: day(1), OccurredAt: base.AddDate(0, 0, 1)})
	if r1.CoinsGranted != 5 || r1.Streak.Current != 1 {
		t.Fatalf("a check-in older than yesterday pays but must not extend the streak: %+v %+v", r1, r1.Streak)
	}
	// Yesterday (day 2) still counts: offline late at night, synced this morning.
	r2 := f.act(rules.ActivityInput{Type: rules.TypeCheckin, Date: day(2), OccurredAt: base.AddDate(0, 0, 2)})
	if r2.Streak.Current != 1 {
		// day 0 → day 2 is a gap of 2 with no shield: the streak restarts at 1.
		t.Fatalf("yesterday: %+v", r2.Streak)
	}
	if r3 := checkin(f, 3); r3.Streak.Current != 2 {
		t.Fatalf("today after yesterday: %+v", r3.Streak)
	}
}

func TestEventWindowAndDates(t *testing.T) {
	f := newFixture(t)
	_, _, err := f.svc.ApplyActivity(context.Background(), f.user, rules.ActivityInput{Type: rules.TypeCheckin, Date: day(-8), OccurredAt: base.AddDate(0, 0, -8)})
	var v *rules.ValidationError
	if !errors.As(err, &v) || v.Field != "occurredAt" {
		t.Fatalf("events older than 7 days must be rejected: %v", err)
	}
	_, _, err = f.svc.ApplyActivity(context.Background(), f.user, rules.ActivityInput{Type: rules.TypeCheckin, Date: day(1), OccurredAt: base})
	if !errors.As(err, &v) || v.Field != "date" {
		t.Fatalf("date must match occurredAt's local date: %v", err)
	}
	_, _, err = f.svc.ApplyActivity(context.Background(), f.user, rules.ActivityInput{Type: rules.TypeFocusComplete, OccurredAt: base})
	if !errors.As(err, &v) {
		t.Fatalf("focus_completed is not available yet: %v", err)
	}
}

func TestJournalFreeLimitPremiumAndCap(t *testing.T) {
	f := newFixture(t)
	r := f.act(rules.ActivityInput{Type: rules.TypeJournalSaved, EntryID: "e1", PromptID: "p_hakim"})
	if r.CoinsGranted != 4 || r.Monster == nil || r.Monster.SaboteurID != "hakim" || r.Monster.Progress != 2 {
		t.Fatalf("first entry: %+v", r)
	}
	// Free users: one entry per day earns anything.
	if r := f.act(rules.ActivityInput{Type: rules.TypeJournalSaved, EntryID: "e2"}); !r.Capped || r.CapReason != rules.CapFreeDailyLimit || r.CoinsGranted != 0 {
		t.Fatalf("second free entry: %+v", r)
	}
	acc, err := f.svc.JournalAccessFor(context.Background(), f.user, "")
	if err != nil || acc.CanWrite || acc.Reason == nil || *acc.Reason != rules.ReasonDailyLimit || acc.EntriesToday != 2 || len(acc.Prompts) != 5 {
		t.Fatalf("journal access after limit: %+v %v", acc, err)
	}
	// Premium: unlimited entries, but coins stop at journalRewardsPerDay (3).
	f.premium("premium_monthly")
	got := 0
	for i := 3; i <= 6; i++ {
		got += f.act(rules.ActivityInput{Type: rules.TypeJournalSaved, EntryID: fmt.Sprintf("e%d", i)}).CoinsGranted
	}
	if got != 8 { // entries 3 and 4 pay (slots 2 and 3), 5 and 6 are capped
		t.Fatalf("premium journal rewards: %d", got)
	}
	acc, _ = f.svc.JournalAccessFor(context.Background(), f.user, "p_waswas")
	if !acc.CanWrite || !acc.Premium || acc.RewardedToday != 3 || len(acc.Prompts) != 1 {
		t.Fatalf("premium access: %+v", acc)
	}
	// An admin raising the cap takes effect.
	if _, err := f.st.ChangeSetting(context.Background(), store.SettingChange{Key: settings.JournalRewardsPerDay, Value: 5, Actor: "test", Reason: "test"}); err != nil {
		t.Fatal(err)
	}
	if r := f.act(rules.ActivityInput{Type: rules.TypeJournalSaved, EntryID: "e7"}); r.CoinsGranted != 4 {
		t.Fatalf("raised cap: %+v", r)
	}
}

func TestMeditationPremiumAndCap(t *testing.T) {
	f := newFixture(t)
	if r := f.act(rules.ActivityInput{Type: rules.TypeMeditation, SessionID: "body_scan", TargetMonsterID: "hakim"}); !r.Capped || r.CapReason != rules.CapPremium {
		t.Fatalf("premium session for free user: %+v", r)
	}
	r := f.act(rules.ActivityInput{Type: rules.TypeMeditation, SessionID: "jeda_kerja", TargetMonsterID: "hakim"})
	if r.CoinsGranted != 3 || r.Monster.SaboteurID != "waswas" {
		t.Fatalf("the catalog decides the target monster: %+v", r)
	}
	if again := f.act(rules.ActivityInput{Type: rules.TypeMeditation, SessionID: "jeda_kerja"}); !again.Replayed {
		t.Fatal("same session same day is one event")
	}
	f.act(rules.ActivityInput{Type: rules.TypeMeditation, SessionID: "napas_4_7_8"})
	f.act(rules.ActivityInput{Type: rules.TypeMeditation, SessionID: "tenang_ujian"})
	f.now = f.now.Add(time.Minute)
	f.premium("premium_monthly")
	if r := f.act(rules.ActivityInput{Type: rules.TypeMeditation, SessionID: "menonton_pikiran"}); !r.Capped || r.CapReason != rules.CapDaily {
		t.Fatalf("4th rewarded meditation: %+v", r)
	}
}

func TestBettermeLevels(t *testing.T) {
	f := newFixture(t)
	if r := f.act(rules.ActivityInput{Type: rules.TypeBettermeLesson, LessonID: "l2_s1"}); r.CapReason != rules.CapPremium {
		t.Fatalf("level 2 needs premium: %+v", r)
	}
	f.premium("premium_yearly")
	if r := f.act(rules.ActivityInput{Type: rules.TypeBettermeLesson, LessonID: "l2_s2"}); r.CapReason != rules.CapLocked {
		t.Fatalf("level 2 needs level 1 done: %+v", r)
	}
	for i := 1; i <= 7; i++ {
		if r := f.act(rules.ActivityInput{Type: rules.TypeBettermeLesson, LessonID: fmt.Sprintf("l1_s%d", i)}); r.CoinsGranted != 10 {
			t.Fatalf("lesson %d: %+v", i, r)
		}
	}
	if r := f.act(rules.ActivityInput{Type: rules.TypeBettermeLesson, LessonID: "l2_s3"}); r.CoinsGranted != 10 {
		t.Fatalf("unlocked: %+v", r)
	}
}

func TestMissionsAndMinigameTaming(t *testing.T) {
	f := newFixture(t)
	for i := 0; i < 3; i++ {
		if r := f.act(rules.ActivityInput{Type: rules.TypeMission, Date: day(0), Index: ptr(i)}); r.CoinsGranted != 3 {
			t.Fatalf("mission %d: %+v", i, r)
		}
	}
	if _, _, err := f.svc.ApplyActivity(context.Background(), f.user, rules.ActivityInput{Type: rules.TypeMission, Date: day(0), Index: ptr(3), OccurredAt: base}); err == nil {
		t.Fatal("only 3 missions per day")
	}
	snap, _ := f.st.Snapshot(context.Background(), f.user.ID, base)
	if got := store.MissionsDone(snap.Counters); len(got) != 3 {
		t.Fatalf("missions done: %v", got)
	}

	// 4 fights per day; the 5th grants nothing.
	total := 0
	var last rules.ActivityResult
	for i := 0; i < 5; i++ {
		last = f.act(rules.ActivityInput{Type: rules.TypeMinigame, SaboteurID: "kabut", Won: ptr(i%2 == 0), Ref: fmt.Sprintf("00000000-0000-4000-8000-%012d", i)})
		total += last.CoinsGranted
	}
	if !last.Capped || total != 16 { // wins on fights 1 and 3
		t.Fatalf("fight cap: total=%d last=%+v", total, last)
	}

	// Taming: push kabut to 100 over several days; the +50 is paid once.
	tamed := 0
	for d := 1; d <= 30 && tamed == 0; d++ {
		f.now = base.AddDate(0, 0, d)
		for i := 0; i < 4; i++ {
			r := f.act(rules.ActivityInput{Type: rules.TypeMinigame, SaboteurID: "kabut", Won: ptr(true), Ref: fmt.Sprintf("00000000-0000-4000-9%03d-%012d", d, i)})
			if r.Monster.JustTamed {
				tamed++
				if r.Monster.TamedBonus != 50 || r.Monster.Progress != 100 || r.Monster.State != "tamed" {
					t.Fatalf("taming: %+v", r.Monster)
				}
			}
		}
	}
	if tamed != 1 {
		t.Fatalf("taming bonus paid %d times", tamed)
	}
	f.now = f.now.AddDate(0, 0, 1)
	if r := f.act(rules.ActivityInput{Type: rules.TypeMinigame, SaboteurID: "kabut", Won: ptr(true), Ref: "00000000-0000-4000-a000-000000000001"}); r.Monster.JustTamed || r.Monster.TamedBonus != 0 || r.Monster.Progress != 100 {
		t.Fatalf("after taming: %+v", r.Monster)
	}
}

func TestShopPurchases(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	buy := func(key string, in rules.PurchaseInput) (rules.PurchaseResult, error) {
		r, _, err := f.svc.Purchase(ctx, f.user, in, key)
		return r, err
	}
	var short *store.ErrInsufficientCoins
	if _, err := buy("k1", rules.PurchaseInput{ItemType: "cosmetic", ItemID: "topi_rajut", ExpectedPrice: 100}); !errors.As(err, &short) || short.Balance != 0 || short.Required != 100 {
		t.Fatalf("no coins: %v", err)
	}
	// Seed 150 earned + 80 purchased coins directly (billing arrives in B3).
	err := f.st.WithUserTx(ctx, f.user.ID, func(tx *store.UserTx) error {
		if _, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: 150, Reason: "test", Key: "seed-earned"}); err != nil {
			return err
		}
		_, err := tx.Credit(store.Credit{Type: "purchase", Bucket: store.BucketPurchased, Amount: 80, Reason: "test", Key: "seed-bought"})
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	var changed *rules.PriceChangedError
	if _, err := buy("k2", rules.PurchaseInput{ItemType: "cosmetic", ItemID: "topi_rajut", ExpectedPrice: 90}); !errors.As(err, &changed) || changed.Price != 100 {
		t.Fatalf("stale price: %v", err)
	}
	if _, err := buy("k3", rules.PurchaseInput{ItemType: "cosmetic", ItemID: "topi_rajut", ExpectedPrice: 100}); err != nil {
		t.Fatal(err)
	}
	if w := f.coins(); w.PurchasedCoins != 0 || w.EarnedCoins != 130 {
		t.Fatalf("purchased coins are spent first: %+v", w)
	}
	if _, err := buy("k4", rules.PurchaseInput{ItemType: "cosmetic", ItemID: "topi_rajut", ExpectedPrice: 100}); !errors.Is(err, rules.ErrAlreadyOwned) {
		t.Fatalf("owned: %v", err)
	}
	if _, err := buy("k5", rules.PurchaseInput{ItemType: "cosmetic", ItemID: "cardstyle_klasik", ExpectedPrice: 0}); !errors.Is(err, rules.ErrNotFound) {
		t.Fatalf("free style is not for sale: %v", err)
	}
	// Bundle: owning beanie makes cozy cost 95 instead of 145.
	if _, err := buy("k6", rules.PurchaseInput{ItemType: "cosmetic", ItemID: "acc_beanie", ExpectedPrice: 60}); err != nil {
		t.Fatal(err)
	}
	if _, err := buy("k7", rules.PurchaseInput{ItemType: "cosmetic_bundle", ItemID: "cozy", ExpectedPrice: 145}); !errors.As(err, &changed) || changed.Price != 95 {
		t.Fatalf("bundle price must exclude owned items: %v", err)
	}
	f.act(rules.ActivityInput{Type: rules.TypeBettermeLesson, LessonID: "l1_s1"}) // +10 → 80
	if r, err := buy("k8", rules.PurchaseInput{ItemType: "cosmetic_bundle", ItemID: "cozy", ExpectedPrice: 95}); err == nil || r.Price != 0 {
		// 70 + 10 = 80 < 95 → insufficient
		if !errors.As(err, &short) {
			t.Fatalf("bundle with too few coins: %v %+v", err, r)
		}
	}
}

func TestConcurrentSpendNeverOverdraws(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	_ = f.st.WithUserTx(ctx, f.user.ID, func(tx *store.UserTx) error {
		_, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: 100, Reason: "test", Key: "seed"})
		return err
	})
	var ok, short int32
	var wg sync.WaitGroup
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			_, _, err := f.svc.Purchase(ctx, f.user, rules.PurchaseInput{ItemType: "streak_shield", ItemID: "streak_shield", ExpectedPrice: 20}, fmt.Sprintf("c%d", i))
			var e *store.ErrInsufficientCoins
			switch {
			case err == nil:
				atomic.AddInt32(&ok, 1)
			case errors.As(err, &e):
				atomic.AddInt32(&short, 1)
			default:
				t.Errorf("purchase %d: %v", i, err)
			}
		}(i)
	}
	wg.Wait()
	if ok != 5 || short != 5 || f.coins().Coins() != 0 {
		t.Fatalf("10 parallel buys of 20 with 100 coins: ok=%d short=%d left=%d", ok, short, f.coins().Coins())
	}
}

func TestLoadouts(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	_ = f.st.WithUserTx(ctx, f.user.ID, func(tx *store.UserTx) error {
		return tx.AddInventory([]string{"topi_rajut", "syal_hangat", "bingkai_emas", "acc_beanie", "acc_ribbon", "acc_jungCrown", "cardstyle_taman"}, "grant")
	})
	if _, err := f.svc.SetMonsterLoadout(ctx, f.user, "kabut", []string{"topi_rajut", "syal_hangat"}); err != nil {
		t.Fatalf("valid monster loadout: %v", err)
	}
	var v *rules.ValidationError
	if _, err := f.svc.SetMonsterLoadout(ctx, f.user, "kabut", []string{"bingkai_emas"}); !errors.As(err, &v) {
		t.Fatalf("bingkai_emas is Si Cermin only: %v", err)
	}
	if _, err := f.svc.SetMonsterLoadout(ctx, f.user, "waswas", []string{"bantal_mini"}); !errors.Is(err, rules.ErrNotOwned) {
		t.Fatalf("not owned: %v", err)
	}
	if _, err := f.svc.SetCharacterLoadout(ctx, f.user, "jung", rules.CharacterLoadoutInput{Accessories: []string{"beanie", "ribbon"}}); !errors.As(err, &v) {
		t.Fatalf("one accessory per slot: %v", err)
	}
	if _, err := f.svc.SetCharacterLoadout(ctx, f.user, "temperament", rules.CharacterLoadoutInput{Accessories: []string{"jungCrown"}}); !errors.As(err, &v) {
		t.Fatalf("exclusive accessory on another character: %v", err)
	}
	if _, err := f.svc.SetCharacterLoadout(ctx, f.user, "jung", rules.CharacterLoadoutInput{Accessories: []string{"jungCrown"}, CardStyle: ptr("taman")}); err != nil {
		t.Fatalf("valid character loadout: %v", err)
	}
	if _, err := f.svc.SetCharacterLoadout(ctx, f.user, "jung", rules.CharacterLoadoutInput{CardStyle: ptr("aurora")}); !errors.Is(err, rules.ErrPremiumRequired) {
		t.Fatalf("unowned paid style without premium: %v", err)
	}
	f.premium("premium_monthly")
	if _, err := f.svc.SetCharacterLoadout(ctx, f.user, "jung", rules.CharacterLoadoutInput{CardStyle: ptr("aurora")}); err != nil {
		t.Fatalf("premium can use every style: %v", err)
	}
	if _, err := f.svc.SetMonsterLoadout(ctx, f.user, "naga", nil); !errors.Is(err, rules.ErrNotFound) {
		t.Fatalf("unknown monster: %v", err)
	}
}

func TestPremiumDailyAndDebt(t *testing.T) {
	f := newFixture(t)
	ctx := context.Background()
	if _, _, err := f.svc.ClaimPremiumDaily(ctx, f.user); !errors.Is(err, rules.ErrPremiumRequired) {
		t.Fatalf("free user: %v", err)
	}
	f.premium("premium_monthly")
	if _, _, err := f.svc.ClaimPremiumDaily(ctx, f.user); !errors.Is(err, rules.ErrPremiumRequired) {
		t.Fatalf("monthly plan has no daily coins: %v", err)
	}
	f.premium("premium_yearly")
	r, w, err := f.svc.ClaimPremiumDaily(ctx, f.user)
	if err != nil || r.CoinsGranted != 2 || w.PurchasedCoins != 2 || w.EarnedCoins != 0 {
		t.Fatalf("claim: %+v %+v %v", r, w, err)
	}
	if r, _, _ := f.svc.ClaimPremiumDaily(ctx, f.user); !r.Capped || r.CoinsGranted != 0 {
		t.Fatalf("second claim the same day: %+v", r)
	}
	// Daily coins are "bought" coins: Aplikasi Beku unlocks (earned only) cannot use them.
	err = f.st.WithUserTx(ctx, f.user.ID, func(tx *store.UserTx) error {
		return tx.Debit(store.Debit{Amount: 1, EarnedOnly: true, Reason: "test", Key: "x"})
	})
	var short *store.ErrInsufficientCoins
	if !errors.As(err, &short) || !short.EarnedOnly {
		t.Fatalf("earned-only debit must refuse purchased coins: %v", err)
	}
}
