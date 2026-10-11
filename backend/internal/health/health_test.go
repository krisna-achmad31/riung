package health

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/krisna-achmad31/riung/backend/internal/logx"
)

type fakePinger struct{ err error }

func (f fakePinger) Ping(context.Context) error { return f.err }

func TestLive(t *testing.T) {
	rec := httptest.NewRecorder()
	Live().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"ok"`) {
		t.Fatalf("got %d %s", rec.Code, rec.Body.String())
	}
}

func TestReady(t *testing.T) {
	var logs bytes.Buffer
	logger := logx.New(&logs, slog.LevelInfo)

	rec := httptest.NewRecorder()
	Ready(fakePinger{}, logger).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("healthy db: got %d", rec.Code)
	}

	rec = httptest.NewRecorder()
	Ready(fakePinger{err: errors.New("connection refused")}, logger).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if rec.Code != http.StatusServiceUnavailable || !strings.Contains(rec.Body.String(), `"unavailable"`) {
		t.Fatalf("down db: got %d %s", rec.Code, rec.Body.String())
	}
	if strings.Contains(rec.Body.String(), "connection refused") {
		t.Fatal("dependency errors must not reach the client")
	}
	if !strings.Contains(logs.String(), `"event":"dependency_error"`) {
		t.Fatalf("failure must be logged: %s", logs.String())
	}
}
