// Package logx builds the structured JSON logger and the pseudonymous hashes
// written to logs (docs/backend-api-spec.md §6).
//
// Logs go to stdout only; Promtail ships them to Loki. Raw user ids, raw IPs,
// tokens, request bodies and personal content are never logged.
package logx

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"log/slog"
	"net/netip"
	"time"
)

// Event names (low-cardinality Loki label "event").
const (
	EventHTTPRequest     = "http_request"
	EventPanic           = "panic"
	EventDependencyError = "dependency_error"
	EventStartup         = "startup"
	EventShutdown        = "shutdown"
	EventMigration       = "migration"
	EventCommandError    = "command_error"

	EventAuthFailed          = "auth_failed"
	EventAppCheckFailed      = "appcheck_failed"
	EventRateLimited         = "rate_limited"
	EventSignupLimited       = "signup_limited"
	EventAccountCreated      = "account_created"
	EventAccountLinked       = "account_linked"
	EventAccountDeleted      = "account_deleted"
	EventIdempotencyConflict = "idempotency_conflict"
	EventPinVerifyFailed     = "pin_verify_failed"
	EventPinLocked           = "pin_locked"
	EventWaitlistSignup      = "waitlist_signup"
	EventContentSeeded       = "content_seeded"
)

// Attribute keys shared across packages so field names never drift.
const (
	KeyEvent     = "event"
	KeyRequestID = "requestId"
	KeyUser      = "user"
	KeyAnon      = "anon"
	KeyIP        = "ip"
)

// New returns a JSON logger writing to w. Timestamps are UTC with millisecond
// precision so they sort and parse consistently in Loki.
func New(w io.Writer, level slog.Level) *slog.Logger {
	h := slog.NewJSONHandler(w, &slog.HandlerOptions{
		Level: level,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if len(groups) == 0 && a.Key == slog.TimeKey && a.Value.Kind() == slog.KindTime {
				return slog.String(slog.TimeKey, a.Value.Time().UTC().Format("2006-01-02T15:04:05.000Z07:00"))
			}
			return a
		},
	})
	return slog.New(h)
}

// Hasher produces stable pseudonyms for logs.
type Hasher struct {
	userKey []byte
	ipKey   []byte
}

// NewHasher keys user hashes with logPepper and IP hashes with ipKey.
func NewHasher(logPepper, ipKey []byte) Hasher {
	return Hasher{userKey: logPepper, ipKey: ipKey}
}

// User returns "u_" + 16 hex chars of HMAC-SHA256(logPepper, userID): the same
// user always maps to the same value, without the id itself being logged.
func (h Hasher) User(userID string) string {
	return "u_" + hmacHex(h.userKey, userID)[:16]
}

// IP returns "ip_" + 16 hex chars keyed by a per-UTC-day key derived from
// ipKey. Requests from one address correlate within a day but not across
// days. The same value backs per-IP daily counters (signup limit).
func (h Hasher) IP(addr netip.Addr, now time.Time) string {
	if !addr.IsValid() {
		return ""
	}
	dayKey := hmacRaw(h.ipKey, now.UTC().Format("2006-01-02"))
	return "ip_" + hmacHex(dayKey, addr.Unmap().String())[:16]
}

// Value returns prefix + 16 hex chars of HMAC-SHA256(logPepper, value), for
// logging other identifiers (e.g. a waitlist email) without the raw value.
func (h Hasher) Value(prefix, value string) string {
	return prefix + hmacHex(h.userKey, prefix+value)[:16]
}

func hmacRaw(key []byte, msg string) []byte {
	m := hmac.New(sha256.New, key)
	m.Write([]byte(msg))
	return m.Sum(nil)
}

func hmacHex(key []byte, msg string) string {
	return hex.EncodeToString(hmacRaw(key, msg))
}
