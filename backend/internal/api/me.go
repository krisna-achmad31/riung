package api

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/rules"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// --- response shapes (docs/backend-api-spec.md §3.2) ---------------------------------

type userJSON struct {
	ID               string    `json:"id"`
	BillingAccountID string    `json:"billingAccountId"`
	IsAnonymous      bool      `json:"isAnonymous"`
	DisplayName      string    `json:"displayName"`
	AvatarID         string    `json:"avatarId"`
	Locale           string    `json:"locale"`
	Persona          *string   `json:"persona"`
	TZ               string    `json:"tz"`
	OnboardingDone   bool      `json:"onboardingDone"`
	CreatedAt        time.Time `json:"createdAt"`
}

type premiumJSON struct {
	Status       string     `json:"status"` // none | active | in_grace | expired | canceled | …
	Plan         *string    `json:"plan"`
	ExpiresAt    *time.Time `json:"expiresAt"`
	AutoRenewing bool       `json:"autoRenewing"`
}

type streakJSON struct {
	Current         int     `json:"current"`
	Longest         int     `json:"longest"`
	LastCheckinDate *string `json:"lastCheckinDate"`
	Shields         int     `json:"shields"`
}

type walletJSON struct {
	Coins          int `json:"coins"`
	EarnedCoins    int `json:"earnedCoins"`
	PurchasedCoins int `json:"purchasedCoins"`
}

type assessmentJSON struct {
	DominantSaboteurs []string       `json:"dominantSaboteurs"`
	Scores            map[string]int `json:"scores"`
	CompletedAt       *time.Time     `json:"completedAt"`
}

type monsterJSON struct {
	SaboteurID string     `json:"saboteurId"`
	State      string     `json:"state"`
	Progress   int        `json:"progress"`
	TamedAt    *time.Time `json:"tamedAt"`
}

type characterLoadoutJSON struct {
	Accessories []string `json:"accessories"`
	CardStyle   *string  `json:"cardStyle"`
}

type todayJSON struct {
	Date                string `json:"date"`
	MissionsDone        []int  `json:"missionsDone"`
	FreeFocusLeft       int    `json:"freeFocusLeft"`
	PaidUnlocksUsed     int    `json:"paidUnlocksUsed"`
	FightsToday         int    `json:"fightsToday"`
	PremiumDailyClaimed bool   `json:"premiumDailyClaimed"`
}

type meResponse struct {
	User       userJSON        `json:"user"`
	Premium    premiumJSON     `json:"premium"`
	Streak     streakJSON      `json:"streak"`
	Wallet     walletJSON      `json:"wallet"`
	Assessment *assessmentJSON `json:"assessment"`
	Monsters   []monsterJSON   `json:"monsters"`
	Inventory  inventoryJSON   `json:"inventory"`
	Loadouts   loadoutsJSON    `json:"loadouts"`
	Today      todayJSON       `json:"today"`
}

type inventoryJSON struct {
	Items        []string `json:"items"`
	PrepaidFocus int      `json:"prepaidFocus"`
}

type loadoutsJSON struct {
	Monsters   map[string][]string             `json:"monsters"`
	Characters map[string]characterLoadoutJSON `json:"characters"`
}

// billingAccountID is the obfuscated account id the app passes to Play
// (applicationUserName); only the server knows the key (spec §3.9).
func (s *Server) billingAccountID(userID string) string {
	return billing.AccountID(s.Config.BillingAccountKey, userID)
}

func (s *Server) userJSON(u store.User) userJSON {
	return userJSON{
		ID: u.ID, BillingAccountID: s.billingAccountID(u.ID), IsAnonymous: u.IsAnonymous,
		DisplayName: u.DisplayName, AvatarID: u.AvatarID, Locale: u.Locale, Persona: u.Persona,
		TZ: u.TZ, OnboardingDone: u.OnboardingDone, CreatedAt: u.CreatedAt.UTC(),
	}
}

// localDay is "today" in the user's time zone, as a UTC-midnight date value.
func localDay(now time.Time, tz string) time.Time { return rules.LocalDay(now, tz) }

func (s *Server) premiumJSON(sub *store.Subscription, now time.Time) premiumJSON {
	p := rules.PremiumStatus(sub, now, s.Economy.Premium.GraceDays)
	return premiumJSON{Status: p.Status, Plan: p.Plan, ExpiresAt: p.ExpiresAt, AutoRenewing: p.AutoRenewing}
}

func isPremium(p premiumJSON) bool { return rules.Premium{Status: p.Status}.Active() }

func (s *Server) meResponse(snap store.Snapshot, day time.Time) meResponse {
	now := s.now()
	prem := s.premiumJSON(snap.Subscription, now)

	resp := meResponse{
		User:    s.userJSON(snap.User),
		Premium: prem,
		Streak: streakJSON{
			Current: snap.Streak.CurrentDays, Longest: snap.Streak.LongestDays,
			Shields: snap.Consumables["streak_shield"],
		},
		Wallet: walletJSON{
			Coins: snap.Wallet.Coins(), EarnedCoins: snap.Wallet.EarnedCoins, PurchasedCoins: snap.Wallet.PurchasedCoins,
		},
		Monsters:  []monsterJSON{},
		Inventory: inventoryJSON{Items: snap.Inventory, PrepaidFocus: snap.Consumables["prepaid_focus"]},
		Loadouts:  loadoutsJSON{Monsters: snap.MonsterLoadouts, Characters: map[string]characterLoadoutJSON{}},
	}
	if snap.Streak.LastCheckinDate != nil {
		d := snap.Streak.LastCheckinDate.Format(time.DateOnly)
		resp.Streak.LastCheckinDate = &d
	}
	if a := snap.Assessment; a != nil {
		resp.Assessment = &assessmentJSON{DominantSaboteurs: a.DominantSaboteurs, Scores: a.Scores, CompletedAt: a.CompletedAt}
	}
	for _, m := range snap.Monsters {
		resp.Monsters = append(resp.Monsters, monsterJSON{SaboteurID: m.SaboteurID, State: m.State, Progress: m.Progress, TamedAt: m.TamedAt})
	}
	for test, l := range snap.CharacterLoadouts {
		resp.Loadouts.Characters[test] = characterLoadoutJSON{Accessories: l.AccessoryIDs, CardStyle: l.CardStyle}
	}

	freeFocus := s.Economy.FreeTier.FocusPerDay
	if isPremium(prem) {
		freeFocus = s.Economy.Premium.FocusFreePerDay
	}
	resp.Today = todayJSON{
		Date:                day.Format(time.DateOnly),
		MissionsDone:        store.MissionsDone(snap.Counters),
		FreeFocusLeft:       max(0, freeFocus-snap.Counters[store.CounterFocusFree]),
		PaidUnlocksUsed:     snap.Counters[store.CounterAppBekuPaid],
		FightsToday:         snap.Counters[store.CounterMinigame],
		PremiumDailyClaimed: snap.Counters[store.CounterPremiumDaily] > 0,
	}
	return resp
}

// --- GET /v1/me ----------------------------------------------------------------------

func (s *Server) getMe(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	day := localDay(s.now(), c.User.TZ)
	snap, err := s.Store.Snapshot(r.Context(), c.User.ID, day)
	if err != nil {
		s.internalError(w, r, "snapshot", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, s.meResponse(snap, day))
}

// --- PATCH /v1/me/profile ----------------------------------------------------------------

type profileRequest struct {
	DisplayName    *string `json:"displayName"`
	AvatarID       *string `json:"avatarId"`
	Locale         *string `json:"locale"`
	Persona        *string `json:"persona"`
	OnboardingDone *bool   `json:"onboardingDone"`
	TZ             *string `json:"tz"`
}

func (s *Server) patchProfile(w http.ResponseWriter, r *http.Request) {
	var req profileRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if req.DisplayName != nil {
		name := strings.TrimSpace(*req.DisplayName)
		if utf8.RuneCountInString(name) > 40 || strings.IndexFunc(name, unicode.IsControl) >= 0 {
			httpx.WriteError(w, r, invalid("displayName must be at most 40 characters without control characters", "displayName"))
			return
		}
		req.DisplayName = &name
	}
	if req.AvatarID != nil && !avatarIDs[*req.AvatarID] {
		httpx.WriteError(w, r, invalid("unknown avatarId", "avatarId"))
		return
	}
	if req.Locale != nil && !locales[*req.Locale] {
		httpx.WriteError(w, r, invalid("locale must be id or en", "locale"))
		return
	}
	if req.Persona != nil && !personas[*req.Persona] {
		httpx.WriteError(w, r, invalid("unknown persona", "persona"))
		return
	}
	if req.TZ != nil && !validTZ(*req.TZ) {
		httpx.WriteError(w, r, invalid("tz must be an IANA time zone such as Asia/Jakarta", "tz"))
		return
	}
	c := callerFrom(r.Context())
	u, err := s.Store.UpdateProfile(r.Context(), c.User.ID, store.ProfilePatch{
		DisplayName: req.DisplayName, AvatarID: req.AvatarID, Locale: req.Locale,
		Persona: req.Persona, OnboardingDone: req.OnboardingDone, TZ: req.TZ,
	})
	if err != nil {
		s.internalError(w, r, "update_profile", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"user": s.userJSON(u)})
}

func validTZ(tz string) bool {
	if tz == "" || len(tz) > 64 || tz == "Local" || !strings.Contains(tz, "/") && tz != "UTC" {
		return false
	}
	_, err := time.LoadLocation(tz)
	return err == nil
}

// --- PUT /v1/me/assessment ------------------------------------------------------------------

type assessmentRequest struct {
	DominantSaboteurs []string       `json:"dominantSaboteurs"`
	Scores            map[string]int `json:"scores"`
	CompletedAt       *time.Time     `json:"completedAt"`
}

func (s *Server) putAssessment(w http.ResponseWriter, r *http.Request) {
	var req assessmentRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if len(req.DominantSaboteurs) == 0 || len(req.DominantSaboteurs) > len(saboteurIDs) {
		httpx.WriteError(w, r, invalid("dominantSaboteurs must list 1–7 saboteurs", "dominantSaboteurs"))
		return
	}
	seen := map[string]bool{}
	for _, id := range req.DominantSaboteurs {
		if !saboteurIDs[id] || seen[id] {
			httpx.WriteError(w, r, invalid("dominantSaboteurs has an unknown or repeated id", "dominantSaboteurs"))
			return
		}
		seen[id] = true
	}
	if req.Scores == nil {
		req.Scores = map[string]int{}
	}
	for id, v := range req.Scores {
		if !saboteurIDs[id] || v < 0 || v > 100 {
			httpx.WriteError(w, r, invalid("scores must map saboteur ids to 0–100", "scores"))
			return
		}
	}
	if req.CompletedAt != nil && req.CompletedAt.After(s.now().Add(5*time.Minute)) {
		httpx.WriteError(w, r, invalid("completedAt is in the future", "completedAt"))
		return
	}
	c := callerFrom(r.Context())
	a := store.Assessment{DominantSaboteurs: req.DominantSaboteurs, Scores: req.Scores, CompletedAt: req.CompletedAt}
	if err := s.Store.PutAssessment(r.Context(), c.User.ID, a); err != nil {
		s.internalError(w, r, "put_assessment", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"assessment": assessmentJSON{
		DominantSaboteurs: a.DominantSaboteurs, Scores: a.Scores, CompletedAt: a.CompletedAt,
	}})
}

// --- POST /v1/me/link -------------------------------------------------------------------------

func (s *Server) postLink(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	if c.Identity.IsAnonymous() {
		httpx.WriteError(w, r, invalid("the token is still anonymous; link the account in Firebase first"))
		return
	}
	u, err := s.Store.MarkPermanent(r.Context(), c.User.ID)
	if err != nil {
		s.internalError(w, r, "mark_permanent", err)
		return
	}
	s.logInfo(r, logx.EventAccountLinked, "account linked",
		slog.String(logx.KeyUser, s.Hasher.User(u.ID)), slog.String("provider", c.Identity.SignInProvider))
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"user": s.userJSON(u)})
}

// --- DELETE /v1/me ------------------------------------------------------------------------------

// deleteMe removes server data first, then the Firebase account. If the
// Firebase call fails the client retries; with no user row left the retry
// only deletes the Firebase account. Either way the answer is idempotent.
func (s *Server) deleteMe(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	ctx := r.Context()
	if c.User != nil {
		err := s.Store.DeleteUser(ctx, c.User.ID, s.Hasher.User(c.User.ID))
		if err != nil && !errors.Is(err, store.ErrNotFound) {
			s.internalError(w, r, "delete_user", err)
			return
		}
		s.logInfo(r, logx.EventAccountDeleted, "account deleted",
			slog.String(logx.KeyUser, s.Hasher.User(c.User.ID)), slog.Bool("anonymous", c.User.IsAnonymous))
	}
	if err := s.Verifier.DeleteUser(ctx, c.Identity.Subject); err != nil {
		s.Logger.LogAttrs(ctx, slog.LevelError, "auth provider delete failed",
			slog.String(logx.KeyEvent, logx.EventDependencyError),
			slog.String(logx.KeyRequestID, httpx.RequestIDFrom(ctx)),
			slog.String("dependency", "firebase"), slog.String("op", "delete_user"), slog.String("error", err.Error()))
		httpx.WriteError(w, r, httpx.ErrUnavailable)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- GET /v1/me/export --------------------------------------------------------------------------

func (s *Server) getExport(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	day := localDay(s.now(), c.User.TZ)
	ex, err := s.Store.Export(r.Context(), c.User.ID, day)
	if err != nil {
		s.internalError(w, r, "export", err)
		return
	}
	w.Header().Set("Content-Disposition", `attachment; filename="riung-data.json"`)
	httpx.WriteJSON(w, http.StatusOK, map[string]any{
		"exportedAt":          s.now().UTC(),
		"account":             s.meResponse(ex.Snapshot, day),
		"coinHistory":         ex.Ledger,
		"purchases":           ex.Purchases,
		"bettermeCompleted":   ex.BettermeCompleted,
		"hasJournalPinBackup": ex.HasJournalPinBackup,
		"paidAppBekuUnlocks":  ex.PaidAppBekuUnlocks,
		"focusTicketsIssued":  ex.FocusTicketsIssued,
		"note":                "Journal entries, check-in notes, Kenali Dirimu results and sleep data are stored only on your phone and are not included.",
	})
}
