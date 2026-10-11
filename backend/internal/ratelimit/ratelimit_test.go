package ratelimit

import (
	"sync"
	"testing"
	"time"
)

type clock struct {
	mu sync.Mutex
	t  time.Time
}

func (c *clock) now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.t
}

func (c *clock) advance(d time.Duration) {
	c.mu.Lock()
	c.t = c.t.Add(d)
	c.mu.Unlock()
}

func TestAllowBurstThenRefill(t *testing.T) {
	c := &clock{t: time.Unix(1_700_000_000, 0)}
	l := New(c.now)
	p := Policy{Name: "pin", Limit: 5, Window: 15 * time.Minute}

	for i := 0; i < 5; i++ {
		if ok, _ := l.Allow(p, "user-1"); !ok {
			t.Fatalf("request %d should pass", i+1)
		}
	}
	ok, retry := l.Allow(p, "user-1")
	if ok || retry <= 0 || retry > 3*time.Minute {
		t.Fatalf("6th request must wait ~3m, got ok=%v retry=%v", ok, retry)
	}
	// Other users and other policies are independent.
	if ok, _ := l.Allow(p, "user-2"); !ok {
		t.Fatal("other key must not be limited")
	}
	if ok, _ := l.Allow(Policy{Name: "other", Limit: 1, Window: time.Minute}, "user-1"); !ok {
		t.Fatal("other policy must not be limited")
	}

	c.advance(3 * time.Minute)
	if ok, _ := l.Allow(p, "user-1"); !ok {
		t.Fatal("one token should have refilled after window/limit")
	}
	if ok, _ := l.Allow(p, "user-1"); ok {
		t.Fatal("only one token should have refilled")
	}
}

func TestRejectedRequestsDoNotConsume(t *testing.T) {
	c := &clock{t: time.Unix(1_700_000_000, 0)}
	l := New(c.now)
	p := Policy{Name: "x", Limit: 1, Window: time.Minute}
	l.Allow(p, "k")
	for i := 0; i < 10; i++ {
		l.Allow(p, "k") // hammering while limited must not push the wait further
	}
	c.advance(time.Minute)
	if ok, _ := l.Allow(p, "k"); !ok {
		t.Fatal("token should be back after one window")
	}
}

func TestSweep(t *testing.T) {
	c := &clock{t: time.Unix(1_700_000_000, 0)}
	l := New(c.now)
	p := Policy{Name: "x", Limit: 1, Window: time.Minute}
	l.Allow(p, "a")
	c.advance(2 * time.Hour)
	l.Allow(p, "b")
	l.Sweep(time.Hour)
	if l.Len() != 1 {
		t.Fatalf("idle bucket should be swept, have %d", l.Len())
	}
}

func TestHeader(t *testing.T) {
	if got := (Policy{Limit: 10, Window: time.Minute}).Header(); got != "10;w=60" {
		t.Fatalf("got %q", got)
	}
}
