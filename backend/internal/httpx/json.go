package httpx

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"net/http"
)

// WriteJSON writes v as JSON with the given status.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	body, err := json.Marshal(v)
	if err != nil {
		status = http.StatusInternalServerError
		body = []byte(`{"error":{"code":"internal","message":"encode failed"}}`)
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_, _ = w.Write(append(body, '\n'))
}

type errorBody struct {
	Error errorPayload `json:"error"`
}

type errorPayload struct {
	Code      string         `json:"code"`
	Message   string         `json:"message"`
	RequestID string         `json:"requestId,omitempty"`
	Details   map[string]any `json:"details,omitempty"`
}

// WriteError writes e in the standard error envelope, including the request
// id so a user-visible error can be traced to the server log.
func WriteError(w http.ResponseWriter, r *http.Request, e *APIError) {
	WriteJSON(w, e.Status, errorBody{Error: errorPayload{
		Code:      e.Code,
		Message:   e.Message,
		RequestID: RequestIDFrom(r.Context()),
		Details:   e.Details,
	}})
}

// DecodeJSON strictly decodes a single JSON object from the request body into
// dst: the Content-Type must be JSON, unknown fields and trailing data are
// rejected, and an oversized body (see LimitBody) yields 413.
func DecodeJSON(r *http.Request, dst any) *APIError {
	mt, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mt != "application/json" {
		return NewError(http.StatusUnsupportedMediaType, CodeUnsupportedMediaType, "Content-Type must be application/json")
	}
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		return decodeError(err)
	}
	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		if err != nil {
			if apiErr := decodeError(err); apiErr.Status == http.StatusRequestEntityTooLarge {
				return apiErr
			}
		}
		return NewError(http.StatusBadRequest, CodeInvalidRequest, "body must contain a single JSON object")
	}
	return nil
}

func decodeError(err error) *APIError {
	var maxErr *http.MaxBytesError
	var syntaxErr *json.SyntaxError
	var typeErr *json.UnmarshalTypeError
	switch {
	case errors.As(err, &maxErr):
		return NewError(http.StatusRequestEntityTooLarge, CodePayloadTooLarge, fmt.Sprintf("body exceeds %d bytes", maxErr.Limit))
	case errors.Is(err, io.EOF):
		return NewError(http.StatusBadRequest, CodeInvalidRequest, "body is empty")
	case errors.As(err, &syntaxErr), errors.Is(err, io.ErrUnexpectedEOF):
		return NewError(http.StatusBadRequest, CodeInvalidRequest, "malformed JSON")
	case errors.As(err, &typeErr):
		return NewError(http.StatusBadRequest, CodeInvalidRequest, "wrong type for field "+typeErr.Field).
			WithDetails(map[string]any{"fields": []string{typeErr.Field}})
	case bytes.HasPrefix([]byte(err.Error()), []byte("json: unknown field ")):
		field := string(bytes.Trim([]byte(err.Error()[len("json: unknown field "):]), `"`))
		return NewError(http.StatusBadRequest, CodeInvalidRequest, "unknown field "+field).
			WithDetails(map[string]any{"fields": []string{field}})
	default:
		return NewError(http.StatusBadRequest, CodeInvalidRequest, "invalid JSON body")
	}
}
