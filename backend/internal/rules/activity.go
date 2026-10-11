package rules

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Activity types (docs/backend-api-spec.md §3.3).
const (
	TypeCheckin        = "checkin"
	TypeJournalSaved   = "journal_saved"
	TypeMeditation     = "meditation_completed"
	TypeBettermeLesson = "betterme_lesson_completed"
	TypeMission        = "mission_completed"
	TypeMinigame       = "minigame_finished"
	TypeFocusComplete  = "focus_completed"
)

// Cap reasons: the event is recorded but grants no coins or progress.
const (
	CapDaily          = "daily_cap"
	CapFreeDailyLimit = "free_daily_limit"
	CapPremium        = "premium_required"
	CapLocked         = "locked"
)

// Offline reports are accepted up to MaxEventAge old and MaxClockSkew in the future.
const (
	MaxEventAge  = 7 * 24 * time.Hour
	MaxClockSkew = 5 * time.Minute
)

// ActivityInput is one reported practice event. Fields not used by Type are ignored.
type ActivityInput struct {
	Type            string    `json:"type"`
	Ref             string    `json:"ref,omitempty"`
	OccurredAt      time.Time `json:"occurredAt"`
	Date            string    `json:"date,omitempty"`
	EntryID         string    `json:"entryId,omitempty"`
	PromptID        string    `json:"promptId,omitempty"`
	PromptMonsterID string    `json:"promptMonsterId,omitempty"`
	SessionID       string    `json:"sessionId,omitempty"`
	TargetMonsterID string    `json:"targetMonsterId,omitempty"`
	LessonID        string    `json:"lessonId,omitempty"`
	Index           *int      `json:"index,omitempty"`
	SaboteurID      string    `json:"saboteurId,omitempty"`
	Won             *bool     `json:"won,omitempty"`
	TicketID        string    `json:"ticketId,omitempty"`
}

// MonsterResult is the monster progress after the event.
type MonsterResult struct {
	SaboteurID string `json:"saboteurId"`
	State      string `json:"state"`
	Progress   int    `json:"progress"`
	JustTamed  bool   `json:"justTamed"`
	TamedBonus int    `json:"tamedBonus"`
}

// StreakResult is the check-in streak after a check-in.
type StreakResult struct {
	Current        int  `json:"current"`
	Longest        int  `json:"longest"`
	ShieldUsed     bool `json:"shieldUsed"`
	MilestoneBonus int  `json:"milestoneBonus"`
}

// ActivityResult is what an event granted. CoinsGranted includes bonuses.
type ActivityResult struct {
	Type         string         `json:"type"`
	Key          string         `json:"key"`
	CoinsGranted int            `json:"coinsGranted"`
	Capped       bool           `json:"capped"`
	CapReason    string         `json:"capReason,omitempty"`
	Monster      *MonsterResult `json:"monster"`
	Streak       *StreakResult  `json:"streak"`
	Replayed     bool           `json:"replayed"`
}

var (
	idPattern   = regexp.MustCompile(`^[A-Za-z0-9_.:-]{1,64}$`)
	uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)
)

// prepared is a validated event with its business key.
type prepared struct {
	in    ActivityInput
	key   string
	day   time.Time // local date the event happened
	today time.Time // local date it is processed
}

func (s *Service) prepare(user store.User, in ActivityInput) (prepared, error) {
	now := s.Now()
	if in.OccurredAt.IsZero() {
		return prepared{}, invalid("occurredAt", "occurredAt is required")
	}
	if in.OccurredAt.Before(now.Add(-MaxEventAge)) || in.OccurredAt.After(now.Add(MaxClockSkew)) {
		return prepared{}, invalid("occurredAt", "occurredAt must be within the last 7 days")
	}
	p := prepared{in: in, day: LocalDay(in.OccurredAt, user.TZ), today: LocalDay(now, user.TZ)}
	dayStr := p.day.Format(time.DateOnly)
	checkDate := func() error {
		if in.Date != dayStr {
			return invalid("date", "date must be the local date of occurredAt ("+dayStr+")")
		}
		return nil
	}
	switch in.Type {
	case TypeCheckin:
		if err := checkDate(); err != nil {
			return p, err
		}
		p.key = "checkin:" + dayStr
	case TypeJournalSaved:
		if !idPattern.MatchString(in.EntryID) {
			return p, invalid("entryId", "entryId is required")
		}
		if in.PromptID != "" {
			if _, ok := s.Catalog.JournalPrompt(in.PromptID); !ok {
				return p, invalid("promptId", "unknown promptId")
			}
		}
		if in.PromptMonsterID != "" {
			if _, ok := s.Catalog.Monster(in.PromptMonsterID); !ok {
				return p, invalid("promptMonsterId", "unknown promptMonsterId")
			}
		}
		p.key = "journal:" + in.EntryID
	case TypeMeditation:
		if _, ok := s.Catalog.Meditation(in.SessionID); !ok {
			return p, invalid("sessionId", "unknown sessionId")
		}
		p.key = "meditation:" + in.SessionID + ":" + dayStr
	case TypeBettermeLesson:
		if _, ok := s.Catalog.BettermeLesson(in.LessonID); !ok {
			return p, invalid("lessonId", "unknown lessonId")
		}
		p.key = "betterme:" + in.LessonID
	case TypeMission:
		if err := checkDate(); err != nil {
			return p, err
		}
		if in.Index == nil || *in.Index < 0 || *in.Index >= s.Economy.Caps.MissionsPerDay {
			return p, invalid("index", fmt.Sprintf("index must be 0–%d", s.Economy.Caps.MissionsPerDay-1))
		}
		p.key = "mission:" + dayStr + ":" + strconv.Itoa(*in.Index)
	case TypeMinigame:
		if !uuidPattern.MatchString(in.Ref) {
			return p, invalid("ref", "ref must be a UUID")
		}
		if _, ok := s.Catalog.Monster(in.SaboteurID); !ok {
			return p, invalid("saboteurId", "unknown saboteurId")
		}
		if in.Won == nil {
			return p, invalid("won", "won is required")
		}
		p.key = "minigame:" + in.Ref
	case TypeFocusComplete:
		return p, invalid("type", "focus_completed needs focus tickets, which this server version does not issue yet")
	default:
		return p, invalid("type", "unknown activity type")
	}
	return p, nil
}

// ApplyActivity processes one event exactly once.
func (s *Service) ApplyActivity(ctx context.Context, user store.User, in ActivityInput) (ActivityResult, store.Wallet, error) {
	p, err := s.prepare(user, in)
	if err != nil {
		return ActivityResult{}, store.Wallet{}, err
	}
	var res ActivityResult
	var wallet store.Wallet
	err = s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		if stored, ok, err := tx.Activity(p.key); err != nil {
			return err
		} else if ok {
			if err := json.Unmarshal(stored, &res); err != nil {
				return err
			}
			res.Replayed = true
			wallet = tx.Wallet()
			return nil
		}
		res = ActivityResult{Type: p.in.Type, Key: p.key}
		if err := s.apply(ctx, tx, p, &res); err != nil {
			return err
		}
		if err := tx.RecordActivity(p.key, p.in.Type, res); err != nil {
			return err
		}
		wallet = tx.Wallet()
		return nil
	})
	return res, wallet, err
}

func (s *Service) apply(ctx context.Context, tx *store.UserTx, p prepared, res *ActivityResult) error {
	e := s.Economy
	in := p.in
	switch in.Type {
	case TypeCheckin:
		return s.applyCheckin(tx, p, res)

	case TypeJournalSaved:
		prem, err := s.premium(tx)
		if err != nil {
			return err
		}
		entries, err := tx.IncCounter(p.day, store.CounterJournal, 1)
		if err != nil {
			return err
		}
		monster := in.PromptMonsterID
		promptPremium := false
		if in.PromptID != "" {
			pr, _ := s.Catalog.JournalPrompt(in.PromptID)
			monster, promptPremium = pr.MonsterID, pr.Premium
		}
		switch {
		case !prem.Active() && entries > e.FreeTier.JournalPerDay:
			return capped(res, CapFreeDailyLimit)
		case promptPremium && !prem.Active():
			return capped(res, CapPremium)
		}
		ok, err := s.takeReward(ctx, tx, p.day, store.CounterJournalReward, settings.JournalRewardsPerDay)
		if err != nil || !ok {
			return orCapped(err, res, CapDaily)
		}
		if err := s.credit(tx, res, e.Earn.Journal, "journal", in.EntryID, p.key); err != nil {
			return err
		}
		if monster != "" {
			return s.progress(tx, res, monster, e.MonsterProgress.JournalPrompt)
		}
		return nil

	case TypeMeditation:
		m, _ := s.Catalog.Meditation(in.SessionID)
		if m.Premium {
			prem, err := s.premium(tx)
			if err != nil {
				return err
			}
			if !prem.Active() {
				return capped(res, CapPremium)
			}
		}
		ok, err := s.takeReward(ctx, tx, p.day, store.CounterMeditation, settings.MeditationRewardsPerDay)
		if err != nil || !ok {
			return orCapped(err, res, CapDaily)
		}
		if err := s.credit(tx, res, e.Earn.Meditation, "meditation", in.SessionID, p.key); err != nil {
			return err
		}
		// The catalog decides the target monster, not the client.
		return s.progress(tx, res, m.TargetMonsterID, e.MonsterProgress.Meditation)

	case TypeBettermeLesson:
		l, _ := s.Catalog.BettermeLesson(in.LessonID)
		if l.Level >= s.Catalog.Betterme.PremiumFromLevel {
			prem, err := s.premium(tx)
			if err != nil {
				return err
			}
			if !prem.Active() {
				return capped(res, CapPremium)
			}
		}
		if l.Level > 1 {
			done, err := tx.BettermeCompleted()
			if err != nil {
				return err
			}
			for _, id := range s.Catalog.LessonsOfLevel(l.Level - 1) {
				if !done[id] {
					return capped(res, CapLocked)
				}
			}
		}
		if _, err := tx.CompleteBetterme(in.LessonID); err != nil {
			return err
		}
		return s.credit(tx, res, e.Earn.BettermeLesson, "betterme", in.LessonID, p.key)

	case TypeMission:
		if _, err := tx.IncCounter(p.day, store.CounterMissionPrefix+strconv.Itoa(*in.Index), 1); err != nil {
			return err
		}
		return s.credit(tx, res, e.Earn.Mission, "mission", strconv.Itoa(*in.Index), p.key)

	case TypeMinigame:
		fights, err := tx.IncCounter(p.day, store.CounterMinigame, 1)
		if err != nil {
			return err
		}
		if fights > e.Tickets.MaxFightsPerDay {
			return capped(res, CapDaily)
		}
		delta := e.MonsterProgress.MinigameLose
		if *in.Won {
			delta = e.MonsterProgress.MinigameWin
			if err := s.credit(tx, res, e.Earn.MinigameWin, "minigame_win", in.SaboteurID, p.key); err != nil {
				return err
			}
		}
		return s.progress(tx, res, in.SaboteurID, delta)
	}
	return fmt.Errorf("unhandled activity type %q", in.Type)
}

// applyCheckin: +check-in coins; the streak grows on consecutive days, a
// streak shield bridges exactly one missed day, milestones pay once when the
// streak reaches 7 and 30. Only check-ins for today or yesterday (a late
// night synced the next morning) can move the streak: an older report still
// pays the check-in but cannot back-fill missed days, which would make
// streak shields pointless.
func (s *Service) applyCheckin(tx *store.UserTx, p prepared, res *ActivityResult) error {
	e := s.Economy
	if err := s.credit(tx, res, e.Earn.Checkin, "checkin", p.day.Format(time.DateOnly), p.key); err != nil {
		return err
	}
	st, err := tx.Streak()
	if err != nil {
		return err
	}
	sr := &StreakResult{}
	res.Streak = sr
	tooOld := p.day.Before(p.today.AddDate(0, 0, -1))
	if tooOld || (st.LastCheckinDate != nil && !p.day.After(*st.LastCheckinDate)) {
		sr.Current, sr.Longest = st.CurrentDays, st.LongestDays
		return nil
	}
	gap := 0
	if st.LastCheckinDate != nil {
		gap = int(p.day.Sub(*st.LastCheckinDate).Hours() / 24)
	}
	switch {
	case st.LastCheckinDate == nil:
		st.CurrentDays = 1
	case gap == 1:
		st.CurrentDays++
	case gap == 2:
		shields, err := tx.Consumable(store.ConsumableStreakShield)
		if err != nil {
			return err
		}
		if shields > 0 {
			if _, err := tx.AddConsumable(store.ConsumableStreakShield, -1); err != nil {
				return err
			}
			st.CurrentDays++
			sr.ShieldUsed = true
		} else {
			st.CurrentDays = 1
		}
	default:
		st.CurrentDays = 1
	}
	day := p.day
	st.LastCheckinDate = &day
	st.LongestDays = max(st.LongestDays, st.CurrentDays)
	if err := tx.SetStreak(st); err != nil {
		return err
	}
	sr.Current, sr.Longest = st.CurrentDays, st.LongestDays

	bonus, name := 0, ""
	switch st.CurrentDays {
	case 7:
		bonus, name = e.Earn.Streak7, "streak7"
	case 30:
		bonus, name = e.Earn.Streak30, "streak30"
	}
	if bonus > 0 {
		dayStr := p.day.Format(time.DateOnly)
		applied, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: bonus,
			Reason: name, Ref: dayStr, Key: name + ":" + dayStr})
		if err != nil {
			return err
		}
		if applied {
			sr.MilestoneBonus = bonus
			res.CoinsGranted += bonus
		}
	}
	return nil
}

// takeReward consumes one of today's rewarded slots for counter, limited by
// the admin setting. It reports false when the cap is reached.
func (s *Service) takeReward(ctx context.Context, tx *store.UserTx, day time.Time, counter, setting string) (bool, error) {
	limit := s.Settings.Int(ctx, setting)
	used, err := tx.Counter(day, counter)
	if err != nil || used >= limit {
		return false, err
	}
	_, err = tx.IncCounter(day, counter, 1)
	return err == nil, err
}

func (s *Service) credit(tx *store.UserTx, res *ActivityResult, amount int, reason, ref, key string) error {
	applied, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: amount, Reason: reason, Ref: ref, Key: key})
	if err != nil {
		return err
	}
	if applied {
		res.CoinsGranted += amount
	}
	return nil
}

// progress adds taming progress; reaching 100 the first time pays the
// taming reward once per monster.
func (s *Service) progress(tx *store.UserTx, res *ActivityResult, monsterID string, delta int) error {
	m, justTamed, err := tx.AddMonsterProgress(monsterID, delta)
	if err != nil {
		return err
	}
	mr := &MonsterResult{SaboteurID: m.SaboteurID, State: m.State, Progress: m.Progress, JustTamed: justTamed}
	res.Monster = mr
	if justTamed {
		bonus := s.Economy.Earn.MonsterTamed
		applied, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: bonus,
			Reason: "monster_tamed", Ref: monsterID, Key: "tamed:" + monsterID})
		if err != nil {
			return err
		}
		if applied {
			mr.TamedBonus = bonus
			res.CoinsGranted += bonus
		}
	}
	return nil
}

func capped(res *ActivityResult, reason string) error {
	res.Capped, res.CapReason = true, reason
	return nil
}

func orCapped(err error, res *ActivityResult, reason string) error {
	if err != nil {
		return err
	}
	return capped(res, reason)
}
