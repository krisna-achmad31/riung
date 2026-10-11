package store

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

// Daily counter keys (daily_counters.key). Shared with the activity, focus
// and Aplikasi Beku code in later phases so /v1/me reads what they write.
const (
	CounterMissionPrefix = "mission:" // + index, value 0/1
	CounterMinigame      = "minigame"
	CounterFocusFree     = "focus_free"
	CounterAppBekuPaid   = "appbeku_paid"
	CounterPremiumDaily  = "premium_daily"
	CounterJournal       = "journal"
	CounterJournalReward = "journal_reward"
	CounterMeditation    = "meditation_reward"
)

// Subscription is the user's Play subscription state.
type Subscription struct {
	Plan         string
	Status       string
	ExpiresAt    *time.Time
	AutoRenewing bool
}

// Streak is the check-in streak.
type Streak struct {
	CurrentDays     int
	LongestDays     int
	LastCheckinDate *time.Time
}

// Wallet is the coin balance split by bucket.
type Wallet struct {
	EarnedCoins    int
	PurchasedCoins int
	DebtCoins      int
	LifetimeEarned int
	LifetimeSpent  int
}

// Coins is the balance shown in the app.
func (w Wallet) Coins() int { return w.EarnedCoins + w.PurchasedCoins }

// Assessment is the onboarding result summary.
type Assessment struct {
	DominantSaboteurs []string
	Scores            map[string]int
	CompletedAt       *time.Time
}

// MonsterProgress is one monster's taming state.
type MonsterProgress struct {
	SaboteurID string
	State      string
	Progress   int
	TamedAt    *time.Time
}

// CharacterLoadout is the outfit of a personality-test character.
type CharacterLoadout struct {
	AccessoryIDs []string
	CardStyle    *string
}

// Snapshot is everything GET /v1/me returns, read in one consistent view.
type Snapshot struct {
	User              User
	Subscription      *Subscription
	Streak            Streak
	Wallet            Wallet
	Assessment        *Assessment
	Monsters          []MonsterProgress
	Inventory         []string
	Consumables       map[string]int
	MonsterLoadouts   map[string][]string
	CharacterLoadouts map[string]CharacterLoadout
	Counters          map[string]int // today's daily_counters
}

// Snapshot loads the user's server-side state; day is "today" in the user's
// time zone (for daily counters).
func (s *Store) Snapshot(ctx context.Context, userID string, day time.Time) (Snapshot, error) {
	snap := Snapshot{
		Consumables:       map[string]int{},
		MonsterLoadouts:   map[string][]string{},
		CharacterLoadouts: map[string]CharacterLoadout{},
		Counters:          map[string]int{},
		Inventory:         []string{},
		Monsters:          []MonsterProgress{},
	}
	err := s.inTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly}, func(tx pgx.Tx) error {
		var err error
		if snap.User, err = scanUser(tx.QueryRow(ctx, `SELECT `+userColumns+` FROM users u WHERE u.id = $1`, userID)); err != nil {
			return err
		}

		var sub Subscription
		err = tx.QueryRow(ctx, `SELECT plan, status, expires_at, auto_renewing FROM subscriptions WHERE user_id = $1`, userID).
			Scan(&sub.Plan, &sub.Status, &sub.ExpiresAt, &sub.AutoRenewing)
		switch err = notFound(err); {
		case err == nil:
			snap.Subscription = &sub
		case errors.Is(err, ErrNotFound):
		default:
			return fmt.Errorf("subscription: %w", err)
		}

		err = tx.QueryRow(ctx, `SELECT current_days, longest_days, last_checkin_date FROM streaks WHERE user_id = $1`, userID).
			Scan(&snap.Streak.CurrentDays, &snap.Streak.LongestDays, &snap.Streak.LastCheckinDate)
		if err = notFound(err); err != nil && !errors.Is(err, ErrNotFound) {
			return fmt.Errorf("streak: %w", err)
		}

		w := &snap.Wallet
		err = tx.QueryRow(ctx, `SELECT earned_coins, purchased_coins, debt_coins, lifetime_earned, lifetime_spent
			FROM wallets WHERE user_id = $1`, userID).
			Scan(&w.EarnedCoins, &w.PurchasedCoins, &w.DebtCoins, &w.LifetimeEarned, &w.LifetimeSpent)
		if err = notFound(err); err != nil && !errors.Is(err, ErrNotFound) {
			return fmt.Errorf("wallet: %w", err)
		}

		var a Assessment
		var scores []byte
		err = tx.QueryRow(ctx, `SELECT dominant_saboteurs, scores, completed_at FROM assessments WHERE user_id = $1`, userID).
			Scan(&a.DominantSaboteurs, &scores, &a.CompletedAt)
		switch err = notFound(err); {
		case err == nil:
			if err := json.Unmarshal(scores, &a.Scores); err != nil {
				return fmt.Errorf("assessment scores: %w", err)
			}
			snap.Assessment = &a
		case errors.Is(err, ErrNotFound):
		default:
			return fmt.Errorf("assessment: %w", err)
		}

		rows, err := tx.Query(ctx, `SELECT saboteur_id, state, progress, tamed_at FROM monster_progress
			WHERE user_id = $1 ORDER BY saboteur_id`, userID)
		if err != nil {
			return fmt.Errorf("monsters: %w", err)
		}
		snap.Monsters, err = pgx.CollectRows(rows, func(r pgx.CollectableRow) (MonsterProgress, error) {
			var m MonsterProgress
			err := r.Scan(&m.SaboteurID, &m.State, &m.Progress, &m.TamedAt)
			return m, err
		})
		if err != nil {
			return fmt.Errorf("monsters: %w", err)
		}

		rows, err = tx.Query(ctx, `SELECT item_id FROM inventory WHERE user_id = $1 ORDER BY acquired_at, item_id`, userID)
		if err != nil {
			return fmt.Errorf("inventory: %w", err)
		}
		if snap.Inventory, err = pgx.CollectRows(rows, pgx.RowTo[string]); err != nil {
			return fmt.Errorf("inventory: %w", err)
		}

		if err := collectMap(ctx, tx, `SELECT kind, qty FROM consumables WHERE user_id = $1`, userID, snap.Consumables); err != nil {
			return fmt.Errorf("consumables: %w", err)
		}
		if err := collectMap(ctx, tx, `SELECT key, count FROM daily_counters WHERE user_id = $1 AND day = $2`, userID, snap.Counters, day); err != nil {
			return fmt.Errorf("counters: %w", err)
		}

		rows, err = tx.Query(ctx, `SELECT saboteur_id, item_ids FROM monster_loadouts WHERE user_id = $1`, userID)
		if err != nil {
			return fmt.Errorf("monster loadouts: %w", err)
		}
		var sab string
		var items []string
		if _, err := pgx.ForEachRow(rows, []any{&sab, &items}, func() error {
			snap.MonsterLoadouts[sab] = append([]string{}, items...)
			return nil
		}); err != nil {
			return fmt.Errorf("monster loadouts: %w", err)
		}

		rows, err = tx.Query(ctx, `SELECT test_id, accessory_ids, card_style FROM character_loadouts WHERE user_id = $1`, userID)
		if err != nil {
			return fmt.Errorf("character loadouts: %w", err)
		}
		var test string
		var style *string
		if _, err := pgx.ForEachRow(rows, []any{&test, &items, &style}, func() error {
			snap.CharacterLoadouts[test] = CharacterLoadout{AccessoryIDs: append([]string{}, items...), CardStyle: style}
			return nil
		}); err != nil {
			return fmt.Errorf("character loadouts: %w", err)
		}
		return nil
	})
	return snap, err
}

func collectMap(ctx context.Context, tx pgx.Tx, sql, userID string, into map[string]int, extra ...any) error {
	rows, err := tx.Query(ctx, sql, append([]any{userID}, extra...)...)
	if err != nil {
		return err
	}
	var k string
	var v int
	_, err = pgx.ForEachRow(rows, []any{&k, &v}, func() error {
		into[k] = v
		return nil
	})
	return err
}

// MissionsDone extracts completed mission indexes from today's counters.
func MissionsDone(counters map[string]int) []int {
	done := []int{}
	for k, v := range counters {
		if v <= 0 || !strings.HasPrefix(k, CounterMissionPrefix) {
			continue
		}
		if i, err := strconv.Atoi(strings.TrimPrefix(k, CounterMissionPrefix)); err == nil {
			done = append(done, i)
		}
	}
	sort.Ints(done)
	return done
}

// PutAssessment stores the onboarding assessment summary.
func (s *Store) PutAssessment(ctx context.Context, userID string, a Assessment) error {
	scores, err := json.Marshal(a.Scores)
	if err != nil {
		return err
	}
	_, err = s.pool.Exec(ctx, `INSERT INTO assessments (user_id, dominant_saboteurs, scores, completed_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id) DO UPDATE SET dominant_saboteurs = EXCLUDED.dominant_saboteurs,
			scores = EXCLUDED.scores, completed_at = EXCLUDED.completed_at`,
		userID, a.DominantSaboteurs, scores, a.CompletedAt)
	return err
}
