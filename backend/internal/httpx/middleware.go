package httpx

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"regexp"
	"runtime/debug"
	"strings"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// Middleware wraps a handler.
type Middleware func(http.Handler) http.Handler

// Chain applies middlewares so that the first one is the outermost.
func Chain(h http.Handler, mws ...Middleware) http.Handler {
	for i := len(mws) - 1; i >= 0; i-- {
		h = mws[i](h)
	}
	return h
}

// RealIP resolves the client IP. X-Real-IP is honoured only when the direct
// peer is in trusted (shared-nginx sets it from $remote_addr). X-Forwarded-For
// is deliberately ignored: the nginx template appends client-supplied values
// to it, so it could be spoofed to dodge per-IP limits.
func RealIP(trusted []netip.Prefix) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			c := client{IP: peerAddr(r.RemoteAddr)}
			if c.IP.IsValid() && inPrefixes(c.IP, trusted) {
				c.ViaTrustedProxy = true
				if v, err := netip.ParseAddr(strings.TrimSpace(r.Header.Get("X-Real-IP"))); err == nil {
					c.IP = v.Unmap()
				}
			}
			next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), clientKey, c)))
		})
	}
}

func peerAddr(remote string) netip.Addr {
	host, _, err := net.SplitHostPort(remote)
	if err != nil {
		host = remote
	}
	a, err := netip.ParseAddr(host)
	if err != nil {
		return netip.Addr{}
	}
	return a.Unmap()
}

func inPrefixes(a netip.Addr, ps []netip.Prefix) bool {
	for _, p := range ps {
		if p.Contains(a) {
			return true
		}
	}
	return false
}

var requestIDPattern = regexp.MustCompile(`^[A-Za-z0-9-]{8,64}$`)

// RequestID assigns every request an id, echoed in X-Request-Id and in error
// bodies. An incoming id (nginx $request_id) is kept only from a trusted proxy.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := ""
		if clientFrom(r.Context()).ViaTrustedProxy {
			if in := r.Header.Get("X-Request-Id"); requestIDPattern.MatchString(in) {
				id = in
			}
		}
		if id == "" {
			id = NewRequestID(time.Now())
		}
		w.Header().Set("X-Request-Id", id)
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), requestIDKey, id)))
	})
}

const crockford = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

// NewRequestID returns a 26-character ULID-style id: 48-bit millisecond time
// followed by 80 random bits, Crockford base32. Sortable and URL-safe.
func NewRequestID(now time.Time) string {
	var b [16]byte
	ms := uint64(now.UnixMilli())
	for i := 5; i >= 0; i-- {
		b[i] = byte(ms)
		ms >>= 8
	}
	_, _ = rand.Read(b[6:])
	// 128 bits plus two leading zero bits = 130 bits = 26 base32 chars. Only
	// the low bits of acc are ever read, so its overflow is harmless.
	var out [26]byte
	var acc uint64
	bits, pos := 2, 0
	for _, x := range b {
		acc = acc<<8 | uint64(x)
		bits += 8
		for bits >= 5 {
			bits -= 5
			out[pos] = crockford[(acc>>uint(bits))&31]
			pos++
		}
	}
	return string(out[:pos])
}

// statusRecorder captures status and size for the access log.
type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (s *statusRecorder) WriteHeader(code int) {
	if s.status == 0 {
		s.status = code
	}
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(p []byte) (int, error) {
	if s.status == 0 {
		s.status = http.StatusOK
	}
	n, err := s.ResponseWriter.Write(p)
	s.bytes += n
	return n, err
}

func (s *statusRecorder) Unwrap() http.ResponseWriter { return s.ResponseWriter }

var headerValuePattern = regexp.MustCompile(`^[A-Za-z0-9._+-]{1,32}$`)

func safeHeader(r *http.Request, name string) string {
	if v := r.Header.Get(name); headerValuePattern.MatchString(v) {
		return v
	}
	return ""
}

// AccessLog writes one "http_request" record per request: route pattern (not
// the raw path), status, latency, size and pseudonymous user/IP. 4xx log at
// WARN, 5xx at ERROR.
func AccessLog(logger *slog.Logger, hasher logx.Hasher) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			info := &LogInfo{}
			rec := &statusRecorder{ResponseWriter: w}
			r = r.WithContext(context.WithValue(r.Context(), logInfoKey, info))

			next.ServeHTTP(rec, r)

			status := rec.status
			if status == 0 {
				status = http.StatusOK
			}
			route := info.Route
			if route == "" {
				route = "unmatched"
			}
			attrs := []slog.Attr{
				slog.String(logx.KeyEvent, logx.EventHTTPRequest),
				slog.String(logx.KeyRequestID, RequestIDFrom(r.Context())),
				slog.String("method", r.Method),
				slog.String("route", route),
				slog.Int("status", status),
				slog.Int64("durationMs", time.Since(start).Milliseconds()),
				slog.Int("bytesOut", rec.bytes),
				slog.String(logx.KeyIP, hasher.IP(ClientIPFrom(r.Context()), start)),
			}
			if info.UserHash != "" {
				attrs = append(attrs, slog.String(logx.KeyUser, info.UserHash))
			}
			if info.Anon != nil {
				attrs = append(attrs, slog.Bool(logx.KeyAnon, *info.Anon))
			}
			if v := safeHeader(r, "X-App-Version"); v != "" {
				attrs = append(attrs, slog.String("appVersion", v))
			}
			if v := safeHeader(r, "X-Platform"); v != "" {
				attrs = append(attrs, slog.String("platform", v))
			}
			level := slog.LevelInfo
			switch {
			case status >= 500:
				level = slog.LevelError
			case status >= 400:
				level = slog.LevelWarn
			}
			logger.LogAttrs(r.Context(), level, "request", attrs...)
		})
	}
}

// Recover turns a panic into a 500 JSON response. The stack goes to the log
// only, never to the client.
func Recover(logger *slog.Logger) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				v := recover()
				if v == nil {
					return
				}
				if err, ok := v.(error); ok && errors.Is(err, http.ErrAbortHandler) {
					panic(v)
				}
				logger.LogAttrs(r.Context(), slog.LevelError, "panic recovered",
					slog.String(logx.KeyEvent, logx.EventPanic),
					slog.String(logx.KeyRequestID, RequestIDFrom(r.Context())),
					slog.String("panic", fmt.Sprint(v)),
					slog.String("stack", string(debug.Stack())),
				)
				WriteError(w, r, ErrInternal)
			}()
			next.ServeHTTP(w, r)
		})
	}
}

// SecurityHeaders sets defaults for API responses. Handlers serving cacheable
// content (config, content) override Cache-Control themselves.
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Cache-Control", "no-store")
		h.Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}

// LimitBody caps the request body; reading past the limit fails and
// DecodeJSON reports 413.
func LimitBody(n int64) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Body != nil && r.Body != http.NoBody {
				r.Body = http.MaxBytesReader(w, r.Body, n)
			}
			next.ServeHTTP(w, r)
		})
	}
}

// Router wraps the ServeMux (innermost layer). It records the matched pattern
// in LogInfo ("GET /v1/me" → "/v1/me") and replaces the mux's plain-text
// 404/405 replies with the JSON error envelope (keeping the Allow header).
func Router(mux *http.ServeMux) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h, pattern := mux.Handler(r)
		if pattern == "" {
			// No route: let the mux decide between 404 and 405, but
			// capture its reply instead of sending it.
			c := &captureWriter{header: http.Header{}}
			h.ServeHTTP(c, r)
			if allow := c.header.Get("Allow"); allow != "" {
				w.Header().Set("Allow", allow)
			}
			if c.status == http.StatusMethodNotAllowed {
				WriteError(w, r, ErrMethodNotAllowed)
			} else {
				WriteError(w, r, ErrNotFound)
			}
			return
		}
		mux.ServeHTTP(w, r)
		if info := LogInfoFrom(r.Context()); info != nil {
			if i := strings.IndexByte(pattern, ' '); i >= 0 {
				pattern = pattern[i+1:]
			}
			info.Route = pattern
		}
	})
}

// captureWriter swallows the mux's default error reply.
type captureWriter struct {
	header http.Header
	status int
}

func (c *captureWriter) Header() http.Header { return c.header }
func (c *captureWriter) WriteHeader(code int) {
	if c.status == 0 {
		c.status = code
	}
}
func (c *captureWriter) Write(p []byte) (int, error) {
	if c.status == 0 {
		c.status = http.StatusOK
	}
	return len(p), nil
}
