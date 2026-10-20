// Package alert sends operational alarms to Telegram. Following the
// core-shared convention, applications alert directly (Grafana alerting stays
// empty): Handler forwards ERROR log records and a few business events from
// slog, the watchdog sends its own findings, and nothing here can block or
// break logging.
package alert

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"sync"
	"time"
)

// Sender delivers one message.
type Sender interface {
	Send(ctx context.Context, text string) error
}

// Telegram sends through the Bot API.
type Telegram struct {
	Token  string
	ChatID string
	// BaseURL overrides https://api.telegram.org (tests).
	BaseURL string
	HTTP    *http.Client
}

// Send implements Sender (plain text, no link previews).
func (t *Telegram) Send(ctx context.Context, text string) error {
	base := t.BaseURL
	if base == "" {
		base = "https://api.telegram.org"
	}
	client := t.HTTP
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	body, _ := json.Marshal(map[string]any{"chat_id": t.ChatID, "text": text, "disable_web_page_preview": true})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, base+"/bot"+t.Token+"/sendMessage", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		// url.Error prints the URL, which holds the token: keep only the cause.
		var ue *url.Error
		if errors.As(err, &ue) {
			return fmt.Errorf("telegram: %w", ue.Err)
		}
		return errors.New("telegram: request failed")
	}
	defer func() { _ = resp.Body.Close() }()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("telegram: status %d", resp.StatusCode)
	}
	return nil
}

// Notifier queues alarms and sends them in the background: deduplicated per
// key for Window (repeats are counted into the next message), at most
// MaxPerHour messages, dropped when the queue is full. Logging never waits
// for Telegram.
type Notifier struct {
	sender     Sender
	label      string
	window     time.Duration
	maxPerHour int
	now        func() time.Time
	onError    func(error)

	queue chan string
	done  chan struct{}

	mu         sync.Mutex
	last       map[string]time.Time
	suppressed map[string]int
	hour       time.Time
	sentInHour int
	closed     bool
}

// Options configures a Notifier.
type Options struct {
	// Label prefixes every message, e.g. "riung prod".
	Label      string
	Window     time.Duration // default 10 minutes
	MaxPerHour int           // default 30
	Now        func() time.Time
	// OnError receives send failures (default: ignored). It must not log at
	// ERROR through the alerting handler, or failures would loop.
	OnError func(error)
}

// New starts a notifier; Close flushes it.
func New(s Sender, o Options) *Notifier {
	if o.Window <= 0 {
		o.Window = 10 * time.Minute
	}
	if o.MaxPerHour <= 0 {
		o.MaxPerHour = 30
	}
	if o.Now == nil {
		o.Now = time.Now
	}
	n := &Notifier{sender: s, label: o.Label, window: o.Window, maxPerHour: o.MaxPerHour, now: o.Now, onError: o.OnError,
		queue: make(chan string, 64), done: make(chan struct{}),
		last: map[string]time.Time{}, suppressed: map[string]int{}}
	go n.run()
	return n
}

func (n *Notifier) run() {
	defer close(n.done)
	for text := range n.queue {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		err := n.sender.Send(ctx, text)
		cancel()
		if err != nil && n.onError != nil {
			n.onError(err)
		}
	}
}

// Notify queues text under key (dedupe). It reports whether it was queued.
func (n *Notifier) Notify(key, text string) bool {
	if n == nil {
		return false
	}
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.closed {
		return false
	}
	now := n.now()
	if t, ok := n.last[key]; ok && now.Sub(t) < n.window {
		n.suppressed[key]++
		return false
	}
	if h := now.Truncate(time.Hour); !h.Equal(n.hour) {
		n.hour, n.sentInHour = h, 0
	}
	if n.sentInHour >= n.maxPerHour {
		n.suppressed[key]++
		return false
	}
	msg := text
	if s := n.suppressed[key]; s > 0 {
		msg += fmt.Sprintf("\n(+%d serupa sejak pesan sebelumnya)", s)
	}
	if n.label != "" {
		msg = n.label + " · " + msg
	}
	select {
	case n.queue <- truncate(msg, 3500):
	default:
		n.suppressed[key]++
		return false
	}
	n.last[key], n.suppressed[key] = now, 0
	n.sentInHour++
	return true
}

// Close stops accepting alarms and waits up to timeout for queued ones.
func (n *Notifier) Close(timeout time.Duration) {
	if n == nil {
		return
	}
	n.mu.Lock()
	if n.closed {
		n.mu.Unlock()
		return
	}
	n.closed = true
	close(n.queue)
	n.mu.Unlock()
	select {
	case <-n.done:
	case <-time.After(timeout):
	}
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max] + "…"
}

// Handler wraps a slog.Handler and forwards records at ERROR or above, plus
// WARN/INFO records whose event is in Events, to the notifier.
type Handler struct {
	next   slog.Handler
	n      *Notifier
	events map[string]bool
	attrs  []slog.Attr
	group  string
}

// NewHandler forwards to n; events lists extra events to alert on below ERROR
// (e.g. refund_applied).
func NewHandler(next slog.Handler, n *Notifier, events ...string) *Handler {
	m := map[string]bool{}
	for _, e := range events {
		m[e] = true
	}
	return &Handler{next: next, n: n, events: m}
}

// Enabled implements slog.Handler.
func (h *Handler) Enabled(ctx context.Context, l slog.Level) bool { return h.next.Enabled(ctx, l) }

// WithAttrs implements slog.Handler.
func (h *Handler) WithAttrs(as []slog.Attr) slog.Handler {
	c := *h
	c.next = h.next.WithAttrs(as)
	c.attrs = append(append([]slog.Attr(nil), h.attrs...), as...)
	return &c
}

// WithGroup implements slog.Handler.
func (h *Handler) WithGroup(name string) slog.Handler {
	c := *h
	c.next = h.next.WithGroup(name)
	c.group = name
	return &c
}

// Fields never sent to Telegram (too long for a chat message).
var skipFields = map[string]bool{"stack": true}

// Handle implements slog.Handler.
func (h *Handler) Handle(ctx context.Context, r slog.Record) error {
	err := h.next.Handle(ctx, r)
	if h.n == nil {
		return err
	}
	fields := map[string]string{}
	for _, a := range h.attrs {
		fields[a.Key] = a.Value.String()
	}
	r.Attrs(func(a slog.Attr) bool {
		fields[a.Key] = a.Value.String()
		return true
	})
	event := fields["event"]
	if r.Level < slog.LevelError && !h.events[event] {
		return err
	}
	keys := make([]string, 0, len(fields))
	for k := range fields {
		if k != "event" && !skipFields[k] {
			keys = append(keys, k)
		}
	}
	sort.Strings(keys)
	var b strings.Builder
	fmt.Fprintf(&b, "%s %s · %s\n%s", levelIcon(r.Level), r.Level, event, r.Message)
	for _, k := range keys {
		fmt.Fprintf(&b, "\n%s: %s", k, truncate(fields[k], 300))
	}
	h.n.Notify(event+"|"+r.Message+"|"+fields["dependency"]+fields["job"], b.String())
	return err
}

func levelIcon(l slog.Level) string {
	if l >= slog.LevelError {
		return "🔴"
	}
	return "🟠"
}
