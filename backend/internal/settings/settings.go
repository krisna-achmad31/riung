// Package settings serves the few numbers an admin may change at runtime
// (docs/backend-api-spec.md §3.11). Defaults come from economy-props.json;
// app_settings rows override them. Only allowlisted keys exist.
package settings

import (
	"context"
	"encoding/json"
	"sort"
	"sync"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/economy"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Keys.
const (
	JournalRewardsPerDay      = "journalRewardsPerDay"
	MeditationRewardsPerDay   = "meditationRewardsPerDay"
	MaxNewAccountsPerIPPerDay = "maxNewAccountsPerIpPerDay"
)

// Def describes one setting.
type Def struct {
	Key     string
	Default int
	Min     int
	Max     int
}

// Defs returns the allowlisted settings with their defaults from e.
func Defs(caps economy.Caps) []Def {
	return []Def{
		{Key: JournalRewardsPerDay, Default: caps.JournalRewardsPerDay, Min: 0, Max: 20},
		{Key: MeditationRewardsPerDay, Default: caps.MeditationRewardsPerDay, Min: 0, Max: 20},
		{Key: MaxNewAccountsPerIPPerDay, Default: caps.NewAccountsPerIpPerDay, Min: 1, Max: 1000},
	}
}

// Source reads stored overrides (implemented by *store.Store).
type Source interface {
	Settings(ctx context.Context) (map[string]json.RawMessage, time.Time, error)
}

// Value is a setting's effective value and provenance (admin listing).
type Value struct {
	Def
	Value      int
	Overridden bool
}

// Cache serves settings from memory, refreshing at most every ttl. On a
// database error it keeps the last good values (or the defaults).
type Cache struct {
	src  Source
	defs map[string]Def
	keys []string
	ttl  time.Duration
	now  func() time.Time

	mu         sync.Mutex
	values     map[string]int
	overridden map[string]bool
	updatedAt  time.Time
	fetchedAt  time.Time
}

// NewCache builds a cache over src (nil = defaults only).
func NewCache(src Source, caps economy.Caps, ttl time.Duration, now func() time.Time) *Cache {
	c := &Cache{src: src, defs: map[string]Def{}, ttl: ttl, now: now}
	for _, d := range Defs(caps) {
		c.defs[d.Key] = d
		c.keys = append(c.keys, d.Key)
	}
	sort.Strings(c.keys)
	return c
}

// Def returns the definition of key.
func (c *Cache) Def(key string) (Def, bool) {
	d, ok := c.defs[key]
	return d, ok
}

// Invalidate forces the next read to reload (after an admin change).
func (c *Cache) Invalidate() {
	c.mu.Lock()
	c.values = nil
	c.mu.Unlock()
}

func (c *Cache) refresh(ctx context.Context) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.values != nil && c.now().Sub(c.fetchedAt) < c.ttl {
		return
	}
	values, overridden := map[string]int{}, map[string]bool{}
	for k, d := range c.defs {
		values[k] = d.Default
	}
	if c.src != nil {
		rows, updatedAt, err := c.src.Settings(ctx)
		if err != nil {
			if c.values == nil {
				c.values, c.overridden = values, overridden
			}
			return // keep last good values; retried after ttl
		}
		for k, raw := range rows {
			d, ok := c.defs[k]
			if !ok {
				continue
			}
			var n int
			if json.Unmarshal(raw, &n) == nil && n >= d.Min && n <= d.Max {
				values[k], overridden[k] = n, true
			}
		}
		c.updatedAt = updatedAt
	}
	c.values, c.overridden = values, overridden
	c.fetchedAt = c.now()
}

// Int returns the current value of key.
func (c *Cache) Int(ctx context.Context, key string) int {
	c.refresh(ctx)
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.values[key]
}

// UpdatedAt is when an admin last changed any setting (zero if never).
func (c *Cache) UpdatedAt(ctx context.Context) time.Time {
	c.refresh(ctx)
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.updatedAt
}

// All returns every setting, sorted by key.
func (c *Cache) All(ctx context.Context) []Value {
	c.refresh(ctx)
	c.mu.Lock()
	defer c.mu.Unlock()
	out := make([]Value, 0, len(c.keys))
	for _, k := range c.keys {
		out = append(out, Value{Def: c.defs[k], Value: c.values[k], Overridden: c.overridden[k]})
	}
	return out
}

var _ Source = (*store.Store)(nil)
