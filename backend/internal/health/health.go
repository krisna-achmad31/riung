// Package health serves liveness and readiness probes.
//
// /healthz is public (nginx exposes it) and only says the process is up.
// /readyz checks the database and is blocked by nginx from outside.
package health

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

// Pinger is satisfied by *pgxpool.Pool.
type Pinger interface {
	Ping(ctx context.Context) error
}

// Live reports that the process is serving requests.
func Live() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
}

// Ready reports whether the database answers within 2 seconds.
func Ready(db Pinger, logger *slog.Logger) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := db.Ping(ctx); err != nil {
			logger.LogAttrs(r.Context(), slog.LevelError, "readiness check failed",
				slog.String(logx.KeyEvent, logx.EventDependencyError),
				slog.String(logx.KeyRequestID, httpx.RequestIDFrom(r.Context())),
				slog.String("dependency", "postgres"),
				slog.String("op", "ping"),
				slog.String("error", err.Error()),
			)
			httpx.WriteError(w, r, httpx.ErrUnavailable)
			return
		}
		httpx.WriteJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})
}
