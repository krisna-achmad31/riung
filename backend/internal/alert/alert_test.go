package alert_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/alert"
)

type recorder struct {
	mu   sync.Mutex
	msgs []string
}

func (r *recorder) Send(_ context.Context, text string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.msgs = append(r.msgs, text)
	return nil
}

func (r *recorder) all() []string {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]string(nil), r.msgs...)
}

type clock struct{ t time.Time }

func (c *clock) now() time.Time { return c.t }

func TestHandlerForwardsErrorsAndListedEvents(t *testing.T) {
	rec := &recorder{}
	n := alert.New(rec, alert.Options{Label: "riung prod"})
	var out bytes.Buffer
	logger := slog.New(alert.NewHandler(slog.NewJSONHandler(&out, nil), n, "refund_applied")).With("requestId", "r-1")

	logger.Info("request", "event", "http_request", "status", 200)
	logger.Warn("rate limited", "event", "rate_limited")
	logger.Error("google play unavailable", "event", "dependency_error", "dependency", "google_play", "stack", "very long")
	logger.Warn("refund applied", "event", "refund_applied", "productId", "coin_pack_small", "coinsClawedBack", 80)
	n.Close(time.Second)

	msgs := rec.all()
	if len(msgs) != 2 {
		t.Fatalf("want 2 alarms (error + refund), got %d: %q", len(msgs), msgs)
	}
	if !strings.HasPrefix(msgs[0], "riung prod · 🔴 ERROR · dependency_error\ngoogle play unavailable") ||
		!strings.Contains(msgs[0], "dependency: google_play") || !strings.Contains(msgs[0], "requestId: r-1") ||
		strings.Contains(msgs[0], "very long") {
		t.Fatalf("error message: %q", msgs[0])
	}
	if !strings.Contains(msgs[1], "🟠 WARN · refund_applied") || !strings.Contains(msgs[1], "coinsClawedBack: 80") {
		t.Fatalf("refund message: %q", msgs[1])
	}
	if strings.Count(out.String(), "\n") != 4 {
		t.Fatalf("every record must still be logged:\n%s", out.String())
	}
}

func TestNotifierDedupesAndCaps(t *testing.T) {
	rec := &recorder{}
	c := &clock{time.Date(2026, 10, 20, 8, 0, 0, 0, time.UTC)}
	n := alert.New(rec, alert.Options{Window: 10 * time.Minute, MaxPerHour: 3, Now: c.now})
	if !n.Notify("db", "postgres down") || n.Notify("db", "postgres down") || n.Notify("db", "postgres down") {
		t.Fatal("repeats within the window must be held back")
	}
	c.t = c.t.Add(11 * time.Minute)
	if !n.Notify("db", "postgres down") {
		t.Fatal("after the window the alarm is sent again")
	}
	n.Notify("a", "x")
	if n.Notify("b", "y") {
		t.Fatal("at most 3 per hour")
	}
	c.t = c.t.Add(time.Hour)
	if !n.Notify("b", "y") {
		t.Fatal("a new hour resets the cap")
	}
	n.Close(time.Second)
	msgs := rec.all()
	if len(msgs) != 4 || !strings.Contains(msgs[1], "(+2 serupa sejak pesan sebelumnya)") || !strings.Contains(msgs[3], "(+1 serupa") {
		t.Fatalf("messages: %q", msgs)
	}
	if n.Notify("late", "after close") {
		t.Fatal("closed notifier accepts nothing")
	}
	var nilN *alert.Notifier
	if nilN.Notify("x", "y") {
		t.Fatal("nil notifier is a no-op")
	}
	nilN.Close(time.Millisecond)
}

func TestTelegramSend(t *testing.T) {
	var got map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/bot123:ABC/sendMessage" {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		_ = json.NewDecoder(r.Body).Decode(&got)
		_, _ = w.Write([]byte(`{"ok":true}`))
	}))
	defer srv.Close()
	tg := &alert.Telegram{Token: "123:ABC", ChatID: "408667565", BaseURL: srv.URL}
	if err := tg.Send(context.Background(), "halo"); err != nil {
		t.Fatal(err)
	}
	if got["chat_id"] != "408667565" || got["text"] != "halo" || got["disable_web_page_preview"] != true {
		t.Fatalf("body %v", got)
	}
	bad := &alert.Telegram{Token: "123:ABC", ChatID: "1", BaseURL: srv.URL + "/nope"}
	if err := bad.Send(context.Background(), "x"); err == nil {
		t.Fatal("non-200 must fail")
	}
	// A network error must not carry the token (it is in the URL).
	down := &alert.Telegram{Token: "123:SECRET", ChatID: "1", BaseURL: "http://127.0.0.1:1"}
	err := down.Send(context.Background(), "x")
	if err == nil || strings.Contains(err.Error(), "SECRET") {
		t.Fatalf("error leaks the token or is nil: %v", err)
	}
}

type failing struct{}

func (failing) Send(context.Context, string) error { return errors.New("boom") }

func TestSendErrorsGoToOnError(t *testing.T) {
	got := make(chan error, 1)
	n := alert.New(failing{}, alert.Options{OnError: func(err error) { got <- err }})
	n.Notify("k", "v")
	n.Close(time.Second)
	select {
	case err := <-got:
		if err.Error() != "boom" {
			t.Fatal(err)
		}
	default:
		t.Fatal("send error not reported")
	}
}
