package watchdog_test

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/watchdog"
)

var now = time.Date(2026, 10, 20, 8, 0, 0, 0, time.UTC)

// fakeLoki answers instant queries by matching a substring of the query.
func fakeLoki(t *testing.T, answers map[string]string) *httptest.Server {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query().Get("query")
		if r.URL.Path != "/loki/api/v1/query" {
			t.Errorf("path %s", r.URL.Path)
		}
		// Longest match wins ("status >= 500" before the bare request count).
		best, val := "", ""
		for k, v := range answers {
			if strings.Contains(q, k) && len(k) > len(best) {
				best, val = k, v
			}
		}
		if best == "" {
			_, _ = w.Write([]byte(`{"status":"success","data":{"resultType":"vector","result":[]}}`))
			return
		}
		_, _ = fmt.Fprintf(w, `{"status":"success","data":{"resultType":"vector","result":[{"metric":{},"value":[1760947200,%q]}]}}`, val)
	}))
	t.Cleanup(srv.Close)
	return srv
}

func healthy(t *testing.T) *httptest.Server {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(`ok`)) }))
	t.Cleanup(srv.Close)
	return srv
}

func backupDir(t *testing.T, age time.Duration, size int) string {
	dir := t.TempDir()
	f := filepath.Join(dir, "riung_2026-10-20.dump")
	if err := os.WriteFile(f, make([]byte, size), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Chtimes(f, now.Add(-age), now.Add(-age)); err != nil {
		t.Fatal(err)
	}
	return dir
}

func byName(rs []watchdog.Result) map[string]watchdog.Result {
	m := map[string]watchdog.Result{}
	for _, r := range rs {
		m[r.Name] = r
	}
	return m
}

func TestRunAllHealthy(t *testing.T) {
	loki := fakeLoki(t, map[string]string{
		`event="http_request" [10m]`: "1000", `status >= 500`: "3", `quantile_over_time`: "42",
		`job="cleanup"`: "1", `job="cleanup_anon"`: "1", `job="reconcile"`: "1", `job="billing_sync"`: "2",
	})
	api := healthy(t)
	rs := watchdog.Run(context.Background(), watchdog.Config{APIURL: api.URL, PublicURL: api.URL + "/healthz",
		LokiURL: loki.URL, Container: "riung-api", BackupDir: backupDir(t, 5*time.Hour, 70000), Now: func() time.Time { return now }})
	for _, r := range rs {
		if !r.OK {
			t.Errorf("%s failed: %s", r.Name, r.Detail)
		}
	}
	if len(rs) != 10 {
		t.Fatalf("want 10 checks, got %d: %+v", len(rs), rs)
	}
}

func TestRunDetectsProblems(t *testing.T) {
	loki := fakeLoki(t, map[string]string{
		`event="http_request" [10m]`: "400", `status >= 500`: "20", `quantile_over_time`: "900",
		`job="cleanup"`: "1", `job="reconcile"`: "1", // cleanup_anon and billing_sync missing
	})
	down := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(503) }))
	t.Cleanup(down.Close)
	rs := byName(watchdog.Run(context.Background(), watchdog.Config{APIURL: down.URL, PublicURL: "http://127.0.0.1:1/healthz",
		LokiURL: loki.URL, Container: "riung-api", BackupDir: backupDir(t, 30*time.Hour, 70000), Now: func() time.Time { return now }}))
	for _, name := range []string{"api_ready", "public_health", "error_rate", "latency_p95", "job_cleanup_anon", "job_billing_sync", "backup"} {
		if rs[name].OK {
			t.Errorf("%s must fail: %+v", name, rs[name])
		}
	}
	for _, name := range []string{"loki", "job_cleanup", "job_reconcile"} {
		if !rs[name].OK {
			t.Errorf("%s must pass: %+v", name, rs[name])
		}
	}
	if !strings.Contains(rs["error_rate"].Detail, "20 dari 400") || !strings.Contains(rs["latency_p95"].Detail, "p95 900 ms") {
		t.Fatalf("details: %+v %+v", rs["error_rate"], rs["latency_p95"])
	}
}

func TestRunQuietTrafficAndBrokenLoki(t *testing.T) {
	// Few requests: a handful of 5xx or a slow p95 is not an alarm.
	loki := fakeLoki(t, map[string]string{`event="http_request" [10m]`: "10", `status >= 500`: "4", `quantile_over_time`: "2000"})
	rs := byName(watchdog.Run(context.Background(), watchdog.Config{LokiURL: loki.URL, Container: "riung-api", Now: func() time.Time { return now }}))
	if !rs["error_rate"].OK || !rs["latency_p95"].OK {
		t.Fatalf("low traffic: %+v %+v", rs["error_rate"], rs["latency_p95"])
	}
	broken := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(500) }))
	t.Cleanup(broken.Close)
	rs = byName(watchdog.Run(context.Background(), watchdog.Config{LokiURL: broken.URL, Container: "riung-api"}))
	if len(rs) != 1 || rs["loki"].OK {
		t.Fatalf("broken loki must be one failed check: %+v", rs)
	}
	if r := byName(watchdog.Run(context.Background(), watchdog.Config{BackupDir: t.TempDir()}))["backup"]; r.OK {
		t.Fatal("empty backup dir must fail")
	}
	if r := byName(watchdog.Run(context.Background(), watchdog.Config{BackupDir: backupDir(t, time.Hour, 10), Now: func() time.Time { return now }}))["backup"]; r.OK {
		t.Fatal("a 10-byte dump is not a backup")
	}
}

func TestEvaluateAlertsOnceRemindsAndRecovers(t *testing.T) {
	fail := []watchdog.Result{{Name: "api_ready", Detail: "status 503"}, {Name: "backup", Detail: "umur 30h"}}
	s, msgs := watchdog.Evaluate(nil, fail, now)
	if len(msgs) != 1 || msgs[0].Check != "backup" || !strings.HasPrefix(msgs[0].Text, "🚨 backup gagal") {
		t.Fatalf("first run: backup alarms at once, api waits for a second failure: %+v", msgs)
	}
	s, msgs = watchdog.Evaluate(s, fail, now.Add(2*time.Minute))
	if len(msgs) != 1 || msgs[0].Check != "api_ready" {
		t.Fatalf("second run: api alarm, backup already sent: %+v", msgs)
	}
	s, msgs = watchdog.Evaluate(s, fail, now.Add(time.Hour))
	if len(msgs) != 0 {
		t.Fatalf("no repeats within %s: %+v", watchdog.Remind, msgs)
	}
	s, msgs = watchdog.Evaluate(s, fail, now.Add(7*time.Hour))
	if len(msgs) != 2 || !strings.HasPrefix(msgs[0].Text, "⏰ masih") {
		t.Fatalf("reminders: %+v", msgs)
	}
	ok := []watchdog.Result{{Name: "api_ready", OK: true, Detail: "200"}, {Name: "backup", OK: true, Detail: "baru"}}
	s, msgs = watchdog.Evaluate(s, ok, now.Add(8*time.Hour))
	if len(msgs) != 2 || !msgs[0].Recovery || !strings.Contains(msgs[0].Text, "pulih (gagal sejak 2026-10-20 08:00 UTC)") {
		t.Fatalf("recovery: %+v", msgs)
	}
	if len(s) != 0 {
		t.Fatalf("healthy checks leave no state: %+v", s)
	}
	// A single blip of the API is forgotten without any message.
	s, _ = watchdog.Evaluate(s, fail[:1], now)
	if _, msgs = watchdog.Evaluate(s, ok[:1], now.Add(2*time.Minute)); len(msgs) != 0 {
		t.Fatalf("blip: %+v", msgs)
	}
}

func TestStateRoundTrip(t *testing.T) {
	path := filepath.Join(t.TempDir(), "watchdog.json")
	if s, err := watchdog.LoadState(path); err != nil || len(s) != 0 {
		t.Fatalf("missing file: %v %v", s, err)
	}
	in := watchdog.State{"backup": {Fails: 2, Since: now, Alerted: true, LastAlert: now}}
	if err := watchdog.SaveState(path, in); err != nil {
		t.Fatal(err)
	}
	out, err := watchdog.LoadState(path)
	if err != nil || out["backup"].Fails != 2 || !out["backup"].Since.Equal(now) {
		t.Fatalf("round trip: %+v %v", out, err)
	}
	_ = os.WriteFile(path, []byte("{broken"), 0o600)
	if s, err := watchdog.LoadState(path); err != nil || len(s) != 0 {
		t.Fatalf("corrupt file must reset: %v %v", s, err)
	}
}
