package httpx

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

var nginx = []netip.Prefix{netip.MustParsePrefix("172.19.0.2/32")}

func serve(h http.Handler, req *http.Request) *httptest.ResponseRecorder {
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestRealIPTrustsOnlyProxyAndIgnoresXFF(t *testing.T) {
	var got netip.Addr
	h := RealIP(nginx)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		got = ClientIPFrom(r.Context())
	}))

	// From nginx: X-Real-IP wins, X-Forwarded-For is ignored.
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "172.19.0.2:41000"
	req.Header.Set("X-Real-IP", "203.0.113.9")
	req.Header.Set("X-Forwarded-For", "1.2.3.4")
	serve(h, req)
	if got != netip.MustParseAddr("203.0.113.9") {
		t.Fatalf("via nginx: got %v", got)
	}

	// From anyone else: headers are ignored.
	req = httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "172.19.0.8:5555"
	req.Header.Set("X-Real-IP", "203.0.113.9")
	req.Header.Set("X-Forwarded-For", "203.0.113.9")
	serve(h, req)
	if got != netip.MustParseAddr("172.19.0.8") {
		t.Fatalf("untrusted peer must not set its IP: got %v", got)
	}

	// Garbage X-Real-IP from nginx falls back to the peer.
	req = httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "172.19.0.2:41000"
	req.Header.Set("X-Real-IP", "not-an-ip")
	serve(h, req)
	if got != netip.MustParseAddr("172.19.0.2") {
		t.Fatalf("bad header: got %v", got)
	}
}

func TestRequestID(t *testing.T) {
	var seen string
	h := Chain(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		seen = RequestIDFrom(r.Context())
	}), RealIP(nginx), RequestID)

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "172.19.0.2:1"
	req.Header.Set("X-Request-Id", "0123456789abcdef0123456789abcdef")
	rec := serve(h, req)
	if seen != "0123456789abcdef0123456789abcdef" || rec.Header().Get("X-Request-Id") != seen {
		t.Fatalf("trusted id should be kept, got %q", seen)
	}

	req = httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "198.51.100.1:1"
	req.Header.Set("X-Request-Id", "attacker-chosen-id-123")
	serve(h, req)
	if seen == "attacker-chosen-id-123" || len(seen) != 26 {
		t.Fatalf("untrusted id must be replaced, got %q", seen)
	}

	req = httptest.NewRequest(http.MethodGet, "/", nil)
	req.RemoteAddr = "172.19.0.2:1"
	req.Header.Set("X-Request-Id", "bad id with spaces")
	serve(h, req)
	if seen == "bad id with spaces" {
		t.Fatal("malformed id must be replaced")
	}
}

func TestNewRequestIDFormat(t *testing.T) {
	a := NewRequestID(time.UnixMilli(1_700_000_000_000))
	b := NewRequestID(time.UnixMilli(1_700_000_000_001))
	if len(a) != 26 || len(b) != 26 {
		t.Fatalf("length: %q %q", a, b)
	}
	if a[:10] >= b[:10] {
		t.Fatalf("ids should sort by time: %q %q", a, b)
	}
	for _, c := range a {
		if !strings.ContainsRune(crockford, c) {
			t.Fatalf("invalid char %q in %q", c, a)
		}
	}
}

func TestRecoverReturnsJSON500(t *testing.T) {
	var logs bytes.Buffer
	logger := logx.New(&logs, slog.LevelInfo)
	h := Chain(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		panic("boom")
	}), RealIP(nil), RequestID, Recover(logger))

	rec := serve(h, httptest.NewRequest(http.MethodGet, "/", nil))
	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status %d", rec.Code)
	}
	var body struct {
		Error struct {
			Code      string `json:"code"`
			RequestID string `json:"requestId"`
		} `json:"error"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("body: %v", err)
	}
	if body.Error.Code != CodeInternal || body.Error.RequestID == "" {
		t.Fatalf("unexpected body %s", rec.Body.String())
	}
	if strings.Contains(rec.Body.String(), "boom") || strings.Contains(rec.Body.String(), "goroutine") {
		t.Fatal("panic details must not reach the client")
	}
	if !strings.Contains(logs.String(), `"event":"panic"`) || !strings.Contains(logs.String(), "boom") {
		t.Fatalf("panic must be logged: %s", logs.String())
	}
}

func TestAccessLogRecordsRouteAndHashesIP(t *testing.T) {
	var logs bytes.Buffer
	logger := logx.New(&logs, slog.LevelInfo)
	hasher := logx.NewHasher([]byte("pepper"), []byte("ipkey"))

	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/items/{id}", func(w http.ResponseWriter, r *http.Request) {
		if li := LogInfoFrom(r.Context()); li != nil {
			anon := true
			li.UserHash, li.Anon = hasher.User("user-1"), &anon
		}
		WriteJSON(w, http.StatusTeapot, map[string]string{"ok": "yes"})
	})
	h := Chain(Router(mux), RealIP(nginx), RequestID, AccessLog(logger, hasher))

	req := httptest.NewRequest(http.MethodGet, "/v1/items/secret-123", nil)
	req.RemoteAddr = "172.19.0.2:1"
	req.Header.Set("X-Real-IP", "203.0.113.50")
	req.Header.Set("X-App-Version", "1.4.0+27")
	req.Header.Set("X-Platform", "android; drop table")
	serve(h, req)

	var rec map[string]any
	if err := json.Unmarshal(logs.Bytes(), &rec); err != nil {
		t.Fatalf("log not JSON: %v (%s)", err, logs.String())
	}
	if rec["event"] != logx.EventHTTPRequest || rec["route"] != "/v1/items/{id}" || rec["status"] != float64(418) {
		t.Fatalf("unexpected log %v", rec)
	}
	if rec["level"] != "WARN" {
		t.Errorf("4xx should log at WARN, got %v", rec["level"])
	}
	if rec["user"] != hasher.User("user-1") || rec["anon"] != true || rec["appVersion"] != "1.4.0+27" {
		t.Errorf("missing fields: %v", rec)
	}
	if _, ok := rec["platform"]; ok {
		t.Error("unsafe header values must be dropped")
	}
	raw := logs.String()
	for _, leak := range []string{"203.0.113.50", "secret-123", "user-1"} {
		if strings.Contains(raw, leak) {
			t.Errorf("log leaks %q: %s", leak, raw)
		}
	}
}

func TestDecodeJSON(t *testing.T) {
	type payload struct {
		Name string `json:"name"`
		N    int    `json:"n"`
	}
	cases := []struct {
		name, ctype, body string
		limit             int64
		status            int
	}{
		{"ok", "application/json", `{"name":"a","n":1}`, 1024, 0},
		{"charset ok", "application/json; charset=utf-8", `{"name":"a"}`, 1024, 0},
		{"wrong type header", "text/plain", `{"name":"a"}`, 1024, http.StatusUnsupportedMediaType},
		{"unknown field", "application/json", `{"name":"a","admin":true}`, 1024, http.StatusBadRequest},
		{"trailing object", "application/json", `{"name":"a"}{"name":"b"}`, 1024, http.StatusBadRequest},
		{"malformed", "application/json", `{"name":`, 1024, http.StatusBadRequest},
		{"wrong field type", "application/json", `{"n":"x"}`, 1024, http.StatusBadRequest},
		{"empty", "application/json", ``, 1024, http.StatusBadRequest},
		{"too large", "application/json", `{"name":"` + strings.Repeat("a", 100) + `"}`, 32, http.StatusRequestEntityTooLarge},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var gotErr *APIError
			h := LimitBody(tc.limit)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				var p payload
				gotErr = DecodeJSON(r, &p)
			}))
			req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(tc.body))
			req.Header.Set("Content-Type", tc.ctype)
			serve(h, req)
			if tc.status == 0 {
				if gotErr != nil {
					t.Fatalf("unexpected error %v", gotErr)
				}
				return
			}
			if gotErr == nil || gotErr.Status != tc.status {
				t.Fatalf("want status %d, got %v", tc.status, gotErr)
			}
		})
	}
}

func TestSecurityHeadersAndNotFound(t *testing.T) {
	var logs bytes.Buffer
	logger := logx.New(&logs, slog.LevelInfo)
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {})
	h := Chain(Router(mux), RealIP(nil), RequestID, AccessLog(logger, logx.NewHasher(nil, nil)), SecurityHeaders)

	rec := serve(h, httptest.NewRequest(http.MethodGet, "/nope", nil))
	if rec.Code != http.StatusNotFound {
		t.Fatalf("status %d", rec.Code)
	}
	if rec.Header().Get("X-Content-Type-Options") != "nosniff" || rec.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("missing security headers: %v", rec.Header())
	}
	body, _ := io.ReadAll(rec.Body)
	if !strings.Contains(string(body), `"code":"not_found"`) || !strings.Contains(string(body), `"requestId"`) {
		t.Fatalf("unexpected body %s", body)
	}
	if !strings.Contains(logs.String(), `"route":"unmatched"`) {
		t.Fatalf("unknown paths must log as unmatched: %s", logs.String())
	}

	rec = serve(h, httptest.NewRequest(http.MethodPost, "/healthz", nil))
	if rec.Code != http.StatusMethodNotAllowed || !strings.Contains(rec.Body.String(), `"code":"method_not_allowed"`) {
		t.Fatalf("want JSON 405, got %d %s", rec.Code, rec.Body.String())
	}
	if allow := rec.Header().Get("Allow"); !strings.Contains(allow, "GET") {
		t.Fatalf("Allow header missing: %q", allow)
	}
}
