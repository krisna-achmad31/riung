package httpx

import (
	"context"
	"net/netip"
)

type ctxKey int

const (
	requestIDKey ctxKey = iota
	clientKey
	logInfoKey
)

// client describes the network peer of a request after proxy resolution.
type client struct {
	IP netip.Addr
	// ViaTrustedProxy is true when the direct peer is a trusted proxy
	// (shared-nginx), whose X-Real-IP / X-Request-Id headers are honoured.
	ViaTrustedProxy bool
}

// RequestIDFrom returns the request id set by the RequestID middleware.
func RequestIDFrom(ctx context.Context) string {
	id, _ := ctx.Value(requestIDKey).(string)
	return id
}

// ClientIPFrom returns the resolved client IP (see RealIP).
func ClientIPFrom(ctx context.Context) netip.Addr {
	c, _ := ctx.Value(clientKey).(client)
	return c.IP
}

func clientFrom(ctx context.Context) client {
	c, _ := ctx.Value(clientKey).(client)
	return c
}

// LogInfo collects per-request facts that inner layers learn (matched route,
// authenticated user) so the access log written by the outer layer can
// include them.
type LogInfo struct {
	Route    string
	UserHash string
	Anon     *bool
	// AppCheck is the App Check outcome: valid, missing, invalid, replayed
	// or unavailable (empty when the route does not check it or mode is off).
	AppCheck string
}

// LogInfoFrom returns the mutable per-request log info, or nil outside the
// AccessLog middleware.
func LogInfoFrom(ctx context.Context) *LogInfo {
	li, _ := ctx.Value(logInfoKey).(*LogInfo)
	return li
}
