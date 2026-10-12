package api

import (
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/ratelimit"
)

// Per-caller rate limits (docs/backend-api-spec.md §5.2). Keyed by user id
// on authenticated routes and by hashed IP on public ones.
var (
	// Public reads are keyed by IP. Indonesian mobile carriers put many users
	// behind one CGNAT address, so these are flood guards, not fairness limits.
	rlConfig  = ratelimit.Policy{Name: "config", Limit: 600, Window: time.Minute}
	rlContent = ratelimit.Policy{Name: "content", Limit: 600, Window: time.Minute}
	// The waitlist is IP-keyed too (no login); generous for shared addresses.
	rlWaitlist = ratelimit.Policy{Name: "waitlist", Limit: 20, Window: time.Hour}

	// Each endpoint has its own bucket: using one must never block another
	// (e.g. exporting data must not prevent deleting the account).
	rlMe         = ratelimit.Policy{Name: "me", Limit: 60, Window: time.Minute}
	rlJournal    = ratelimit.Policy{Name: "journal_access", Limit: 60, Window: time.Minute}
	rlWallet     = ratelimit.Policy{Name: "wallet", Limit: 60, Window: time.Minute}
	rlProfile    = ratelimit.Policy{Name: "profile", Limit: 20, Window: time.Minute}
	rlAssessment = ratelimit.Policy{Name: "assessment", Limit: 10, Window: time.Minute}
	rlLink       = ratelimit.Policy{Name: "link", Limit: 5, Window: time.Hour}
	rlDelete     = ratelimit.Policy{Name: "delete_account", Limit: 3, Window: time.Hour}
	rlExport     = ratelimit.Policy{Name: "export", Limit: 3, Window: time.Hour}
	rlPinRead    = ratelimit.Policy{Name: "pin_read", Limit: 10, Window: time.Minute}
	rlPinWrite   = ratelimit.Policy{Name: "pin_write", Limit: 5, Window: time.Hour}
	rlPinVerify  = ratelimit.Policy{Name: "pin_verify", Limit: 5, Window: 15 * time.Minute}

	rlActivity      = ratelimit.Policy{Name: "activity", Limit: 60, Window: time.Minute}
	rlActivityBatch = ratelimit.Policy{Name: "activity_batch", Limit: 10, Window: time.Minute}
	rlTransactions  = ratelimit.Policy{Name: "transactions", Limit: 30, Window: time.Minute}
	rlShop          = ratelimit.Policy{Name: "shop", Limit: 10, Window: time.Minute}
	rlPremiumDaily  = ratelimit.Policy{Name: "premium_daily", Limit: 10, Window: time.Minute}
	rlLoadout       = ratelimit.Policy{Name: "loadout", Limit: 30, Window: time.Minute}
	rlFocusIssue    = ratelimit.Policy{Name: "focus_ticket", Limit: 20, Window: time.Minute}
	rlFocusList     = ratelimit.Policy{Name: "focus_tickets_list", Limit: 30, Window: time.Minute}
	rlAppBeku       = ratelimit.Policy{Name: "appbeku_unlock", Limit: 10, Window: time.Minute}
	rlVerifyMin     = ratelimit.Policy{Name: "billing_verify", Limit: 10, Window: time.Minute}
	rlVerifyHour    = ratelimit.Policy{Name: "billing_verify_hour", Limit: 30, Window: time.Hour}
	rlRestore       = ratelimit.Policy{Name: "billing_restore", Limit: 5, Window: time.Hour}
	rlSubscription  = ratelimit.Policy{Name: "billing_subscription", Limit: 30, Window: time.Minute}
	rlWebhookIP     = ratelimit.Policy{Name: "play_webhook_ip", Limit: 120, Window: time.Minute}
	rlWebhook       = ratelimit.Policy{Name: "play_webhook", Limit: 300, Window: time.Minute}
	rlAdminRead     = ratelimit.Policy{Name: "admin_read", Limit: 30, Window: time.Minute}
	rlAdminWrite    = ratelimit.Policy{Name: "admin_write", Limit: 10, Window: time.Minute}
)

// maxBatchEvents caps POST /v1/activities/batch.
const maxBatchEvents = 50

// Journal PIN lockout: after pinMaxFailures failed checks in a day the backup
// cannot be verified for pinLockFor.
const (
	pinMaxFailures = 10
	pinLockFor     = time.Hour
)

// freshAuthMaxAge is how recent a permanent account's sign-in must be for
// destructive actions (account deletion).
const freshAuthMaxAge = 5 * time.Minute
