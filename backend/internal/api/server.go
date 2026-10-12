// Package api wires the HTTP endpoints of docs/backend-api-spec.md onto the
// shared middleware (httpx) and the data layer (store).
package api

import (
	"log/slog"
	"net/http"
	"time"
	_ "time/tzdata" // distroless has no zoneinfo; users.tz must always resolve

	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/billing"
	"github.com/krisna-achmad31/riung/backend/internal/catalog"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/health"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/ratelimit"
	"github.com/krisna-achmad31/riung/backend/internal/rules"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Deps are the API's collaborators.
type Deps struct {
	Config   config.Config
	Logger   *slog.Logger
	Hasher   logx.Hasher
	Store    *store.Store
	Verifier authn.Verifier
	AppCheck authn.AppChecker
	Economy  economy.Props
	Catalog  *catalog.Catalog
	Limiter  *ratelimit.Limiter
	// Settings is shared with the Admin API so changes apply at once.
	// Optional: built from Store when nil.
	Settings *settings.Cache
	// Billing verifies Play purchases; nil = billing not configured (503).
	Billing *billing.Service
	// Push authenticates RTDN Pub/Sub pushes.
	Push billing.PushVerifier
	// Now is the clock (tests inject a fixed one). Defaults to time.Now.
	Now func() time.Time
}

// Server holds the dependencies used by handlers.
type Server struct {
	Deps
	settings     *settings.Cache
	rules        *rules.Service
	billingSvc   *billing.Service
	publicConfig configResponse
}

func newServer(d Deps) *Server {
	if d.Now == nil {
		d.Now = time.Now
	}
	if d.Settings == nil {
		d.Settings = settings.NewCache(d.Store, d.Economy.Caps, 30*time.Second, d.Now)
	}
	if d.Catalog == nil {
		d.Catalog = catalog.MustLoad(d.Economy)
	}
	s := &Server{Deps: d, settings: d.Settings}
	s.rules = &rules.Service{Store: d.Store, Economy: d.Economy, Catalog: d.Catalog, Settings: d.Settings, Now: d.Now}
	s.billingSvc = d.Billing
	if s.billingSvc == nil {
		s.billingSvc = &billing.Service{Store: d.Store, Economy: d.Economy, Hasher: d.Hasher, AccountKey: d.Config.BillingAccountKey, Now: d.Now}
	}
	s.publicConfig = buildPublicConfig(d)
	return s
}

// DefaultBodyLimit applies to every route that does not set its own
// (applied per route: a global limit would cap the larger ones too).
const DefaultBodyLimit = 16 << 10

// NewHandler builds the full HTTP handler: global middleware + routes.
func NewHandler(d Deps) http.Handler {
	s := newServer(d)

	mux := http.NewServeMux()
	mux.Handle("GET /healthz", health.Live())
	mux.Handle("GET /readyz", health.Ready(d.Store, d.Logger))
	s.routes(mux)

	return httpx.Chain(httpx.Router(mux),
		httpx.RealIP(d.Config.TrustedProxies),
		httpx.RequestID,
		httpx.AccessLog(d.Logger, d.Hasher),
		httpx.Recover(d.Logger),
		httpx.SecurityHeaders,
	)
}

func (s *Server) routes(mux *http.ServeMux) {
	// §3.1 System & public
	s.handle(mux, "GET /v1/config", s.getConfig, route{access: accessApp, limits: []ratelimit.Policy{rlConfig}})
	s.handle(mux, "GET /v1/content/{kind}", s.getContent, route{access: accessApp, limits: []ratelimit.Policy{rlContent}})
	s.handle(mux, "POST /v1/waitlist", s.postWaitlist, route{access: accessPublic, limits: []ratelimit.Policy{rlWaitlist}, bodyLimit: 2 << 10, cors: true})
	s.handle(mux, "OPTIONS /v1/waitlist", s.waitlistPreflight, route{access: accessPublic, cors: true})

	// §3.2 Account & profile
	s.handle(mux, "GET /v1/me", s.getMe, route{access: accessUser, limits: []ratelimit.Policy{rlMe}})
	s.handle(mux, "PATCH /v1/me/profile", s.patchProfile, route{access: accessUser, limits: []ratelimit.Policy{rlProfile}, idempotent: true})
	s.handle(mux, "PUT /v1/me/assessment", s.putAssessment, route{access: accessUser, limits: []ratelimit.Policy{rlAssessment}, idempotent: true})
	s.handle(mux, "POST /v1/me/link", s.postLink, route{access: accessUser, checkRevoked: true, limits: []ratelimit.Policy{rlLink}, idempotent: true})
	s.handle(mux, "DELETE /v1/me", s.deleteMe, route{access: accessUser, fresh: true, noCreate: true, limitedUseAppCheck: true, limits: []ratelimit.Policy{rlDelete}})
	s.handle(mux, "GET /v1/me/export", s.getExport, route{access: accessUser, limits: []ratelimit.Policy{rlExport}})
	s.handle(mux, "GET /v1/me/journal-pin-backup", s.getPinBackup, route{access: accessPermanent, limits: []ratelimit.Policy{rlPinRead}})
	s.handle(mux, "PUT /v1/me/journal-pin-backup", s.putPinBackup, route{access: accessPermanent, limits: []ratelimit.Policy{rlPinWrite}, idempotent: true})
	s.handle(mux, "DELETE /v1/me/journal-pin-backup", s.deletePinBackup, route{access: accessPermanent, limits: []ratelimit.Policy{rlPinWrite}, idempotent: true})
	s.handle(mux, "POST /v1/me/journal-pin-backup/verify", s.verifyPin, route{access: accessPermanent, limitedUseAppCheck: true, limits: []ratelimit.Policy{rlPinVerify}})

	// §3.3 Practice events
	s.handle(mux, "POST /v1/activities", s.postActivity, route{access: accessUser, limits: []ratelimit.Policy{rlActivity}, idempotent: true})
	s.handle(mux, "POST /v1/activities/batch", s.postActivityBatch, route{access: accessUser, limits: []ratelimit.Policy{rlActivityBatch}, idempotent: true, bodyLimit: 64 << 10})
	// §3.4 Journal
	s.handle(mux, "GET /v1/journal/access", s.getJournalAccess, route{access: accessUser, limits: []ratelimit.Policy{rlJournal}})
	// §3.5 Wallet & premium daily coins
	s.handle(mux, "GET /v1/wallet", s.getWallet, route{access: accessUser, limits: []ratelimit.Policy{rlWallet}})
	s.handle(mux, "GET /v1/wallet/transactions", s.getTransactions, route{access: accessUser, limits: []ratelimit.Policy{rlTransactions}})
	s.handle(mux, "POST /v1/premium/daily-coins", s.postPremiumDaily, route{access: accessPermanent, limits: []ratelimit.Policy{rlPremiumDaily}, idempotent: true})
	// §3.6 Shop & loadouts
	s.handle(mux, "POST /v1/shop/purchase", s.postPurchase, route{access: accessUser, limits: []ratelimit.Policy{rlShop}, idempotent: true})
	s.handle(mux, "PUT /v1/loadouts/monsters/{saboteurId}", s.putMonsterLoadout, route{access: accessUser, limits: []ratelimit.Policy{rlLoadout}, idempotent: true})
	s.handle(mux, "PUT /v1/loadouts/characters/{testId}", s.putCharacterLoadout, route{access: accessUser, limits: []ratelimit.Policy{rlLoadout}, idempotent: true})

	// §3.9 Google Play billing
	s.handle(mux, "POST /v1/billing/verify", s.postBillingVerify, route{access: accessPermanent, checkRevoked: true, limitedUseAppCheck: true, limits: []ratelimit.Policy{rlVerifyMin, rlVerifyHour}, idempotent: true})
	s.handle(mux, "POST /v1/billing/restore", s.postBillingRestore, route{access: accessPermanent, limits: []ratelimit.Policy{rlRestore}, idempotent: true})
	s.handle(mux, "GET /v1/billing/subscription", s.getSubscription, route{access: accessUser, limits: []ratelimit.Policy{rlSubscription}})
	s.handle(mux, "POST /v1/webhooks/google-play", s.postPlayWebhook, route{access: accessPublic, bodyLimit: 256 << 10})
}

func (s *Server) now() time.Time { return s.Now() }
