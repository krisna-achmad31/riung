package httpx

import "net/http"

// Error codes returned in {"error":{"code":...}} (docs/backend-api-spec.md §1.1).
// The app maps codes to its own localized strings; Message is for debugging.
const (
	CodeInvalidRequest           = "invalid_request"
	CodeUnauthenticated          = "unauthenticated"
	CodeRecentLoginRequired      = "recent_login_required"
	CodeAppCheckFailed           = "app_check_failed"
	CodePermanentAccountRequired = "permanent_account_required"
	CodePremiumRequired          = "premium_required"
	CodeForbidden                = "forbidden"
	CodeNotFound                 = "not_found"
	CodeMethodNotAllowed         = "method_not_allowed"
	CodeInsufficientCoins        = "insufficient_coins"
	CodePriceChanged             = "price_changed"
	CodeAlreadyOwned             = "already_owned"
	CodeNotOwned                 = "not_owned"
	CodeIdempotencyKeyReuse      = "idempotency_key_reuse"
	CodeRequestInProgress        = "request_in_progress"
	CodeLimitReached             = "limit_reached"
	CodeCooldown                 = "cooldown"
	CodeTicketInvalid            = "ticket_invalid"
	CodePurchaseInvalid          = "purchase_invalid"
	CodePinLocked                = "pin_locked"
	CodePayloadTooLarge          = "payload_too_large"
	CodeUnsupportedMediaType     = "unsupported_media_type"
	CodeUpgradeRequired          = "upgrade_required"
	CodeRateLimited              = "rate_limited"
	CodeSignupLimited            = "signup_limited"
	CodeInternal                 = "internal"
	CodeUnavailable              = "unavailable"
)

// APIError is an error that maps directly to an HTTP error response.
type APIError struct {
	Status  int
	Code    string
	Message string
	Details map[string]any
}

func (e *APIError) Error() string { return e.Code + ": " + e.Message }

// NewError builds an APIError.
func NewError(status int, code, message string) *APIError {
	return &APIError{Status: status, Code: code, Message: message}
}

// WithDetails returns a copy of e carrying details.
func (e *APIError) WithDetails(d map[string]any) *APIError {
	c := *e
	c.Details = d
	return &c
}

// Common errors.
var (
	ErrNotFound         = NewError(http.StatusNotFound, CodeNotFound, "resource not found")
	ErrMethodNotAllowed = NewError(http.StatusMethodNotAllowed, CodeMethodNotAllowed, "method not allowed")
	ErrInternal         = NewError(http.StatusInternalServerError, CodeInternal, "internal error")
	ErrUnavailable      = NewError(http.StatusServiceUnavailable, CodeUnavailable, "service unavailable")
)
