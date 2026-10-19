package api

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"log/slog"
	"net/http"
	"regexp"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/httpx"
	"github.com/krisna-achmad31/riung/backend/internal/logx"
	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// The phone hashes the PIN with a salt; the server only ever stores
// HMAC(PIN_PEPPER, thatHash), so a database dump alone cannot be
// brute-forced, and verification happens here with attempt limits
// (spec §4.7).

var (
	pinHashPattern = regexp.MustCompile(`^[A-Za-z0-9+/=_-]{16,256}$`)
	pinSaltPattern = regexp.MustCompile(`^[A-Za-z0-9+/=_-]{8,256}$`)
)

func (s *Server) pinMAC(hash string) string {
	m := hmac.New(sha256.New, s.Config.PinPepper)
	m.Write([]byte(hash))
	return hex.EncodeToString(m.Sum(nil))
}

// GET /v1/me/journal-pin-backup — salt only; the hash never leaves the server.
func (s *Server) getPinBackup(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	b, err := s.Store.PinBackup(r.Context(), c.User.ID)
	if errors.Is(err, store.ErrNotFound) {
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	if err != nil {
		s.internalError(w, r, "pin_backup", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"salt": b.Salt, "updatedAt": b.UpdatedAt.UTC()})
}

type pinPutRequest struct {
	Hash string `json:"hash"`
	Salt string `json:"salt"`
}

// PUT /v1/me/journal-pin-backup
func (s *Server) putPinBackup(w http.ResponseWriter, r *http.Request) {
	var req pinPutRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if !pinHashPattern.MatchString(req.Hash) {
		httpx.WriteError(w, r, invalid("hash must be 16–256 base64/hex characters", "hash"))
		return
	}
	if !pinSaltPattern.MatchString(req.Salt) {
		httpx.WriteError(w, r, invalid("salt must be 8–256 base64/hex characters", "salt"))
		return
	}
	c := callerFrom(r.Context())
	at, err := s.Store.PutPinBackup(r.Context(), c.User.ID, s.pinMAC(req.Hash), req.Salt)
	if err != nil {
		s.internalError(w, r, "put_pin_backup", err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"updatedAt": at.UTC()})
}

// DELETE /v1/me/journal-pin-backup
func (s *Server) deletePinBackup(w http.ResponseWriter, r *http.Request) {
	c := callerFrom(r.Context())
	if err := s.Store.DeletePinBackup(r.Context(), c.User.ID); err != nil {
		s.internalError(w, r, "delete_pin_backup", err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type pinVerifyRequest struct {
	Hash string `json:"hash"`
}

// POST /v1/me/journal-pin-backup/verify
func (s *Server) verifyPin(w http.ResponseWriter, r *http.Request) {
	var req pinVerifyRequest
	if apiErr := httpx.DecodeJSON(r, &req); apiErr != nil {
		httpx.WriteError(w, r, apiErr)
		return
	}
	if !pinHashPattern.MatchString(req.Hash) {
		httpx.WriteError(w, r, invalid("hash must be 16–256 base64/hex characters", "hash"))
		return
	}
	ctx := r.Context()
	c := callerFrom(ctx)
	now := s.now()
	day := utcDay(now)

	if until, err := s.Store.PinLockedUntil(ctx, c.User.ID, now); err != nil {
		s.internalError(w, r, "pin_lock", err)
		return
	} else if until != nil {
		writePinLocked(w, r, *until, now)
		return
	}

	b, err := s.Store.PinBackup(ctx, c.User.ID)
	if errors.Is(err, store.ErrNotFound) {
		httpx.WriteError(w, r, httpx.ErrNotFound)
		return
	}
	if err != nil {
		s.internalError(w, r, "pin_backup", err)
		return
	}
	if hmac.Equal([]byte(s.pinMAC(req.Hash)), []byte(b.MAC)) {
		httpx.WriteJSON(w, http.StatusOK, map[string]any{"match": true})
		return
	}

	failures, until, err := s.Store.RecordPinFailure(ctx, c.User.ID, day, now, pinMaxFailures, pinLockFor)
	if err != nil {
		s.internalError(w, r, "pin_failure", err)
		return
	}
	s.logWarn(r, logx.EventPinVerifyFailed, "journal PIN verification failed",
		slog.String(logx.KeyUser, s.Hasher.User(c.User.ID)), slog.Int("attemptsToday", failures))
	if until != nil {
		s.logWarn(r, logx.EventPinLocked, "journal PIN verification locked",
			slog.String(logx.KeyUser, s.Hasher.User(c.User.ID)))
		writePinLocked(w, r, *until, now)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"match": false, "attemptsLeft": pinMaxFailures - failures})
}

func writePinLocked(w http.ResponseWriter, r *http.Request, until, now time.Time) {
	secs := int(until.Sub(now).Seconds()) + 1
	httpx.WriteError(w, r, httpx.NewError(http.StatusConflict, httpx.CodePinLocked, "too many attempts, try again later").
		WithDetails(map[string]any{"retryAfterSeconds": secs}))
}
