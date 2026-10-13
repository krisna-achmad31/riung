package api

import (
	"bytes"
	"context"
	"crypto/sha256"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/authn"
	"github.com/krisna-achmad31/riung/backend/internal/config"
	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/ratelimit"
	"github.com/krisna-achmad31/riung/backend/internal/settings"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

type access int

const (
	accessPublic    access = iota // no App Check, no login
	accessApp                     // App Check only
	accessUser                    // App Check + ID token (anonymous allowed)
	accessPermanent               // accessUser + non-anonymous account
)

// route declares how an endpoint is protected.
type route struct {
	access access
	// checkRevoked asks Firebase whether the token was revoked / user disabled.
	checkRevoked bool
	// fresh implies checkRevoked and, for permanent accounts, a sign-in no
	// older than freshAuthMaxAge.
	fresh bool
	// noCreate: do not auto-create an unknown identity (caller.User may be nil).
	noCreate bool
	// limitedUseAppCheck rejects a replayed App Check token (enforce mode).
	limitedUseAppCheck bool
	limits             []ratelimit.Policy
	idempotent         bool
	bodyLimit          int64
	cors               bool
}

// caller is the authenticated principal of a request.
type caller struct {
	Identity authn.Identity
	User     *store.User
	Created  bool
}

type callerKey struct{}

func callerFrom(ctx context.Context) *caller {
	c, _ := ctx.Value(callerKey{}).(*caller)
	return c
}

// handle registers pattern with the protections in rt, outermost first:
// CORS → body limit → min app version → App Check → auth (local token check)
// → rate limit → revocation check → idempotency → handler. The revocation
// check calls Firebase, so it runs only for requests within the rate limit.
func (s *Server) handle(mux *http.ServeMux, pattern string, h http.HandlerFunc, rt route) {
	var next http.Handler = h
	if rt.idempotent {
		next = s.idempotency(pattern, next)
	}
	if rt.access >= accessUser && (rt.checkRevoked || rt.fresh) {
		next = s.revocation(next)
	}
	if len(rt.limits) > 0 {
		next = s.rateLimit(rt.limits, next)
	}
	if rt.access >= accessUser {
		next = s.authenticate(rt, next)
	}
	if rt.access >= accessApp {
		next = s.appCheck(rt, next)
	}
	if rt.access != accessPublic {
		next = s.minAppVersion(next)
	}
	limit := rt.bodyLimit
	if limit == 0 {
		limit = DefaultBodyLimit
	}
	next = httpx.LimitBody(limit)(next)
	if rt.cors {
		next = s.cors(next)
	}
	mux.Handle(pattern, next)
}

func (s *Server) logWarn(r *http.Request, event, msg string, attrs ...slog.Attr) {
	attrs = append([]slog.Attr{
		slog.String(logx.KeyEvent, event),
		slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
	}, attrs...)
	s.Logger.LogAttrs(r.Context(), slog.LevelWarn, msg, attrs...)
}

func (s *Server) logInfo(r *http.Request, event, msg string, attrs ...slog.Attr) {
	attrs = append([]slog.Attr{
		slog.String(logx.KeyEvent, event),
		slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
	}, attrs...)
	s.Logger.LogAttrs(r.Context(), slog.LevelInfo, msg, attrs...)
}

// internalError logs err and answers 500 without details.
func (s *Server) internalError(w http.ResponseWriter, r *http.Request, op string, err error) {
	s.Logger.LogAttrs(r.Context(), slog.LevelError, "internal error",
		slog.String(logx.KeyEvent, logx.EventDependencyError),
		slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
		slog.String("op", op),
		slog.String("error", err.Error()),
	)
	httpx.WriteError(w, r, httpx.ErrInternal)
}

// --- min app version -------------------------------------------------------

func (s *Server) minAppVersion(next http.Handler) http.Handler {
	minV, _ := config.ParseVersion(s.Config.MinAppVersion)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if v, ok := config.ParseVersion(r.Header.Get("X-App-Version")); ok && versionLess(v, minV) {
			httpx.WriteError(w, r, httpx.NewError(http.StatusUpgradeRequired, httpx.CodeUpgradeRequired, "app version too old").
				WithDetails(map[string]any{"minAppVersion": s.Config.MinAppVersion}))
			return
		}
		next.ServeHTTP(w, r)
	})
}

func versionLess(a, b [3]int) bool {
	for i := range a {
		if a[i] != b[i] {
			return a[i] < b[i]
		}
	}
	return false
}

// --- App Check -----------------------------------------------------------------

var errAppCheck = httpx.NewError(http.StatusUnauthorized, httpx.CodeAppCheckFailed, "app check failed")

func (s *Server) appCheck(rt route, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mode := s.Config.AppCheckMode
		if mode == config.AppCheckOff {
			next.ServeHTTP(w, r)
			return
		}
		tok, err := s.AppCheck.Verify(r.Context(), r.Header.Get("X-Firebase-AppCheck"))
		reason := ""
		li := httpx.LogInfoFrom(r.Context())
		outcome := func(v string) {
			if li != nil {
				li.AppCheck = v
			}
		}
		switch {
		case errors.Is(err, authn.ErrUnavailable):
			outcome("unavailable")
			// Cannot judge the token right now: never block in monitor mode,
			// ask the client to retry in enforce mode.
			s.Logger.LogAttrs(r.Context(), slog.LevelError, "app check unavailable",
				slog.String(logx.KeyEvent, logx.EventDependencyError),
				slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
				slog.String("dependency", "firebase_app_check"), slog.String("error", err.Error()))
			if mode == config.AppCheckEnforce {
				httpx.WriteError(w, r, httpx.ErrUnavailable)
				return
			}
			next.ServeHTTP(w, r)
			return
		case err != nil:
			reason = "invalid"
			if r.Header.Get("X-Firebase-AppCheck") == "" {
				reason = "missing"
			}
		case rt.limitedUseAppCheck && tok.JTI != "":
			// Checked in monitor mode too, so replays show up in the logs
			// before enforce is switched on.
			fresh, err := s.Store.ConsumeAppCheckJTI(r.Context(), tok.JTI, tok.ExpiresAt)
			if err != nil {
				s.internalError(w, r, "appcheck_jti", err)
				return
			}
			if !fresh {
				reason = "replayed"
			}
		}
		if reason == "" {
			outcome("valid")
		} else {
			outcome(reason)
			s.logWarn(r, logx.EventAppCheckFailed, "app check failed",
				slog.String("reason", reason), slog.String("mode", mode))
			if mode == config.AppCheckEnforce {
				httpx.WriteError(w, r, errAppCheck)
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}

// --- authentication ------------------------------------------------------------

var (
	errUnauthenticated   = httpx.NewError(http.StatusUnauthorized, httpx.CodeUnauthenticated, "authentication required")
	errRecentLogin       = httpx.NewError(http.StatusUnauthorized, httpx.CodeRecentLoginRequired, "sign in again to continue")
	errPermanentRequired = httpx.NewError(http.StatusForbidden, httpx.CodePermanentAccountRequired, "a registered account is required")
	errSignupLimited     = httpx.NewError(http.StatusTooManyRequests, httpx.CodeSignupLimited, "too many new accounts from this network today")
)

func bearerToken(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "Bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

// revocation re-verifies the token with a revocation check (a Firebase call)
// for sensitive routes, after the rate limit.
func (s *Server) revocation(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		if _, err := s.Verifier.Verify(ctx, bearerToken(r), true); err != nil {
			if errors.Is(err, authn.ErrUnavailable) {
				s.Logger.LogAttrs(ctx, slog.LevelError, "auth provider unavailable",
					slog.String(logx.KeyEvent, logx.EventDependencyError),
					slog.String(logx.KeyRequestID, httpx.RequestIDFrom(ctx)),
					slog.String("dependency", "firebase"), slog.String("error", err.Error()))
				httpx.WriteError(w, r, httpx.ErrUnavailable)
				return
			}
			reason := "invalid"
			if errors.Is(err, authn.ErrRevoked) {
				reason = "revoked"
			}
			s.logWarn(r, logx.EventAuthFailed, "authentication failed", slog.String("reason", reason))
			httpx.WriteError(w, r, errUnauthenticated)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) authenticate(rt route, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		id, err := s.Verifier.Verify(ctx, bearerToken(r), false)
		if err != nil {
			if errors.Is(err, authn.ErrUnavailable) {
				s.Logger.LogAttrs(ctx, slog.LevelError, "auth provider unavailable",
					slog.String(logx.KeyEvent, logx.EventDependencyError),
					slog.String(logx.KeyRequestID, httpx.RequestIDFrom(ctx)),
					slog.String("dependency", "firebase"), slog.String("error", err.Error()))
				httpx.WriteError(w, r, httpx.ErrUnavailable)
				return
			}
			reason := "invalid"
			switch {
			case bearerToken(r) == "":
				reason = "missing"
			case errors.Is(err, authn.ErrRevoked):
				reason = "revoked"
			}
			s.logWarn(r, logx.EventAuthFailed, "authentication failed", slog.String("reason", reason))
			httpx.WriteError(w, r, errUnauthenticated)
			return
		}
		if rt.fresh && !id.IsAnonymous() && s.now().Sub(id.AuthTime) > freshAuthMaxAge {
			s.logWarn(r, logx.EventAuthFailed, "recent sign-in required", slog.String("reason", "stale_auth_time"))
			httpx.WriteError(w, r, errRecentLogin)
			return
		}

		now := s.now()
		u, created, err := s.Store.ResolveUser(ctx, store.ResolveParams{
			Provider:    id.Provider,
			Subject:     id.Subject,
			Anonymous:   id.IsAnonymous(),
			Create:      !rt.noCreate,
			IPHash:      s.Hasher.IP(httpx.ClientIPFrom(ctx), now),
			Day:         utcDay(now),
			SignupLimit: s.settings.Int(ctx, settings.MaxNewAccountsPerIPPerDay),
		})
		c := &caller{Identity: id}
		switch {
		case err == nil:
			c.User, c.Created = &u, created
		case errors.Is(err, store.ErrNotFound) && rt.noCreate:
		case errors.Is(err, store.ErrSignupLimited):
			s.logWarn(r, logx.EventSignupLimited, "signup limit reached",
				slog.Int("limit", s.settings.Int(ctx, settings.MaxNewAccountsPerIPPerDay)))
			httpx.WriteError(w, r, errSignupLimited)
			return
		default:
			s.internalError(w, r, "resolve_user", err)
			return
		}

		if c.User != nil {
			if li := httpx.LogInfoFrom(ctx); li != nil {
				anon := c.User.IsAnonymous
				li.UserHash, li.Anon = s.Hasher.User(c.User.ID), &anon
			}
			if created {
				s.logInfo(r, logx.EventAccountCreated, "account created",
					slog.String(logx.KeyUser, s.Hasher.User(u.ID)), slog.String("provider", id.SignInProvider))
			}
		}
		if rt.access == accessPermanent && (c.User == nil || c.User.IsAnonymous) {
			httpx.WriteError(w, r, errPermanentRequired)
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(ctx, callerKey{}, c)))
	})
}

func utcDay(t time.Time) time.Time {
	y, m, d := t.UTC().Date()
	return time.Date(y, m, d, 0, 0, 0, 0, time.UTC)
}

// --- rate limiting -----------------------------------------------------------------

func (s *Server) rateLimit(policies []ratelimit.Policy, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		key, scope := s.Hasher.IP(httpx.ClientIPFrom(r.Context()), s.now()), "ip"
		if c := callerFrom(r.Context()); c != nil && c.User != nil {
			key, scope = c.User.ID, "user"
		} else if c != nil {
			key, scope = c.Identity.Provider+":"+c.Identity.Subject, "user"
		}
		for _, p := range policies {
			ok, retry := s.Limiter.Allow(p, key)
			if ok {
				continue
			}
			secs := int(retry.Seconds() + 0.999)
			if secs < 1 {
				secs = 1
			}
			w.Header().Set("Retry-After", strconv.Itoa(secs))
			w.Header().Set("RateLimit-Policy", p.Header())
			s.logWarn(r, logx.EventRateLimited, "rate limited", slog.String("limit", p.Name), slog.String("scope", scope))
			httpx.WriteError(w, r, httpx.NewError(http.StatusTooManyRequests, httpx.CodeRateLimited, "too many requests").
				WithDetails(map[string]any{"retryAfterSeconds": secs}))
			return
		}
		next.ServeHTTP(w, r)
	})
}

// --- idempotency ---------------------------------------------------------------------

var uuidPattern = regexp.MustCompile(`^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$`)

// idempotency makes mutations safe to retry: the first response for an
// Idempotency-Key is stored and replayed for identical retries (spec §1.2).
func (s *Server) idempotency(pattern string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		key := r.Header.Get("Idempotency-Key")
		if !uuidPattern.MatchString(key) {
			httpx.WriteError(w, r, httpx.NewError(http.StatusBadRequest, httpx.CodeInvalidRequest, "Idempotency-Key header (UUID) is required"))
			return
		}
		c := callerFrom(r.Context())
		if c == nil || c.User == nil {
			next.ServeHTTP(w, r)
			return
		}
		body, err := io.ReadAll(r.Body)
		if err != nil {
			var maxErr *http.MaxBytesError
			if errors.As(err, &maxErr) {
				httpx.WriteError(w, r, httpx.NewError(http.StatusRequestEntityTooLarge, httpx.CodePayloadTooLarge, "body too large"))
				return
			}
			httpx.WriteError(w, r, httpx.NewError(http.StatusBadRequest, httpx.CodeInvalidRequest, "unreadable body"))
			return
		}
		r.Body = io.NopCloser(bytes.NewReader(body))
		sum := sha256.Sum256(append([]byte(pattern+"\n"), body...))

		stored, err := s.Store.BeginIdempotent(r.Context(), c.User.ID, strings.ToLower(key), pattern, sum[:])
		switch {
		case errors.Is(err, store.ErrIdempotencyMismatch):
			s.logWarn(r, logx.EventIdempotencyConflict, "idempotency key reused", slog.String("route", pattern))
			httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodeIdempotencyKeyReuse, "Idempotency-Key was used for a different request"))
			return
		case errors.Is(err, store.ErrIdempotencyInProgress):
			httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodeRequestInProgress, "the original request is still being processed"))
			return
		case err != nil:
			s.internalError(w, r, "idempotency_begin", err)
			return
		case stored != nil:
			w.Header().Set("Idempotent-Replayed", "true")
			if len(stored.Body) > 0 {
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
			}
			w.WriteHeader(stored.Status)
			_, _ = w.Write(stored.Body) //nolint:gosec // G705: our own earlier JSON response, served with nosniff
			return
		}

		rec := &bufferedWriter{header: http.Header{}}
		// Background context: the client may have gone away, the record must still settle.
		bg, cancel := context.WithTimeout(context.WithoutCancel(r.Context()), 5*time.Second)
		defer cancel()
		release := func() {
			if err := s.Store.AbortIdempotent(bg, c.User.ID, strings.ToLower(key)); err != nil {
				// Not fatal: an unreleased claim becomes retryable after IdempotencyStaleAfter.
				s.Logger.LogAttrs(r.Context(), slog.LevelError, "idempotency release failed",
					slog.String(logx.KeyEvent, logx.EventDependencyError), slog.String("error", err.Error()))
			}
		}
		func() {
			// A panic must not leave the key "in progress": release it, then
			// let Recover (outer middleware) answer 500.
			defer func() {
				if v := recover(); v != nil {
					release()
					panic(v)
				}
			}()
			next.ServeHTTP(rec, r)
		}()
		status := rec.statusCode()
		if status >= 500 {
			release()
		} else if err := s.Store.CompleteIdempotent(bg, c.User.ID, strings.ToLower(key), status, rec.body.Bytes()); err != nil {
			s.Logger.LogAttrs(r.Context(), slog.LevelError, "idempotency store failed",
				slog.String(logx.KeyEvent, logx.EventDependencyError), slog.String("error", err.Error()))
		}
		for k, v := range rec.header {
			w.Header()[k] = v
		}
		w.WriteHeader(status)
		_, _ = w.Write(rec.body.Bytes())
	})
}

type bufferedWriter struct {
	header http.Header
	status int
	body   bytes.Buffer
}

func (b *bufferedWriter) Header() http.Header { return b.header }
func (b *bufferedWriter) WriteHeader(code int) {
	if b.status == 0 {
		b.status = code
	}
}
func (b *bufferedWriter) Write(p []byte) (int, error) {
	if b.status == 0 {
		b.status = http.StatusOK
	}
	return b.body.Write(p)
}
func (b *bufferedWriter) statusCode() int {
	if b.status == 0 {
		return http.StatusOK
	}
	return b.status
}

// --- CORS (waitlist only) ----------------------------------------------------------------

func (s *Server) cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin != "" && s.Config.CORSLandingOrigin != "" && origin == s.Config.CORSLandingOrigin {
			h := w.Header()
			h.Set("Access-Control-Allow-Origin", origin)
			h.Set("Vary", "Origin")
			h.Set("Access-Control-Allow-Methods", "POST, OPTIONS")
			h.Set("Access-Control-Allow-Headers", "Content-Type")
			h.Set("Access-Control-Max-Age", "600")
		}
		next.ServeHTTP(w, r)
	})
}
