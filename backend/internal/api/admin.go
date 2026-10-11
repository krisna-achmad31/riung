package api

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"strconv"
	"time"
	"unicode/utf8"

	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/ratelimit"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Admin API (docs/backend-api-spec.md §3.11). Served on its own listener
// (ADMIN_LISTEN_ADDR) that nginx never proxies, accepts connections only from
// ADMIN_ALLOWED_CIDRS (the office VPN), and requires a fresh Firebase sign-in
// with the riungAdmin claim by a user listed in the admins table.

const (
	adminAuthMaxAge = 15 * time.Minute
	adminBodyLimit  = 8 << 10

	eventAdminSettingChanged = "admin_setting_changed"
	eventAdminAccessDenied   = "admin_access_denied"
)

// NewAdminHandler builds the Admin API handler. Pass the same Settings cache
// as the public API so changes take effect immediately.
func NewAdminHandler(d Deps) http.Handler {
	s := newServer(d)
	mux := http.NewServeMux()
	s.adminRoute(mux, "GET /admin/v1/settings", s.adminListSettings, rlAdminRead, false)
	s.adminRoute(mux, "PUT /admin/v1/settings/{key}", s.adminPutSetting, rlAdminWrite, true)
	s.adminRoute(mux, "DELETE /admin/v1/settings/{key}", s.adminResetSetting, rlAdminWrite, true)
	s.adminRoute(mux, "GET /admin/v1/audit", s.adminAudit, rlAdminRead, false)

	return httpx.Chain(httpx.Router(mux),
		s.adminSourceAllowlist,
		httpx.RealIP(nil), // direct connections only: never trust forwarded headers here
		httpx.RequestID,
		httpx.AccessLog(d.Logger, d.Hasher),
		httpx.Recover(d.Logger),
		httpx.SecurityHeaders,
		httpx.LimitBody(adminBodyLimit),
	)
}

var errAdminForbidden = httpx.NewError(http.StatusForbidden, httpx.CodeForbidden, "admin access denied")

// adminSourceAllowlist drops connections from outside the allowed networks
// before any parsing or authentication happens.
func (s *Server) adminSourceAllowlist(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		host, _, err := net.SplitHostPort(r.RemoteAddr)
		addr, perr := netip.ParseAddr(host)
		if err != nil || perr != nil || !inAny(addr.Unmap(), s.Config.AdminAllowedCIDRs) {
			s.Logger.LogAttrs(r.Context(), slog.LevelWarn, "admin access denied",
				slog.String(logx.KeyEvent, eventAdminAccessDenied), slog.String("reason", "source_ip"))
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func inAny(a netip.Addr, ps []netip.Prefix) bool {
	for _, p := range ps {
		if p.Contains(a) {
			return true
		}
	}
	return false
}

func (s *Server) adminRoute(mux *http.ServeMux, pattern string, h http.HandlerFunc, limit ratelimit.Policy, idempotent bool) {
	var next http.Handler = h
	if idempotent {
		next = s.idempotency(pattern, next)
	}
	next = s.rateLimit([]ratelimit.Policy{limit}, next)
	next = s.adminAuth(next)
	mux.Handle(pattern, next)
}

func (s *Server) adminDenied(w http.ResponseWriter, r *http.Request, reason string) {
	s.logWarn(r, eventAdminAccessDenied, "admin access denied", slog.String("reason", reason))
	httpx.WriteError(w, r, errAdminForbidden)
}

func (s *Server) adminAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		id, err := s.Verifier.Verify(ctx, bearerToken(r), true)
		if err != nil {
			if errors.Is(err, authn.ErrUnavailable) {
				httpx.WriteError(w, r, httpx.ErrUnavailable)
				return
			}
			s.adminDenied(w, r, "invalid_token")
			return
		}
		switch {
		case id.IsAnonymous() || !id.EmailVerified:
			s.adminDenied(w, r, "not_verified")
			return
		case !id.Admin:
			s.adminDenied(w, r, "no_claim")
			return
		case s.now().Sub(id.AuthTime) > adminAuthMaxAge:
			s.adminDenied(w, r, "stale_token")
			return
		}
		u, err := s.Store.UserByIdentity(ctx, id.Provider, id.Subject)
		if errors.Is(err, store.ErrNotFound) {
			s.adminDenied(w, r, "not_listed")
			return
		}
		if err != nil {
			s.internalError(w, r, "admin_user", err)
			return
		}
		ok, err := s.Store.IsAdmin(ctx, u.ID)
		if err != nil {
			s.internalError(w, r, "admin_check", err)
			return
		}
		if !ok {
			s.adminDenied(w, r, "not_listed")
			return
		}
		if li := httpx.LogInfoFrom(ctx); li != nil {
			li.UserHash = s.Hasher.User(u.ID)
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(ctx, callerKey{}, &caller{Identity: id, User: &u})))
	})
}

type settingJSON struct {
	Key        string     `json:"key"`
	Value      int        `json:"value"`
	Default    int        `json:"default"`
	Min        int        `json:"min"`
	Max        int        `json:"max"`
	Overridden bool       `json:"overridden"`
	UpdatedAt  *time.Time `json:"updatedAt"`
	UpdatedBy  *string    `json:"updatedBy"`
}

func (s *Server) adminListSettings(w http.ResponseWriter, r *http.Request) {
	s.settings.Invalidate()
	rows, err := s.Store.SettingRows(r.Context())
	if err != nil {
		s.internalError(w, r, "settings", err)
		return
	}
	out := []settingJSON{}
	for _, v := range s.settings.All(r.Context()) {
		sj := settingJSON{Key: v.Key, Value: v.Value, Default: v.Default, Min: v.Min, Max: v.Max, Overridden: v.Overridden}
		if row, ok := rows[v.Key]; ok {
			at, by := row.UpdatedAt.UTC(), row.UpdatedBy
			sj.UpdatedAt, sj.UpdatedBy = &at, &by
		}
		out = append(out, sj)
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"settings": out})
}

type settingPutRequest struct {
	Value  *int   `json:"value"`
	Reason string `json:"reason"`
}

type settingResetRequest struct {
	Reason string `json:"reason"`
}

func validReason(s string) bool {
	n := utf8.RuneCountInString(s)
	return n >= 3 && n <= 500
}

func (s *Server) adminPutSetting(w http.ResponseWriter, r *http.Request) {
	key := r.PathValue("key")
	def, ok := s.settings.Def(key)
	if !ok {
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	var req settingPutRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if req.Value == nil || *req.Value < def.Min || *req.Value > def.Max {
		httpx.WriteError(w, r, invalid("value must be "+strconv.Itoa(def.Min)+"–"+strconv.Itoa(def.Max), "value"))
		return
	}
	if !validReason(req.Reason) {
		httpx.WriteError(w, r, invalid("reason must be 3–500 characters", "reason"))
		return
	}
	s.changeSetting(w, r, key, *req.Value, req.Reason)
}

func (s *Server) adminResetSetting(w http.ResponseWriter, r *http.Request) {
	key := r.PathValue("key")
	if _, ok := s.settings.Def(key); !ok {
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	var req settingResetRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if !validReason(req.Reason) {
		httpx.WriteError(w, r, invalid("reason must be 3–500 characters", "reason"))
		return
	}
	s.changeSetting(w, r, key, nil, req.Reason)
}

func (s *Server) changeSetting(w http.ResponseWriter, r *http.Request, key string, value any, reason string) {
	c := callerFrom(r.Context())
	actor := "admin:" + s.Hasher.User(c.User.ID)
	reqID := httpx.RequestIDFrom(r.Context())
	old, err := s.Store.ChangeSetting(r.Context(), store.SettingChange{
		Key: key, Value: value, Actor: actor, AdminUserID: &c.User.ID, Reason: reason, RequestID: &reqID,
	})
	if err != nil {
		s.internalError(w, r, "change_setting", err)
		return
	}
	s.settings.Invalidate()
	newVal := s.settings.Int(r.Context(), key)
	oldStr := "default"
	if len(old) > 0 {
		oldStr = string(old)
	}
	s.logWarn(r, eventAdminSettingChanged, "admin changed a setting",
		slog.String("key", key), slog.String("old", oldStr), slog.Int("new", newVal),
		slog.String("admin", s.Hasher.User(c.User.ID)), slog.String("reason", reason))
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"key": key, "value": newVal, "overridden": value != nil})
}

func (s *Server) adminAudit(w http.ResponseWriter, r *http.Request) {
	limit := 50
	if v := r.URL.Query().Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 200 {
			httpx.WriteError(w, r, invalid("limit must be 1–200", "limit"))
			return
		}
		limit = n
	}
	items, next, err := s.Store.AuditLog(r.Context(), limit, r.URL.Query().Get("cursor"))
	if errors.Is(err, store.ErrBadCursor) {
		httpx.WriteError(w, r, invalid("invalid cursor", "cursor"))
		return
	}
	if err != nil {
		s.internalError(w, r, "audit", err)
		return
	}
	var nextCursor *string
	if next != "" {
		nextCursor = &next
	}
	if items == nil {
		items = []store.AuditEntry{}
	}
	raw, _ := json.Marshal(items)
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"items": json.RawMessage(raw), "nextCursor": nextCursor})
}
