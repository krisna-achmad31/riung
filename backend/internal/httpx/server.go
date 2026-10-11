package httpx

import (
	"net/http"
	"time"
)

// NewServer returns an http.Server with the timeouts from
// docs/backend-api-spec.md §4.8, so slow or stalled clients cannot hold
// connections open.
func NewServer(addr string, h http.Handler) *http.Server {
	return &http.Server{
		Addr:              addr,
		Handler:           h,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    16 << 10,
	}
}
