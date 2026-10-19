package database_test

import (
	"bytes"
	"context"
	"io"
	"log/slog"
	"net"
	"net/url"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/database"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

// closedPortURL points at a port nothing listens on: every ping fails fast.
const closedPortURL = "postgres://riung_app:x@127.0.0.1:1/riung?sslmode=disable&connect_timeout=1"

func TestOpenTriesOnceWithoutConnectWait(t *testing.T) {
	var logs bytes.Buffer
	_, err := database.Open(context.Background(), closedPortURL, database.PoolOptions{
		MaxConns: 1, StatementTimeout: time.Second, Logger: logx.New(&logs, slog.LevelInfo),
	})
	if err == nil || !strings.Contains(err.Error(), "attempt 1)") {
		t.Fatalf("want a failure after one attempt, got %v", err)
	}
	if logs.Len() != 0 {
		t.Fatalf("one try must not log retries:\n%s", logs.String())
	}
}

func TestOpenGivesUpAfterConnectWait(t *testing.T) {
	var logs bytes.Buffer
	start := time.Now()
	// Retries after 0.5 s, then the next delay (1 s) would pass 1.2 s.
	_, err := database.Open(context.Background(), closedPortURL, database.PoolOptions{
		MaxConns: 1, StatementTimeout: time.Second, ConnectWait: 1200 * time.Millisecond,
		Logger: logx.New(&logs, slog.LevelInfo),
	})
	if err == nil || !strings.Contains(err.Error(), "attempt 2)") {
		t.Fatalf("want a failure after two attempts, got %v", err)
	}
	if took := time.Since(start); took < 400*time.Millisecond || took > 1200*time.Millisecond {
		t.Fatalf("gave up after %v, want about 0.5 s", took)
	}
	if n := strings.Count(logs.String(), `"level":"WARN","msg":"database not ready, retrying"`); n != 1 {
		t.Fatalf("want 1 retry warning, got %d:\n%s", n, logs.String())
	}
	if strings.Contains(logs.String(), `"level":"ERROR"`) {
		t.Fatalf("waiting must not log errors:\n%s", logs.String())
	}
}

func TestOpenStopsWaitingWhenContextEnds(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	start := time.Now()
	_, err := database.Open(ctx, closedPortURL, database.PoolOptions{
		MaxConns: 1, StatementTimeout: time.Second, ConnectWait: time.Minute,
		Logger: logx.New(io.Discard, slog.LevelInfo),
	})
	if err == nil {
		t.Fatal("want an error once the context ends")
	}
	if took := time.Since(start); took > 2*time.Second {
		t.Fatalf("kept waiting %v after the context ended", took)
	}
}

// TestOpenWaitsForDatabase plays the VPS reboot: Postgres refuses connections
// for a while (the proxy hangs up), then comes up; Open must wait for it.
func TestOpenWaitsForDatabase(t *testing.T) {
	urls := testdb.Create(t)
	target, err := url.Parse(urls.App)
	if err != nil {
		t.Fatal(err)
	}
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = ln.Close() })
	var up atomic.Bool
	go proxy(ln, target.Host, &up)
	time.AfterFunc(1500*time.Millisecond, func() { up.Store(true) })

	viaProxy := *target
	viaProxy.Host = ln.Addr().String()
	var logs bytes.Buffer
	start := time.Now()
	pool, err := database.Open(context.Background(), viaProxy.String(), database.PoolOptions{
		MaxConns: 1, StatementTimeout: 5 * time.Second, AppName: "riung-test", ConnectWait: 30 * time.Second,
		Logger: logx.New(&logs, slog.LevelInfo),
	})
	if err != nil {
		t.Fatalf("open must wait for the database: %v\n%s", err, logs.String())
	}
	defer pool.Close()
	if took := time.Since(start); took < 1500*time.Millisecond {
		t.Fatalf("connected after %v, before the database was up", took)
	}
	if !strings.Contains(logs.String(), `"msg":"database not ready, retrying"`) ||
		!strings.Contains(logs.String(), `"msg":"database ready"`) {
		t.Fatalf("want retry warnings and a ready line:\n%s", logs.String())
	}
	var one int
	if err := pool.QueryRow(context.Background(), "SELECT 1").Scan(&one); err != nil || one != 1 {
		t.Fatalf("query after waiting: %v", err)
	}
}

// proxy hangs up on every connection until up is set, then forwards to target.
func proxy(ln net.Listener, target string, up *atomic.Bool) {
	for {
		c, err := ln.Accept()
		if err != nil {
			return
		}
		if !up.Load() {
			_ = c.Close()
			continue
		}
		go func() {
			defer func() { _ = c.Close() }()
			s, err := net.Dial("tcp", target)
			if err != nil {
				return
			}
			defer func() { _ = s.Close() }()
			done := make(chan struct{}, 2)
			go func() { _, _ = io.Copy(s, c); done <- struct{}{} }()
			go func() { _, _ = io.Copy(c, s); done <- struct{}{} }()
			<-done
		}()
	}
}
