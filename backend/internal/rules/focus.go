package rules

import (
	"context"
	"errors"
	"slices"
	"strconv"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// LimitError: a blocking daily or ethical limit was reached (409 limit_reached).
type LimitError struct {
	Reason   string // free_daily | no_prepaid_sessions | daily_paid_unlocks
	Limit    int
	ResetsAt *time.Time
}

func (e *LimitError) Error() string { return "limit reached: " + e.Reason }

// CooldownError: the ethical pause between paid unlocks has not passed (409 cooldown).
type CooldownError struct{ RetryAfter time.Duration }

func (e *CooldownError) Error() string { return "cooldown" }

// TicketError: a focus_completed report names an unusable ticket (409 ticket_invalid).
type TicketError struct {
	Reason string // not_found | used | too_early | expired | overlap
}

func (e *TicketError) Error() string { return "focus ticket invalid: " + e.Reason }

// endOfLocalDay is the next local midnight in tz.
func endOfLocalDay(t time.Time, tz string) time.Time {
	loc, err := time.LoadLocation(tz)
	if err != nil {
		loc, _ = time.LoadLocation("Asia/Jakarta")
	}
	y, m, d := t.In(loc).Date()
	return time.Date(y, m, d+1, 0, 0, 0, 0, loc).UTC()
}

// --- Focus Mode tickets (docs/backend-api-spec.md §3.7) -------------------------------

// Focus ticket sources.
const (
	FocusFreeDaily = "free_daily"
	FocusPrepaid   = "prepaid"
	FocusCoins     = "coins"
)

// paidTicketValidity is how long prepaid and coin tickets stay usable.
const paidTicketValidity = 30 * 24 * time.Hour

// FocusDurations are the session lengths a ticket can be issued for.
var FocusDurations = []int{25, 45, 60}

// FocusTicketInput requests a ticket. ExpectedPrice is required for coins.
type FocusTicketInput struct {
	Source        string `json:"source"`
	DurationMin   int    `json:"durationMin"`
	ExpectedPrice *int   `json:"expectedPrice,omitempty"`
}

// FocusIssue is an issued ticket and what it cost.
type FocusIssue struct {
	Ticket        store.FocusTicket
	Price         int
	FreeFocusLeft int
	PrepaidFocus  int
}

// FocusPrice is the coin price of a session of durationMin.
func (s *Service) FocusPrice(durationMin int) (int, bool) {
	switch durationMin {
	case 25:
		return s.Economy.Spend.Focus25, true
	case 45:
		return s.Economy.Spend.Focus45, true
	case 60:
		return s.Economy.Spend.Focus60, true
	}
	return 0, false
}

// freeFocusLimit is today's free sessions: 1, or 3 with Premium.
func (s *Service) freeFocusLimit(tx *store.UserTx) (int, error) {
	prem, err := s.premium(tx)
	if err != nil {
		return 0, err
	}
	if prem.Active() {
		return s.Economy.Premium.FocusFreePerDay, nil
	}
	return s.Economy.FreeTier.FocusPerDay, nil
}

// IssueFocusTicket issues a ticket the app can use offline. Free tickets are
// limited per local day and expire at local midnight; prepaid tickets use
// one bought session and coin tickets cost 25/40/50 coins, both valid 30
// days. Free and prepaid tickets are valid for any duration.
func (s *Service) IssueFocusTicket(ctx context.Context, user store.User, in FocusTicketInput, idemKey string) (FocusIssue, store.Wallet, error) {
	var out FocusIssue
	var wallet store.Wallet
	if !slices.Contains(FocusDurations, in.DurationMin) {
		return out, wallet, invalid("durationMin", "durationMin must be 25, 45 or 60")
	}
	now := s.Now().UTC().Truncate(time.Second)
	today := LocalDay(now, user.TZ)
	err := s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		limit, err := s.freeFocusLimit(tx)
		if err != nil {
			return err
		}
		expires := now.Add(paidTicketValidity)
		switch in.Source {
		case FocusFreeDaily:
			used, err := tx.IncCounter(today, store.CounterFocusFree, 1)
			if err != nil {
				return err
			}
			if used > limit {
				resets := endOfLocalDay(now, user.TZ)
				return &LimitError{Reason: "free_daily", Limit: limit, ResetsAt: &resets}
			}
			expires = endOfLocalDay(now, user.TZ)
		case FocusPrepaid:
			if _, err := tx.AddConsumable(store.ConsumablePrepaidFocus, -1); errors.Is(err, store.ErrNotEnough) {
				return &LimitError{Reason: "no_prepaid_sessions"}
			} else if err != nil {
				return err
			}
		case FocusCoins:
			price, _ := s.FocusPrice(in.DurationMin)
			if in.ExpectedPrice == nil {
				return invalid("expectedPrice", "expectedPrice is required for coin tickets")
			}
			if *in.ExpectedPrice != price {
				return &PriceChangedError{Price: price}
			}
			if err := tx.Debit(store.Debit{Amount: price, Reason: "focus_ticket", Ref: strconv.Itoa(in.DurationMin),
				Key: "focus_ticket:" + idemKey}); err != nil {
				return err
			}
			out.Price = price
		default:
			return invalid("source", "source must be free_daily, prepaid or coins")
		}
		t, err := tx.IssueFocusTicket(in.Source, in.DurationMin, now, expires)
		if err != nil {
			return err
		}
		out.Ticket = t
		used, err := tx.Counter(today, store.CounterFocusFree)
		if err != nil {
			return err
		}
		out.FreeFocusLeft = max(0, limit-used)
		if out.PrepaidFocus, err = tx.Consumable(store.ConsumablePrepaidFocus); err != nil {
			return err
		}
		wallet = tx.Wallet()
		return nil
	})
	return out, wallet, err
}

// focusTolerance absorbs clock differences between the phone and the server.
const focusTolerance = time.Minute

// redeemFocus consumes the ticket of a focus_completed report. The session
// cannot finish before issuedAt + duration − 1 minute (by the reported time
// and by the server clock, since occurredAt may run a few minutes ahead),
// must have started (occurredAt − duration) before the ticket expired, and
// must not overlap another redeemed session: one person focuses on one
// session at a time, so several tickets cannot pay for the same minutes.
func (s *Service) redeemFocus(tx *store.UserTx, p prepared, res *ActivityResult) error {
	in := p.in
	t, err := tx.FocusTicket(in.TicketID)
	if errors.Is(err, store.ErrNotFound) {
		return &TicketError{Reason: "not_found"}
	}
	if err != nil {
		return err
	}
	dur := time.Duration(t.DurationMin) * time.Minute
	earliest := t.IssuedAt.Add(dur - focusTolerance)
	switch {
	case t.ConsumedAt != nil:
		return &TicketError{Reason: "used"}
	case in.OccurredAt.Before(earliest), s.Now().Before(earliest):
		return &TicketError{Reason: "too_early"}
	case in.OccurredAt.Add(-dur).After(t.ExpiresAt):
		return &TicketError{Reason: "expired"}
	}
	if overlaps, err := tx.FocusSessionOverlaps(t.ID, in.OccurredAt.Add(-dur), in.OccurredAt, focusTolerance); err != nil {
		return err
	} else if overlaps {
		return &TicketError{Reason: "overlap"}
	}
	if ok, err := tx.ConsumeFocusTicket(t.ID, s.Now(), in.OccurredAt); err != nil {
		return err
	} else if !ok {
		return &TicketError{Reason: "used"}
	}
	return s.progress(tx, res, in.SaboteurID, s.Economy.MonsterProgress.Focus)
}

// --- Aplikasi Beku paid unlocks (docs/backend-api-spec.md §3.8) -----------------------------

// AppBekuInput is one paid unlock: a single app (AppID + Minutes) or a bundle.
type AppBekuInput struct {
	AppID         string   `json:"appId,omitempty"`
	Minutes       int      `json:"minutes,omitempty"`
	BundleID      string   `json:"bundleId,omitempty"`
	AppIDs        []string `json:"appIds,omitempty"`
	ExpectedPrice int      `json:"expectedPrice"`
}

// AppBekuResult tells the app which minutes to unlock locally.
type AppBekuResult struct {
	Target          string                 `json:"target"` // unit | <bundleId>
	Grants          []catalog.AppBekuGrant `json:"grants"`
	Price           int                    `json:"price"`
	PaidUnlocksUsed int                    `json:"paidUnlocksUsed"`
	PaidUnlocksLeft int                    `json:"paidUnlocksLeft"`
	CooldownUntil   time.Time              `json:"cooldownUntil"`
}

// appBekuRequest resolves the input against the catalog: what it unlocks
// and its base price before escalation.
func (s *Service) appBekuRequest(in AppBekuInput) (target string, grants []catalog.AppBekuGrant, base int, err error) {
	switch {
	case in.BundleID == "" && in.AppID != "":
		if len(in.AppIDs) > 0 {
			return "", nil, 0, invalid("appIds", "appIds is only for bundles")
		}
		if _, ok := s.Catalog.AppBekuApp(in.AppID); !ok {
			return "", nil, 0, invalid("appId", "appId is not in the Aplikasi Beku catalog")
		}
		u, ok := s.Catalog.AppBekuUnit(in.Minutes)
		if !ok {
			return "", nil, 0, invalid("minutes", "minutes must be one of the catalog units")
		}
		return "unit", []catalog.AppBekuGrant{{AppID: in.AppID, Minutes: u.Minutes}}, u.Price, nil

	case in.BundleID != "" && in.AppID == "" && in.Minutes == 0:
		b, ok := s.Catalog.AppBekuBundle(in.BundleID)
		if !ok {
			return "", nil, 0, invalid("bundleId", "unknown bundleId")
		}
		if len(b.Apps) > 0 {
			// Fixed bundle: appIds may be omitted or must list exactly its apps.
			if len(in.AppIDs) > 0 {
				want := make([]string, 0, len(b.Apps))
				for _, g := range b.Apps {
					want = append(want, g.AppID)
				}
				got := slices.Clone(in.AppIDs)
				slices.Sort(want)
				slices.Sort(got)
				if !slices.Equal(want, got) {
					return "", nil, 0, invalid("appIds", "appIds must match the bundle's apps")
				}
			}
			return b.ID, slices.Clone(b.Apps), b.Price, nil
		}
		// Group bundle: the frozen apps of the group the user picked.
		if len(in.AppIDs) == 0 {
			return "", nil, 0, invalid("appIds", "appIds must list the frozen apps to unlock")
		}
		seen := map[string]bool{}
		for _, id := range in.AppIDs {
			a, ok := s.Catalog.AppBekuApp(id)
			if !ok || a.Group != b.Group || seen[id] {
				return "", nil, 0, invalid("appIds", "appIds must be distinct "+b.Group+" apps from the catalog")
			}
			seen[id] = true
			grants = append(grants, catalog.AppBekuGrant{AppID: id, Minutes: b.MinutesPerApp})
		}
		return b.ID, grants, b.Price, nil
	}
	return "", nil, 0, invalid("appId", "send either appId and minutes, or bundleId")
}

// AppBekuUnlock buys extra minutes with practice coins only. The ethical
// guard (CLAUDE.md §3) is enforced here: at most maxPaidUnlocksPerDay per
// local day, each costs escalationPerUnlock more than the previous one, and
// at least unlockCooldownSeconds must pass between paid unlocks. A bundle is
// one unlock, charged once, all or nothing.
func (s *Service) AppBekuUnlock(ctx context.Context, user store.User, in AppBekuInput, idemKey string) (AppBekuResult, store.Wallet, error) {
	var res AppBekuResult
	var wallet store.Wallet
	target, grants, base, err := s.appBekuRequest(in)
	if err != nil {
		return res, wallet, err
	}
	e := s.Economy.AppBeku
	now := s.Now().UTC()
	today := LocalDay(now, user.TZ)
	err = s.Store.WithUserTx(ctx, user.ID, func(tx *store.UserTx) error {
		used, err := tx.Counter(today, store.CounterAppBekuPaid)
		if err != nil {
			return err
		}
		if used >= e.MaxPaidUnlocksPerDay {
			resets := endOfLocalDay(now, user.TZ)
			return &LimitError{Reason: "daily_paid_unlocks", Limit: e.MaxPaidUnlocksPerDay, ResetsAt: &resets}
		}
		cooldown := time.Duration(e.UnlockCooldownSeconds) * time.Second
		last, err := tx.LastAppBekuUnlock()
		if err != nil {
			return err
		}
		if last != nil && now.Before(last.Add(cooldown)) {
			return &CooldownError{RetryAfter: last.Add(cooldown).Sub(now)}
		}
		price := base + e.EscalationPerUnlock*used
		if in.ExpectedPrice != price {
			return &PriceChangedError{Price: price}
		}
		if err := tx.Debit(store.Debit{Amount: price, EarnedOnly: true, Reason: "appbeku_unlock", Ref: target,
			Key: "appbeku:" + idemKey}); err != nil {
			return err
		}
		n, err := tx.IncCounter(today, store.CounterAppBekuPaid, 1)
		if err != nil {
			return err
		}
		minutes := 0
		for _, g := range grants {
			minutes += g.Minutes
		}
		if err := tx.RecordAppBekuUnlock(target, minutes, price, now); err != nil {
			return err
		}
		res = AppBekuResult{Target: target, Grants: grants, Price: price, PaidUnlocksUsed: n,
			PaidUnlocksLeft: max(0, e.MaxPaidUnlocksPerDay-n), CooldownUntil: now.Add(cooldown)}
		wallet = tx.Wallet()
		return nil
	})
	return res, wallet, err
}
