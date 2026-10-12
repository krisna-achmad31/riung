package billing

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"

	"google.golang.org/api/idtoken"

	"github.com/krisna-achmad31/riung/backend/internal/store"
)

// Real-time Developer Notifications arrive as Google Cloud Pub/Sub pushes,
// authenticated with a Google-signed OIDC token for a service account we
// configure on the push subscription. Notification contents are only hints:
// the current state is always re-read from the Play Developer API.

// PushVerifier authenticates a Pub/Sub push request.
type PushVerifier interface {
	Verify(ctx context.Context, bearer string) error
}

// ErrBadPush: the push token is missing, invalid, or not ours.
var ErrBadPush = errors.New("push authentication failed")

// GooglePushVerifier checks the OIDC token: Google signature, expiry,
// audience, Google issuer, and the configured push service account.
type GooglePushVerifier struct {
	Audience       string // must be non-empty: idtoken skips the check otherwise
	ServiceAccount string
}

// Verify implements PushVerifier.
func (g GooglePushVerifier) Verify(ctx context.Context, bearer string) error {
	if g.Audience == "" || g.ServiceAccount == "" || bearer == "" {
		return ErrBadPush
	}
	p, err := idtoken.Validate(ctx, bearer, g.Audience)
	if err != nil {
		return fmt.Errorf("%w: %w", ErrBadPush, err)
	}
	if p.Issuer != "accounts.google.com" && p.Issuer != "https://accounts.google.com" {
		return fmt.Errorf("%w: issuer %q", ErrBadPush, p.Issuer)
	}
	email, _ := p.Claims["email"].(string)
	verified, _ := p.Claims["email_verified"].(bool)
	if email != g.ServiceAccount || !verified {
		return fmt.Errorf("%w: unexpected service account", ErrBadPush)
	}
	return nil
}

// DevPushVerifier accepts the literal bearer "dev-pubsub" (DEV_BILLING only).
type DevPushVerifier struct{}

// Verify implements PushVerifier.
func (DevPushVerifier) Verify(_ context.Context, bearer string) error {
	if bearer != "dev-pubsub" { //nolint:gosec // G101: fixed dev token, DEV_BILLING is refused outside dev
		return ErrBadPush
	}
	return nil
}

// PushEnvelope is the Pub/Sub push body.
type PushEnvelope struct {
	Message struct {
		Data      string `json:"data"`
		MessageID string `json:"messageId"`
	} `json:"message"`
	Subscription string `json:"subscription"`
}

// Notification is the decoded DeveloperNotification.
type Notification struct {
	PackageName              string `json:"packageName"`
	EventTimeMillis          string `json:"eventTimeMillis"`
	SubscriptionNotification *struct {
		NotificationType int    `json:"notificationType"`
		PurchaseToken    string `json:"purchaseToken"`
		SubscriptionID   string `json:"subscriptionId"`
	} `json:"subscriptionNotification"`
	OneTimeProductNotification *struct {
		NotificationType int    `json:"notificationType"`
		PurchaseToken    string `json:"purchaseToken"`
		Sku              string `json:"sku"`
	} `json:"oneTimeProductNotification"`
	VoidedPurchaseNotification *struct {
		PurchaseToken string `json:"purchaseToken"`
		OrderID       string `json:"orderId"`
		ProductType   int    `json:"productType"`
	} `json:"voidedPurchaseNotification"`
	TestNotification *struct {
		Version string `json:"version"`
	} `json:"testNotification"`
}

// DecodePush parses the envelope and its base64 notification.
func DecodePush(env PushEnvelope) (Notification, error) {
	var n Notification
	if env.Message.MessageID == "" || len(env.Message.MessageID) > 128 {
		return n, errors.New("missing message id")
	}
	raw, err := base64.StdEncoding.DecodeString(env.Message.Data)
	if err != nil {
		return n, fmt.Errorf("message data: %w", err)
	}
	if err := json.Unmarshal(raw, &n); err != nil {
		return n, fmt.Errorf("notification: %w", err)
	}
	return n, nil
}

// HandleOutcome describes what a notification did (for logs).
type HandleOutcome struct {
	Kind      string // subscription | one_time | voided | test | ignored
	Type      int
	ProductID string
	Action    string
	Refund    *RefundResult // set when a refund changed coins or Premium
}

// HandleNotification applies one notification. packageName guards against
// notifications for another app routed to us by mistake.
func (s *Service) HandleNotification(ctx context.Context, n Notification, packageName string) (HandleOutcome, error) {
	if s.Publisher == nil {
		return HandleOutcome{}, ErrNotConfigured
	}
	if n.PackageName != packageName {
		return HandleOutcome{Kind: "ignored", Action: "other_package"}, nil
	}
	switch {
	case n.TestNotification != nil:
		return HandleOutcome{Kind: "test", Action: "logged"}, nil

	case n.VoidedPurchaseNotification != nil:
		v := n.VoidedPurchaseNotification
		r, err := s.ApplyVoided(ctx, VoidedPurchase{Token: v.PurchaseToken, OrderID: v.OrderID, VoidedAt: s.Now().UTC(), Quantity: 1})
		out := HandleOutcome{Kind: "voided", ProductID: r.ProductID, Action: "no_change"}
		if !r.AlreadyRun && r.ProductID != "" {
			out.Action, out.Refund = "refund_applied", &r
		}
		return out, err

	case n.SubscriptionNotification != nil:
		sn := n.SubscriptionNotification
		out := HandleOutcome{Kind: "subscription", Type: sn.NotificationType, ProductID: sn.SubscriptionID}
		action, err := s.refreshSubscription(ctx, sn.PurchaseToken)
		out.Action = action
		return out, err

	case n.OneTimeProductNotification != nil:
		// Purchases are credited when the app calls /billing/verify; refunds
		// arrive as voided notifications or through the daily sync.
		o := n.OneTimeProductNotification
		return HandleOutcome{Kind: "one_time", Type: o.NotificationType, ProductID: o.Sku, Action: "logged"}, nil
	}
	return HandleOutcome{Kind: "ignored", Action: "unknown_notification"}, nil
}

// refreshSubscription re-reads a subscription from Play and stores it for
// the user who owns the token (or its linked predecessor, after an upgrade or
// resubscribe). Tokens nobody has verified yet are left for /billing/verify.
func (s *Service) refreshSubscription(ctx context.Context, token string) (string, error) {
	sp, err := s.Publisher.GetSubscription(ctx, token)
	if errors.Is(err, ErrPurchaseNotFound) {
		return "unknown_token", nil
	}
	if err != nil {
		return "", err
	}
	owner := ""
	if p, err := s.Store.PurchaseByToken(ctx, token); err == nil && p.UserID != nil {
		owner = *p.UserID
	} else if err != nil && !errors.Is(err, store.ErrNotFound) {
		return "", err
	}
	if owner == "" && sp.LinkedToken != "" {
		if p, err := s.Store.PurchaseByToken(ctx, sp.LinkedToken); err == nil && p.UserID != nil {
			owner = *p.UserID
		}
	}
	if owner == "" {
		return "awaiting_verify", nil
	}
	// The owner must still match the account the app bought with.
	if sp.ObfuscatedAccount != "" && sp.ObfuscatedAccount != AccountID(s.AccountKey, owner) {
		return "account_mismatch", nil
	}
	status, ok := subscriptionStatus(sp.State)
	if !ok {
		return "pending", nil
	}
	err = s.Store.WithUserTx(ctx, owner, func(tx *store.UserTx) error {
		return s.applySubscription(tx, owner, token, sp, status)
	})
	if errors.Is(err, store.ErrPurchaseOtherUser) {
		return "other_user", nil
	}
	if err != nil {
		return "", err
	}
	return "updated:" + status, nil
}
