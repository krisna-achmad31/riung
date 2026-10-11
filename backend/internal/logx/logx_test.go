package logx

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/netip"
	"strings"
	"testing"
	"time"
)

func TestLoggerWritesUTCJSON(t *testing.T) {
	var buf bytes.Buffer
	New(&buf, slog.LevelInfo).Info("hello", KeyEvent, EventStartup)

	var rec map[string]any
	if err := json.Unmarshal(buf.Bytes(), &rec); err != nil {
		t.Fatalf("not JSON: %v (%s)", err, buf.String())
	}
	ts, _ := rec["time"].(string)
	if !strings.HasSuffix(ts, "Z") {
		t.Errorf("time must be UTC, got %q", ts)
	}
	if rec["level"] != "INFO" || rec["msg"] != "hello" || rec["event"] != EventStartup {
		t.Errorf("unexpected record: %v", rec)
	}
}

func TestLoggerRespectsLevel(t *testing.T) {
	var buf bytes.Buffer
	New(&buf, slog.LevelWarn).Info("dropped")
	if buf.Len() != 0 {
		t.Fatalf("info should be dropped at warn level: %s", buf.String())
	}
}

func TestUserHash(t *testing.T) {
	h := NewHasher([]byte("pepper-a"), []byte("ip-key"))
	a := h.User("7b1e0000-0000-0000-0000-000000000001")
	if a != h.User("7b1e0000-0000-0000-0000-000000000001") {
		t.Fatal("hash must be stable")
	}
	if !strings.HasPrefix(a, "u_") || len(a) != 18 {
		t.Fatalf("unexpected format %q", a)
	}
	if strings.Contains(a, "7b1e") {
		t.Fatal("hash must not leak the id")
	}
	if a == NewHasher([]byte("pepper-b"), nil).User("7b1e0000-0000-0000-0000-000000000001") {
		t.Fatal("hash must depend on the pepper")
	}
}

func TestIPHashRotatesDaily(t *testing.T) {
	h := NewHasher(nil, []byte("ip-key"))
	ip := netip.MustParseAddr("203.0.113.7")
	day1 := time.Date(2026, 10, 11, 1, 0, 0, 0, time.UTC)
	sameDay := time.Date(2026, 10, 11, 23, 59, 0, 0, time.UTC)
	day2 := time.Date(2026, 10, 12, 0, 0, 1, 0, time.UTC)

	if h.IP(ip, day1) != h.IP(ip, sameDay) {
		t.Fatal("same UTC day must give the same hash")
	}
	if h.IP(ip, day1) == h.IP(ip, day2) {
		t.Fatal("hash must change the next day")
	}
	if got := h.IP(ip, day1); !strings.HasPrefix(got, "ip_") || strings.Contains(got, "203") {
		t.Fatalf("unexpected IP hash %q", got)
	}
	mapped := netip.MustParseAddr("::ffff:203.0.113.7")
	if h.IP(mapped, day1) != h.IP(ip, day1) {
		t.Fatal("IPv4-mapped IPv6 must hash like plain IPv4")
	}
	if h.IP(netip.Addr{}, day1) != "" {
		t.Fatal("invalid address hashes to empty")
	}
}
