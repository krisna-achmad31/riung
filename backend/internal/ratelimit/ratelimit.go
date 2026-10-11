// Package ratelimit implements the per-user / per-IP token buckets of
// docs/backend-api-spec.md §5.2. State is in memory (one riung-api instance);
// moving to several instances means swapping this for a shared-redis store.
package ratelimit

import (
	"context"
	"strconv"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// Policy allows Limit events per Window, with a burst of Limit.
type Policy struct {
	Name   string
	Limit  int
	Window time.Duration
}

// Header renders the policy for the RateLimit-Policy response header,
// e.g. `10;w=60`.
func (p Policy) Header() string {
	return strconv.Itoa(p.Limit) + ";w=" + strconv.Itoa(int(p.Window/time.Second))
}

type bucket struct {
	lim  *rate.Limiter
	seen time.Time
}

// Limiter holds buckets keyed by policy name and caller key.
type Limiter struct {
	mu      sync.Mutex
	buckets map[string]*bucket
	now     func() time.Time
	maxKeys int
}

// New returns an empty limiter. now may be nil (time.Now).
func New(now func() time.Time) *Limiter {
	if now == nil {
		now = time.Now
	}
	return &Limiter{buckets: map[string]*bucket{}, now: now, maxKeys: 200_000}
}

// Allow consumes one token for key under p. When the bucket is empty it
// returns false and how long until a token is available.
func (l *Limiter) Allow(p Policy, key string) (bool, time.Duration) {
	now := l.now()
	k := p.Name + "\x00" + key

	l.mu.Lock()
	b, ok := l.buckets[k]
	if !ok {
		if len(l.buckets) >= l.maxKeys {
			l.sweepLocked(now, 0)
		}
		every := p.Window / time.Duration(p.Limit)
		b = &bucket{lim: rate.NewLimiter(rate.Every(every), p.Limit)}
		l.buckets[k] = b
	}
	b.seen = now
	l.mu.Unlock()

	r := b.lim.ReserveN(now, 1)
	if !r.OK() {
		return false, p.Window
	}
	if d := r.DelayFrom(now); d > 0 {
		r.CancelAt(now)
		return false, d
	}
	return true, 0
}

// Sweep drops buckets idle for longer than idle (they would be full again).
func (l *Limiter) Sweep(idle time.Duration) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.sweepLocked(l.now(), idle)
}

func (l *Limiter) sweepLocked(now time.Time, idle time.Duration) {
	for k, b := range l.buckets {
		if now.Sub(b.seen) >= idle {
			delete(l.buckets, k)
		}
	}
}

// Len reports the number of tracked buckets (tests, metrics).
func (l *Limiter) Len() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.buckets)
}

// Run sweeps idle buckets every interval until ctx is done. idle must exceed
// the longest policy window so a sweep never resets an active limit.
func (l *Limiter) Run(ctx context.Context, interval, idle time.Duration) {
	t := time.NewTicker(interval)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			l.Sweep(idle)
		}
	}
}
