package api

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log/slog"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
)

// --- GET /v1/config ---------------------------------------------------------------

type configResponse struct {
	Version       string        `json:"version"`
	MinAppVersion string        `json:"minAppVersion"`
	ServerTime    time.Time     `json:"serverTime"`
	Economy       economyPublic `json:"economy"`
	Catalog       catalogPublic `json:"catalog"`
	// FocusTicketKeys verify Focus tickets offline (§3.7).
	FocusTicketKeys []ticketKey `json:"focusTicketKeys"`
}

// economyPublic is economy-props.json minus internal notes, with caps after
// admin overrides.
type economyPublic struct {
	Earn            economy.Earn            `json:"earn"`
	MonsterProgress economy.MonsterProgress `json:"monsterProgress"`
	Spend           economy.Spend           `json:"spend"`
	AppBeku         economy.AppBeku         `json:"appbeku"`
	Tickets         economy.Tickets         `json:"tickets"`
	FreeTier        economy.FreeTier        `json:"freeTier"`
	Premium         economy.Premium         `json:"premium"`
	CoinPacks       []economy.CoinPack      `json:"coinPacks"`
	Caps            capsPublic              `json:"caps"`
}

type capsPublic struct {
	MissionsPerDay          int `json:"missionsPerDay"`
	JournalRewardsPerDay    int `json:"journalRewardsPerDay"`
	MeditationRewardsPerDay int `json:"meditationRewardsPerDay"`
}

// catalogPublic is catalog.json with prices resolved (what the shop shows).
type catalogPublic struct {
	Version          string                    `json:"version"`
	Monsters         []catalog.Monster         `json:"monsters"`
	MonsterCosmetics []monsterCosmeticPublic   `json:"monsterCosmetics"`
	PersonalityTests []string                  `json:"personalityTests"`
	Accessories      []accessoryPublic         `json:"accessories"`
	AccessoryBundles []catalog.AccessoryBundle `json:"accessoryBundles"`
	CardStyles       []cardStylePublic         `json:"cardStyles"`
	FocusPacks       []focusPackPublic         `json:"focusPacks"`
	AppBeku          appBekuPublic             `json:"appbeku"`
	StreakShield     pricePublic               `json:"streakShield"`
	JournalPrompts   []catalog.JournalPrompt   `json:"journalPrompts"`
	Meditations      []catalog.Meditation      `json:"meditations"`
	Betterme         catalog.Betterme          `json:"betterme"`
}

type monsterCosmeticPublic struct {
	ID        string `json:"id"`
	MonsterID string `json:"monsterId"`
	Slot      string `json:"slot"`
	Exclusive bool   `json:"exclusive"`
	Price     int    `json:"price"`
}

type accessoryPublic struct {
	ID          string  `json:"id"`
	InventoryID string  `json:"inventoryId"`
	Slot        string  `json:"slot"`
	ExclusiveTo *string `json:"exclusiveTo"`
	Price       int     `json:"price"`
}

type cardStylePublic struct {
	ID          string `json:"id"`
	InventoryID string `json:"inventoryId"`
	Free        bool   `json:"free"`
	Price       *int   `json:"price"`
}

type focusPackPublic struct {
	ID       string `json:"id"`
	Sessions int    `json:"sessions"`
	Price    int    `json:"price"`
}

type appBekuPublic struct {
	Apps    []catalog.AppBekuApp  `json:"apps"`
	Units   []appBekuUnitPublic   `json:"units"`
	Bundles []appBekuBundlePublic `json:"bundles"`
}

type appBekuUnitPublic struct {
	Minutes int `json:"minutes"`
	Price   int `json:"price"`
}

type appBekuBundlePublic struct {
	ID            string                 `json:"id"`
	Price         int                    `json:"price"`
	Apps          []catalog.AppBekuGrant `json:"apps,omitempty"`
	Group         string                 `json:"group,omitempty"`
	MinutesPerApp int                    `json:"minutesPerApp,omitempty"`
}

type pricePublic struct {
	ItemID string `json:"itemId"`
	Price  int    `json:"price"`
}

func buildPublicConfig(d Deps) configResponse {
	e, c := d.Economy, d.Catalog
	pc := catalogPublic{
		Version: c.Version, Monsters: c.Monsters, PersonalityTests: c.PersonalityTests,
		AccessoryBundles: c.AccessoryBundles, JournalPrompts: c.JournalPrompts, Meditations: c.Meditations,
		Betterme: c.Betterme, StreakShield: pricePublic{ItemID: "streak_shield", Price: e.Spend.StreakShield},
	}
	for _, m := range c.MonsterCosmetics {
		pc.MonsterCosmetics = append(pc.MonsterCosmetics, monsterCosmeticPublic{ID: m.ID, MonsterID: m.MonsterID, Slot: m.Slot, Exclusive: m.Exclusive, Price: m.Price})
	}
	for _, a := range c.Accessories {
		pc.Accessories = append(pc.Accessories, accessoryPublic{ID: a.ID, InventoryID: a.InventoryID(), Slot: a.Slot, ExclusiveTo: a.ExclusiveTo, Price: a.Price})
	}
	for _, st := range c.CardStyles {
		cs := cardStylePublic{ID: st.ID, InventoryID: st.InventoryID(), Free: st.Free()}
		if !st.Free() {
			p := st.Price
			cs.Price = &p
		}
		pc.CardStyles = append(pc.CardStyles, cs)
	}
	for _, f := range c.FocusPacks {
		pc.FocusPacks = append(pc.FocusPacks, focusPackPublic{ID: f.ID, Sessions: f.Sessions, Price: f.Price})
	}
	// Base prices: the n-th paid unlock of a day costs escalationPerUnlock × (n−1) more.
	pc.AppBeku.Apps = c.AppBeku.Apps
	for _, u := range c.AppBeku.Units {
		pc.AppBeku.Units = append(pc.AppBeku.Units, appBekuUnitPublic{Minutes: u.Minutes, Price: u.Price})
	}
	for _, b := range c.AppBeku.Bundles {
		pc.AppBeku.Bundles = append(pc.AppBeku.Bundles, appBekuBundlePublic{ID: b.ID, Price: b.Price, Apps: b.Apps,
			Group: b.Group, MinutesPerApp: b.MinutesPerApp})
	}
	return configResponse{
		Version:       e.Version,
		MinAppVersion: d.Config.MinAppVersion,
		Economy: economyPublic{
			Earn: e.Earn, MonsterProgress: e.MonsterProgress, Spend: e.Spend, AppBeku: e.AppBeku,
			Tickets: e.Tickets, FreeTier: e.FreeTier, Premium: e.Premium, CoinPacks: e.CoinPacks,
		},
		Catalog: pc,
	}
}

func (s *Server) getConfig(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	resp := s.publicConfig
	resp.Economy.Caps = capsPublic{
		MissionsPerDay:          s.Economy.Caps.MissionsPerDay,
		JournalRewardsPerDay:    s.settings.Int(ctx, settings.JournalRewardsPerDay),
		MeditationRewardsPerDay: s.settings.Int(ctx, settings.MeditationRewardsPerDay),
	}
	tag := etag(s.Economy.Version, s.Catalog.Version, s.Config.MinAppVersion, s.settings.UpdatedAt(ctx).UTC().Format(time.RFC3339Nano),
		strconv.Itoa(resp.Economy.Caps.JournalRewardsPerDay), strconv.Itoa(resp.Economy.Caps.MeditationRewardsPerDay),
		fmt.Sprint(resp.FocusTicketKeys))
	if notModified(w, r, tag) {
		return
	}
	resp.ServerTime = s.now().UTC()
	httpx.WriteJSON(w, http.StatusOK, resp)
}

// etag builds a strong validator from parts.
func etag(parts ...string) string {
	sum := sha256.Sum256([]byte(strings.Join(parts, "\x00")))
	return `"` + hex.EncodeToString(sum[:])[:32] + `"`
}

// notModified sets ETag + revalidation headers and answers 304 when the
// client already has this version.
func notModified(w http.ResponseWriter, r *http.Request, tag string) bool {
	w.Header().Set("ETag", tag)
	w.Header().Set("Cache-Control", "no-cache")
	for _, t := range strings.Split(r.Header.Get("If-None-Match"), ",") {
		if strings.TrimSpace(t) == tag {
			w.WriteHeader(http.StatusNotModified)
			return true
		}
	}
	return false
}

// --- GET /v1/content/{kind} ------------------------------------------------------------

type contentResponse struct {
	Kind      string      `json:"kind"`
	Locale    string      `json:"locale"`
	UpdatedAt *time.Time  `json:"updatedAt"`
	Items     interface{} `json:"items"`
}

func (s *Server) getContent(w http.ResponseWriter, r *http.Request) {
	kind := r.PathValue("kind")
	if !contentKinds[kind] {
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	locale := r.URL.Query().Get("locale")
	if locale == "" {
		locale = "id"
	}
	if !locales[locale] {
		httpx.WriteError(w, r, invalid("locale must be id or en", "locale"))
		return
	}
	list, err := s.Store.Content(r.Context(), kind, locale)
	if err != nil {
		s.internalError(w, r, "content", err)
		return
	}
	if len(list.Items) == 0 && locale != "id" {
		// Content is authored in Indonesian first; fall back rather than show nothing.
		locale = "id"
		if list, err = s.Store.Content(r.Context(), kind, locale); err != nil {
			s.internalError(w, r, "content", err)
			return
		}
	}
	if notModified(w, r, list.ETag) {
		return
	}
	resp := contentResponse{Kind: kind, Locale: locale, Items: list.Items}
	if !list.UpdatedAt.IsZero() {
		t := list.UpdatedAt.UTC()
		resp.UpdatedAt = &t
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}

// --- POST /v1/waitlist ------------------------------------------------------------------

type waitlistRequest struct {
	Email  string `json:"email"`
	Lang   string `json:"lang"`
	Source string `json:"source"`
	// Website is a honeypot: hidden on the landing page, so only bots fill it.
	Website string `json:"website"`
}

var (
	emailPattern  = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]{2,}$`)
	langPattern   = regexp.MustCompile(`^[a-z]{2}(-[A-Za-z]{2})?$`)
	sourcePattern = regexp.MustCompile(`^[a-z0-9_-]{1,32}$`)
)

// postWaitlist always answers 202 for a well-formed request — new email,
// duplicate or honeypot alike — so it cannot be used to probe who signed up.
func (s *Server) postWaitlist(w http.ResponseWriter, r *http.Request) {
	var req waitlistRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	email := strings.ToLower(strings.TrimSpace(req.Email))
	if len(email) > 254 || !emailPattern.MatchString(email) {
		httpx.WriteError(w, r, invalid("email is not valid", "email"))
		return
	}
	if req.Lang != "" && !langPattern.MatchString(req.Lang) {
		httpx.WriteError(w, r, invalid("lang is not valid", "lang"))
		return
	}
	if req.Source != "" && !sourcePattern.MatchString(req.Source) {
		httpx.WriteError(w, r, invalid("source is not valid", "source"))
		return
	}
	accepted := map[string]string{"status": "accepted"}
	if req.Website != "" {
		s.logWarn(r, logx.EventWaitlistSignup, "waitlist honeypot triggered", slog.Bool("honeypot", true))
		httpx.WriteJSON(w, http.StatusAccepted, accepted)
		return
	}
	isNew, err := s.Store.AddWaitlist(r.Context(), email, req.Lang, req.Source)
	if err != nil {
		s.internalError(w, r, "waitlist", err)
		return
	}
	s.logInfo(r, logx.EventWaitlistSignup, "waitlist signup",
		slog.String("email", s.Hasher.Value("e_", email)), slog.Bool("new", isNew))
	httpx.WriteJSON(w, http.StatusAccepted, accepted)
}

// waitlistPreflight answers CORS preflight (headers are set by the cors middleware).
func (s *Server) waitlistPreflight(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusNoContent)
}

func invalid(msg string, fields ...string) *httpx.APIError {
	return httpx.NewError(http.StatusBadRequest, httpx.CodeInvalidRequest, msg).
		WithDetails(map[string]any{"fields": fields})
}
