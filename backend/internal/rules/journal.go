package rules

import (
	"context"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// JournalPromptAccess is one prompt's status for the caller.
type JournalPromptAccess struct {
	ID        string `json:"id"`
	MonsterID string `json:"monsterId"`
	Premium   bool   `json:"premium"`
	Locked    bool   `json:"locked"`
}

// JournalAccess answers "may I write a journal entry now, and which prompts
// are premium?" (GET /v1/journal/access, spec §3.4).
type JournalAccess struct {
	Date              string                `json:"date"`
	Premium           bool                  `json:"premium"`
	EntriesToday      int                   `json:"entriesToday"`
	FreeEntriesPerDay int                   `json:"freeEntriesPerDay"`
	CanWrite          bool                  `json:"canWrite"`
	Reason            *string               `json:"reason"`
	RewardedToday     int                   `json:"rewardedToday"`
	RewardsPerDay     int                   `json:"rewardsPerDay"`
	Prompts           []JournalPromptAccess `json:"prompts"`
}

// Reasons why writing is not allowed.
const (
	ReasonDailyLimit      = "daily_limit"
	ReasonPremiumRequired = "premium_required"
)

// JournalAccessFor computes the caller's journal access today. With promptID
// set, only that prompt is listed and canWrite also accounts for it being
// premium. Entries count from journal_saved events already received; the app
// keeps its own count as a fallback while offline.
func (s *Service) JournalAccessFor(ctx context.Context, user store.User, promptID string) (JournalAccess, error) {
	var only *JournalPromptAccess
	if promptID != "" {
		p, ok := s.Catalog.JournalPrompt(promptID)
		if !ok {
			return JournalAccess{}, ErrNotFound
		}
		only = &JournalPromptAccess{ID: p.ID, MonsterID: p.MonsterID, Premium: p.Premium}
	}
	day := LocalDay(s.Now(), user.TZ)
	out := JournalAccess{
		Date:              day.Format(time.DateOnly),
		FreeEntriesPerDay: s.Economy.FreeTier.JournalPerDay,
		RewardsPerDay:     s.Settings.Int(ctx, settings.JournalRewardsPerDay),
		Prompts:           []JournalPromptAccess{},
	}
	err := s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		prem, err := s.premium(tx)
		if err != nil {
			return err
		}
		out.Premium = prem.Active()
		if out.EntriesToday, err = tx.Counter(day, store.CounterJournal); err != nil {
			return err
		}
		out.RewardedToday, err = tx.Counter(day, store.CounterJournalReward)
		return err
	})
	if err != nil {
		return JournalAccess{}, err
	}

	if only != nil {
		only.Locked = only.Premium && !out.Premium
		out.Prompts = append(out.Prompts, *only)
	} else {
		for _, p := range s.Catalog.JournalPrompts {
			out.Prompts = append(out.Prompts, JournalPromptAccess{ID: p.ID, MonsterID: p.MonsterID, Premium: p.Premium, Locked: p.Premium && !out.Premium})
		}
	}
	out.CanWrite = true
	switch {
	case !out.Premium && out.EntriesToday >= out.FreeEntriesPerDay:
		r := ReasonDailyLimit
		out.CanWrite, out.Reason = false, &r
	case only != nil && only.Locked:
		r := ReasonPremiumRequired
		out.CanWrite, out.Reason = false, &r
	}
	return out, nil
}
