package appstore

import (
	"strings"
	"time"
)

// Environments Apple reports on transactions and notifications.
const (
	EnvProduction = "Production"
	EnvSandbox    = "Sandbox"
)

// Transaction types we sell.
const (
	TypeConsumable   = "Consumable"
	TypeAutoRenewing = "Auto-Renewable Subscription"
)

// Subscription statuses from Get All Subscription Statuses.
const (
	StatusActive       = 1
	StatusExpired      = 2
	StatusBillingRetry = 3
	StatusGracePeriod  = 4
	StatusRevoked      = 5
)

// Transaction is a decoded JWSTransactionDecodedPayload (fields we use).
// Dates are Unix milliseconds; 0 = absent.
type Transaction struct {
	TransactionID         string `json:"transactionId"`
	OriginalTransactionID string `json:"originalTransactionId"`
	BundleID              string `json:"bundleId"`
	ProductID             string `json:"productId"`
	Type                  string `json:"type"`
	Quantity              int    `json:"quantity"`
	PurchaseDate          int64  `json:"purchaseDate"`
	ExpiresDate           int64  `json:"expiresDate"`
	RevocationDate        int64  `json:"revocationDate"`
	AppAccountToken       string `json:"appAccountToken"`
	InAppOwnershipType    string `json:"inAppOwnershipType"`
	Environment           string `json:"environment"`
	SignedDate            int64  `json:"signedDate"`
}

// Test reports whether the transaction was made in the sandbox (TestFlight,
// App Review, sandbox testers).
func (t Transaction) Test() bool { return t.Environment != EnvProduction }

// Revoked reports whether Apple refunded or revoked the transaction.
func (t Transaction) Revoked() bool { return t.RevocationDate > 0 }

// Expires returns the expiry of a subscription transaction.
func (t Transaction) Expires() *time.Time { return msTime(t.ExpiresDate) }

// AccountToken is the appAccountToken in canonical (lowercase) form.
func (t Transaction) AccountToken() string { return strings.ToLower(t.AppAccountToken) }

// RenewalInfo is a decoded JWSRenewalInfoDecodedPayload (fields we use).
type RenewalInfo struct {
	OriginalTransactionID  string `json:"originalTransactionId"`
	AutoRenewProductID     string `json:"autoRenewProductId"`
	AutoRenewStatus        int    `json:"autoRenewStatus"` // 1 = renews
	GracePeriodExpiresDate int64  `json:"gracePeriodExpiresDate"`
	IsInBillingRetryPeriod bool   `json:"isInBillingRetryPeriod"`
	Environment            string `json:"environment"`
	SignedDate             int64  `json:"signedDate"`
}

// GraceUntil returns the end of a billing grace period, if any.
func (r RenewalInfo) GraceUntil() *time.Time { return msTime(r.GracePeriodExpiresDate) }

// SubscriptionStatus is the current state of one subscription (one
// originalTransactionId): the latest transaction and its renewal info.
type SubscriptionStatus struct {
	Status      int
	Transaction Transaction
	Renewal     RenewalInfo
}

// Notification is a decoded App Store Server Notification V2 payload.
type Notification struct {
	NotificationType string            `json:"notificationType"`
	Subtype          string            `json:"subtype"`
	NotificationUUID string            `json:"notificationUUID"`
	Version          string            `json:"version"`
	SignedDate       int64             `json:"signedDate"`
	Data             *NotificationData `json:"data"`
}

// NotificationData is the data object of a notification. The signed fields
// are JWS documents verified separately.
type NotificationData struct {
	AppAppleID            int64  `json:"appAppleId"`
	BundleID              string `json:"bundleId"`
	Environment           string `json:"environment"`
	SignedTransactionInfo string `json:"signedTransactionInfo"`
	SignedRenewalInfo     string `json:"signedRenewalInfo"`
	Status                int    `json:"status"`
}

func msTime(ms int64) *time.Time {
	if ms <= 0 {
		return nil
	}
	t := time.UnixMilli(ms).UTC()
	return &t
}
