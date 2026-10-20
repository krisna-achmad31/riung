// Package watchdog checks what the API cannot report about itself: whether it
// answers at all, error rate and latency from Loki, cron jobs that stopped
// running, and the age of the last database backup. It runs as a separate
// short-lived container from host cron, so it still works when riung-api is
// down; findings go to Telegram through the alert package.
package watchdog

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Config says what to check; an empty URL or directory skips its checks.
type Config struct {
	APIURL    string // e.g. http://riung-api:8080 (/readyz)
	PublicURL string // e.g. https://riung.e55techlab.com/healthz (through nginx)
	LokiURL   string // e.g. http://shared-loki:3100
	Container string // Loki container label, e.g. riung-api
	BackupDir string // directory with pg_dump *.dump files
	// BackupNewest describes the newest dump as "<name> <unix mtime> <bytes>"
	// ("none" = no file). The host script fills it so the container never
	// needs access to the dumps; it takes precedence over BackupDir.
	BackupNewest string
	HTTP         *http.Client
	Now          func() time.Time
}

// Thresholds (docs/backend-api-spec.md §6.6).
const (
	window          = "10m"
	maxErrorRatio   = 0.01
	minErrors       = 5
	maxP95Ms        = 500
	minRequestsP95  = 50
	maxBackupAge    = 26 * time.Hour
	minBackupBytes  = 1024
	dailyJobMaxAge  = "26h"
	hourlyJobMaxAge = "2h"
)

// Jobs whose last successful run must be recent (crontab in runbook step 9).
var jobs = []struct{ name, maxAge string }{
	{"cleanup", dailyJobMaxAge}, {"cleanup_anon", dailyJobMaxAge}, {"reconcile", dailyJobMaxAge},
	{"billing_sync", hourlyJobMaxAge},
}

// Result is one check.
type Result struct {
	Name   string
	OK     bool
	Detail string
}

// Run performs every configured check.
func Run(ctx context.Context, c Config) []Result {
	if c.HTTP == nil {
		c.HTTP = &http.Client{Timeout: 10 * time.Second}
	}
	if c.Now == nil {
		c.Now = time.Now
	}
	var out []Result
	if c.APIURL != "" {
		out = append(out, c.httpCheck(ctx, "api_ready", strings.TrimRight(c.APIURL, "/")+"/readyz"))
	}
	if c.PublicURL != "" {
		out = append(out, c.httpCheck(ctx, "public_health", c.PublicURL))
	}
	if c.LokiURL != "" {
		out = append(out, c.lokiChecks(ctx)...)
	}
	if c.BackupNewest != "" || c.BackupDir != "" {
		out = append(out, c.backupCheck())
	}
	return out
}

func (c Config) httpCheck(ctx context.Context, name, u string) Result {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return Result{name, false, err.Error()}
	}
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return Result{name, false, "tidak menjawab: " + shortErr(err)}
	}
	defer func() { _ = resp.Body.Close() }()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	if resp.StatusCode != http.StatusOK {
		return Result{name, false, fmt.Sprintf("status %d", resp.StatusCode)}
	}
	return Result{name, true, "200"}
}

func (c Config) lokiChecks(ctx context.Context) []Result {
	sel := fmt.Sprintf(`{container=%q} | json | event="http_request"`, c.Container)
	total, err := c.lokiScalar(ctx, fmt.Sprintf(`sum(count_over_time(%s [%s]))`, sel, window))
	if err != nil {
		return []Result{{"loki", false, "query gagal: " + shortErr(err)}}
	}
	errs, err := c.lokiScalar(ctx, fmt.Sprintf(`sum(count_over_time(%s | status >= 500 [%s]))`, sel, window))
	if err != nil {
		return []Result{{"loki", false, "query gagal: " + shortErr(err)}}
	}
	out := []Result{{"loki", true, "ok"}}

	rate := Result{Name: "error_rate", OK: true}
	ratio := 0.0
	if total > 0 {
		ratio = errs / total
	}
	rate.Detail = fmt.Sprintf("%.0f dari %.0f request 5xx (%.1f%%) dalam %s", errs, total, 100*ratio, window)
	if errs >= minErrors && ratio > maxErrorRatio {
		rate.OK = false
	}
	out = append(out, rate)

	lat := Result{Name: "latency_p95", OK: true, Detail: fmt.Sprintf("%.0f request dalam %s", total, window)}
	if total >= minRequestsP95 {
		p95, err := c.lokiScalar(ctx, fmt.Sprintf(
			`max(quantile_over_time(0.95, %s | route!="/healthz" | route!="/readyz" | unwrap durationMs [%s]) by (container))`, sel, window))
		if err != nil {
			lat = Result{"latency_p95", false, "query gagal: " + shortErr(err)}
		} else {
			lat.Detail = fmt.Sprintf("p95 %.0f ms (%.0f request dalam %s)", p95, total, window)
			lat.OK = p95 <= maxP95Ms
		}
	}
	out = append(out, lat)

	for _, j := range jobs {
		n, err := c.lokiScalar(ctx, fmt.Sprintf(
			`sum(count_over_time({container=%q} | json | event="job_run" | job=%q | ok="true" [%s]))`, c.Container, j.name, j.maxAge))
		r := Result{Name: "job_" + j.name, OK: n > 0}
		switch {
		case err != nil:
			r = Result{"job_" + j.name, false, "query gagal: " + shortErr(err)}
		case n > 0:
			r.Detail = fmt.Sprintf("%.0f kali sukses dalam %s", n, j.maxAge)
		default:
			r.Detail = "tidak ada run sukses dalam " + j.maxAge
		}
		out = append(out, r)
	}
	return out
}

// lokiScalar runs an instant query and returns the first sample (0 when Loki
// has no data — e.g. no request at all in the window).
func (c Config) lokiScalar(ctx context.Context, query string) (float64, error) {
	u := strings.TrimRight(c.LokiURL, "/") + "/loki/api/v1/query?" + url.Values{
		"query": {query}, "time": {strconv.FormatInt(c.Now().UnixNano(), 10)}}.Encode()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return 0, err
	}
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return 0, err
	}
	defer func() { _ = resp.Body.Close() }()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return 0, err
	}
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("loki status %d", resp.StatusCode)
	}
	var r struct {
		Status string `json:"status"`
		Data   struct {
			Result []struct {
				Value [2]any `json:"value"`
			} `json:"result"`
		} `json:"data"`
	}
	if err := json.Unmarshal(body, &r); err != nil {
		return 0, err
	}
	if r.Status != "success" {
		return 0, fmt.Errorf("loki status %q", r.Status)
	}
	if len(r.Data.Result) == 0 {
		return 0, nil
	}
	s, _ := r.Data.Result[0].Value[1].(string)
	return strconv.ParseFloat(s, 64)
}

func (c Config) backupCheck() Result {
	name, mtime, size, err := c.newestBackup()
	if err != nil {
		return Result{"backup", false, err.Error()}
	}
	age := c.Now().Sub(mtime)
	detail := fmt.Sprintf("%s, %d byte, umur %s", name, size, age.Round(time.Minute))
	return Result{"backup", age <= maxBackupAge && size >= minBackupBytes, detail}
}

func (c Config) newestBackup() (string, time.Time, int64, error) {
	if c.BackupNewest != "" {
		f := strings.Fields(c.BackupNewest)
		if len(f) != 3 {
			return "", time.Time{}, 0, errors.New("tidak ada file backup")
		}
		sec, err1 := strconv.ParseInt(f[1], 10, 64)
		size, err2 := strconv.ParseInt(f[2], 10, 64)
		if err1 != nil || err2 != nil {
			return "", time.Time{}, 0, fmt.Errorf("info backup tidak valid: %q", c.BackupNewest)
		}
		return f[0], time.Unix(sec, 0), size, nil
	}
	files, err := filepath.Glob(filepath.Join(c.BackupDir, "*.dump"))
	if err != nil || len(files) == 0 {
		return "", time.Time{}, 0, errors.New("tidak ada file backup di " + c.BackupDir)
	}
	var newest os.FileInfo
	for _, f := range files {
		st, err := os.Stat(f)
		if err == nil && (newest == nil || st.ModTime().After(newest.ModTime())) {
			newest = st
		}
	}
	if newest == nil {
		return "", time.Time{}, 0, errors.New("file backup tidak terbaca")
	}
	return newest.Name(), newest.ModTime(), newest.Size(), nil
}

func shortErr(err error) string {
	s := err.Error()
	if len(s) > 160 {
		s = s[:160] + "…"
	}
	return s
}

// --- state: alert on change, remind while failing --------------------------------

// Checks that must fail twice in a row before alerting (a single slow
// answer or a deploy restart is not an outage).
var needsTwo = map[string]bool{"api_ready": true, "public_health": true}

// Remind repeats an alarm while a check keeps failing.
const Remind = 6 * time.Hour

// CheckState is persisted between runs.
type CheckState struct {
	Fails     int       `json:"fails"`
	Since     time.Time `json:"since"`
	Alerted   bool      `json:"alerted"`
	LastAlert time.Time `json:"lastAlert"`
}

// State maps check name → state.
type State map[string]CheckState

// Message is one alarm or recovery to send.
type Message struct {
	Check    string
	Recovery bool
	Text     string
}

// Evaluate updates state with results and returns the messages to send:
// a failure once it is confirmed, a reminder every Remind, and a recovery.
func Evaluate(prev State, results []Result, now time.Time) (State, []Message) {
	next := State{}
	for k, v := range prev {
		next[k] = v
	}
	var msgs []Message
	for _, r := range results {
		s := next[r.Name]
		if r.OK {
			if s.Alerted {
				msgs = append(msgs, Message{r.Name, true, fmt.Sprintf("✅ %s pulih (gagal sejak %s) — %s",
					r.Name, s.Since.UTC().Format("2006-01-02 15:04 UTC"), r.Detail)})
			}
			delete(next, r.Name)
			continue
		}
		if s.Fails == 0 {
			s.Since = now
		}
		s.Fails++
		need := 1
		if needsTwo[r.Name] {
			need = 2
		}
		if s.Fails >= need && (!s.Alerted || now.Sub(s.LastAlert) >= Remind) {
			prefix := "🚨"
			if s.Alerted {
				prefix = "⏰ masih"
			}
			msgs = append(msgs, Message{r.Name, false, fmt.Sprintf("%s %s gagal — %s", prefix, r.Name, r.Detail)})
			s.Alerted, s.LastAlert = true, now
		}
		next[r.Name] = s
	}
	return next, msgs
}

// LoadState reads the state file (missing = empty).
func LoadState(path string) (State, error) {
	b, err := os.ReadFile(path) //nolint:gosec // G304: operator-set path
	if os.IsNotExist(err) {
		return State{}, nil
	}
	if err != nil {
		return nil, err
	}
	s := State{}
	if err := json.Unmarshal(b, &s); err != nil {
		return State{}, nil // corrupt file: start over rather than stop alerting
	}
	return s, nil
}

// SaveState writes the state file atomically.
func SaveState(path string, s State) error {
	b, err := json.Marshal(s)
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}
