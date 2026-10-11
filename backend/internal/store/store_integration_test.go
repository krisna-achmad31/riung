package store_test

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/store"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

var day = time.Date(2026, 10, 11, 0, 0, 0, 0, time.UTC)

func params(subject string, anon bool) store.ResolveParams {
	return store.ResolveParams{Provider: "firebase", Subject: subject, Anonymous: anon, Create: true,
		IPHash: "ip_test", Day: day, SignupLimit: 100}
}

func TestResolveUserCreatesOnceAndFlipsAnonymous(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()

	u, created, err := st.ResolveUser(ctx, params("uid-1", true))
	if err != nil || !created || !u.IsAnonymous || u.TZ != "Asia/Jakarta" || u.AvatarID != "av1" {
		t.Fatalf("create: %+v created=%v err=%v", u, created, err)
	}
	again, created, err := st.ResolveUser(ctx, params("uid-1", true))
	if err != nil || created || again.ID != u.ID {
		t.Fatalf("second resolve must return the same user: %+v %v %v", again, created, err)
	}
	// Signing in with a permanent provider clears the anonymous flag.
	perm, _, err := st.ResolveUser(ctx, params("uid-1", false))
	if err != nil || perm.IsAnonymous {
		t.Fatalf("permanent sign-in must flip is_anonymous: %+v %v", perm, err)
	}
	// …and an anonymous token later never flips it back.
	back, _, _ := st.ResolveUser(ctx, params("uid-1", true))
	if back.IsAnonymous {
		t.Fatal("is_anonymous must never flip back to true")
	}

	snap, err := st.Snapshot(ctx, u.ID, day)
	if err != nil {
		t.Fatalf("snapshot: %v", err)
	}
	if snap.Wallet.Coins() != 0 || snap.Streak.CurrentDays != 0 || len(snap.Inventory) != 0 || snap.Subscription != nil {
		t.Fatalf("new user must start empty: %+v", snap)
	}
}

func TestResolveUserNoCreate(t *testing.T) {
	st := store.New(testdb.Pool(t))
	p := params("ghost", true)
	p.Create = false
	if _, _, err := st.ResolveUser(context.Background(), p); !errors.Is(err, store.ErrNotFound) {
		t.Fatalf("want ErrNotFound, got %v", err)
	}
}

func TestResolveUserConcurrentFirstRequests(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	var wg sync.WaitGroup
	ids := make([]string, 8)
	errs := make([]error, 8)
	for i := range ids {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			u, _, err := st.ResolveUser(ctx, params("same-uid", true))
			ids[i], errs[i] = u.ID, err
		}(i)
	}
	wg.Wait()
	for i := range ids {
		if errs[i] != nil {
			t.Fatalf("request %d: %v", i, errs[i])
		}
		if ids[i] != ids[0] {
			t.Fatalf("concurrent first requests created different users: %v", ids)
		}
	}
}

func TestSignupLimit(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	for i, sub := range []string{"a", "b"} {
		p := params(sub, true)
		p.SignupLimit = 2
		if _, _, err := st.ResolveUser(ctx, p); err != nil {
			t.Fatalf("signup %d: %v", i, err)
		}
	}
	p := params("c", true)
	p.SignupLimit = 2
	if _, _, err := st.ResolveUser(ctx, p); !errors.Is(err, store.ErrSignupLimited) {
		t.Fatalf("third signup from same IP must be limited, got %v", err)
	}
	// Existing users from that IP are unaffected; another IP or day is fine.
	p = params("a", true)
	p.SignupLimit = 2
	if _, _, err := st.ResolveUser(ctx, p); err != nil {
		t.Fatalf("existing user must still resolve: %v", err)
	}
	p = params("d", true)
	p.SignupLimit, p.IPHash = 2, "ip_other"
	if _, _, err := st.ResolveUser(ctx, p); err != nil {
		t.Fatalf("other IP must be allowed: %v", err)
	}
}

func TestProfileAssessmentDeleteAndExport(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	u, _, err := st.ResolveUser(ctx, params("uid-p", false))
	if err != nil {
		t.Fatal(err)
	}
	name, tz, done := "Rani", "Asia/Makassar", true
	got, err := st.UpdateProfile(ctx, u.ID, store.ProfilePatch{DisplayName: &name, TZ: &tz, OnboardingDone: &done})
	if err != nil || got.DisplayName != "Rani" || got.TZ != tz || !got.OnboardingDone || got.Locale != "id" {
		t.Fatalf("update: %+v %v", got, err)
	}
	notDone := false
	got, _ = st.UpdateProfile(ctx, u.ID, store.ProfilePatch{OnboardingDone: &notDone})
	if !got.OnboardingDone {
		t.Fatal("onboardingDone must not go back to false")
	}

	at := time.Date(2026, 10, 10, 8, 0, 0, 0, time.UTC)
	if err := st.PutAssessment(ctx, u.ID, store.Assessment{DominantSaboteurs: []string{"waswas"}, Scores: map[string]int{"waswas": 80}, CompletedAt: &at}); err != nil {
		t.Fatal(err)
	}
	snap, _ := st.Snapshot(ctx, u.ID, day)
	if snap.Assessment == nil || snap.Assessment.Scores["waswas"] != 80 {
		t.Fatalf("assessment not stored: %+v", snap.Assessment)
	}

	ex, err := st.Export(ctx, u.ID, day)
	if err != nil || ex.Snapshot.User.ID != u.ID || ex.Ledger == nil || ex.Purchases == nil {
		t.Fatalf("export: %+v %v", ex, err)
	}

	if err := st.DeleteUser(ctx, u.ID, "u_hash"); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if _, err := st.UserByIdentity(ctx, "firebase", "uid-p"); !errors.Is(err, store.ErrNotFound) {
		t.Fatalf("identity must be gone, got %v", err)
	}
	if err := st.DeleteUser(ctx, u.ID, "u_hash"); !errors.Is(err, store.ErrNotFound) {
		t.Fatalf("second delete: want ErrNotFound, got %v", err)
	}
}

func TestPinAttemptsLock(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	u, _, _ := st.ResolveUser(ctx, params("uid-pin", false))
	now := time.Date(2026, 10, 11, 9, 0, 0, 0, time.UTC)
	if _, err := st.PutPinBackup(ctx, u.ID, "mac", "salt1234"); err != nil {
		t.Fatal(err)
	}
	for i := 1; i <= 3; i++ {
		n, until, err := st.RecordPinFailure(ctx, u.ID, day, now, 3, time.Hour)
		if err != nil || n != i || (i < 3 && until != nil) || (i == 3 && until == nil) {
			t.Fatalf("failure %d: n=%d until=%v err=%v", i, n, until, err)
		}
	}
	if until, _ := st.PinLockedUntil(ctx, u.ID, day, now.Add(30*time.Minute)); until == nil {
		t.Fatal("must be locked for an hour")
	}
	if until, _ := st.PinLockedUntil(ctx, u.ID, day, now.Add(61*time.Minute)); until != nil {
		t.Fatal("lock must expire")
	}
}

func TestIdempotency(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	u, _, _ := st.ResolveUser(ctx, params("uid-idem", true))
	key := "6f1c2c56-4a7e-4f55-9a0d-6a2f1d7b9c01"

	stored, err := st.BeginIdempotent(ctx, u.ID, key, "PATCH /v1/me/profile", []byte("h1"))
	if err != nil || stored != nil {
		t.Fatalf("first begin: %v %v", stored, err)
	}
	if _, err := st.BeginIdempotent(ctx, u.ID, key, "PATCH /v1/me/profile", []byte("h1")); !errors.Is(err, store.ErrIdempotencyInProgress) {
		t.Fatalf("concurrent duplicate must be in progress, got %v", err)
	}
	if err := st.CompleteIdempotent(ctx, u.ID, key, 200, []byte(`{"ok":true}`)); err != nil {
		t.Fatal(err)
	}
	stored, err = st.BeginIdempotent(ctx, u.ID, key, "PATCH /v1/me/profile", []byte("h1"))
	if err != nil || stored == nil || stored.Status != 200 || string(stored.Body) != `{"ok":true}` {
		t.Fatalf("replay: %+v %v", stored, err)
	}
	if _, err := st.BeginIdempotent(ctx, u.ID, key, "PATCH /v1/me/profile", []byte("h2")); !errors.Is(err, store.ErrIdempotencyMismatch) {
		t.Fatalf("different body must mismatch, got %v", err)
	}
	// Aborted keys can be retried.
	key2 := "6f1c2c56-4a7e-4f55-9a0d-6a2f1d7b9c02"
	_, _ = st.BeginIdempotent(ctx, u.ID, key2, "r", []byte("h"))
	_ = st.AbortIdempotent(ctx, u.ID, key2)
	if stored, err := st.BeginIdempotent(ctx, u.ID, key2, "r", []byte("h")); err != nil || stored != nil {
		t.Fatalf("aborted key must be reusable: %v %v", stored, err)
	}
}

func TestContentAndWaitlist(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	items := []store.ContentItem{
		{ID: "b", Position: 1, Data: json.RawMessage(`{"id":"b"}`)},
		{ID: "a", Position: 0, Data: json.RawMessage(`{"id":"a"}`)},
	}
	if err := st.ReplaceContent(ctx, "saboteurs", "id", items); err != nil {
		t.Fatal(err)
	}
	list, err := st.Content(ctx, "saboteurs", "id")
	if err != nil || len(list.Items) != 2 || string(list.Items[0]) != `{"id": "a"}` || list.ETag == "" {
		t.Fatalf("content: %+v %v (%s)", list, err, list.Items)
	}
	before := list.ETag
	_ = st.ReplaceContent(ctx, "saboteurs", "id", items[:1])
	list, _ = st.Content(ctx, "saboteurs", "id")
	if len(list.Items) != 1 || list.ETag == before {
		t.Fatalf("replace must drop old items and change the ETag: %+v", list)
	}

	isNew, err := st.AddWaitlist(ctx, "a@example.com", "id", "landing")
	if err != nil || !isNew {
		t.Fatalf("waitlist new: %v %v", isNew, err)
	}
	isNew, err = st.AddWaitlist(ctx, "A@Example.com", "", "")
	if err != nil || isNew {
		t.Fatalf("waitlist must be case-insensitive unique: %v %v", isNew, err)
	}
}

func TestCreditRepaysDebtFirst(t *testing.T) {
	pool := testdb.Pool(t)
	st := store.New(pool)
	ctx := context.Background()
	u, _, _ := st.ResolveUser(ctx, params("uid-debt", false))
	// A refund left 7 coins of debt (set directly; B3 writes this).
	if _, err := pool.Exec(ctx, `UPDATE wallets SET debt_coins = 7 WHERE user_id = $1`, u.ID); err != nil {
		t.Fatal(err)
	}
	err := st.WithUserTx(ctx, u.ID, func(tx *store.UserTx) error {
		if _, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: 5, Reason: "checkin", Key: "a"}); err != nil {
			return err
		}
		_, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: 5, Reason: "checkin", Key: "b"})
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	w, _ := st.Wallet(ctx, u.ID)
	if w.DebtCoins != 0 || w.EarnedCoins != 3 || w.LifetimeEarned != 10 {
		t.Fatalf("debt must be repaid before coins reach the wallet: %+v", w)
	}
	items, _, err := st.Transactions(ctx, u.ID, 10, "")
	if err != nil || len(items) != 2 || items[0].DebtDelta != -2 || items[1].DebtDelta != -5 || items[1].Amount != 0 {
		t.Fatalf("ledger rows: %+v %v", items, err)
	}
	// Reusing a key is a no-op.
	_ = st.WithUserTx(ctx, u.ID, func(tx *store.UserTx) error {
		applied, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: 5, Reason: "checkin", Key: "a"})
		if applied || err != nil {
			t.Errorf("duplicate key: applied=%v err=%v", applied, err)
		}
		return nil
	})
}

func TestTransactionsPaging(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	u, _, _ := st.ResolveUser(ctx, params("uid-pages", false))
	_ = st.WithUserTx(ctx, u.ID, func(tx *store.UserTx) error {
		for i := 0; i < 5; i++ {
			if _, err := tx.Credit(store.Credit{Type: "earn", Bucket: store.BucketEarned, Amount: 1, Reason: "t", Key: string(rune('a' + i))}); err != nil {
				return err
			}
		}
		return nil
	})
	seen := map[string]bool{}
	cursor := ""
	for page := 0; page < 5; page++ {
		items, next, err := st.Transactions(ctx, u.ID, 2, cursor)
		if err != nil {
			t.Fatal(err)
		}
		for _, it := range items {
			if seen[it.ID] {
				t.Fatalf("duplicate across pages: %s", it.ID)
			}
			seen[it.ID] = true
		}
		if next == "" {
			break
		}
		cursor = next
	}
	if len(seen) != 5 {
		t.Fatalf("paging returned %d of 5 rows", len(seen))
	}
	if _, _, err := st.Transactions(ctx, u.ID, 2, "garbage!"); !errors.Is(err, store.ErrBadCursor) {
		t.Fatalf("bad cursor: %v", err)
	}
}

func TestPurgeKeepsRecentRows(t *testing.T) {
	pool := testdb.Pool(t)
	st := store.New(pool)
	ctx := context.Background()
	u, _, _ := st.ResolveUser(ctx, params("uid-purge", false))
	if _, err := pool.Exec(ctx, `INSERT INTO idempotency_keys (user_id, key, route, request_hash, status, response, created_at) VALUES
		($1, '00000000-0000-4000-8000-000000000001', 'r', 'h', 200, '', now() - interval '8 days'),
		($1, '00000000-0000-4000-8000-000000000002', 'r', 'h', 200, '', now())`, u.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, `INSERT INTO daily_counters (user_id, day, key, count) VALUES
		($1, current_date - 40, 'minigame', 4), ($1, current_date, 'minigame', 1)`, u.ID); err != nil {
		t.Fatal(err)
	}
	res, err := st.Purge(ctx)
	if err != nil || res.IdempotencyKeys != 1 || res.DailyCounters != 1 {
		t.Fatalf("purge: %+v %v", res, err)
	}
	var left int
	_ = pool.QueryRow(ctx, `SELECT count(*) FROM idempotency_keys`).Scan(&left)
	if left != 1 {
		t.Fatalf("recent idempotency key must stay, left %d", left)
	}
}

func TestIdempotencyStaleClaimCanBeRetaken(t *testing.T) {
	pool := testdb.Pool(t)
	st := store.New(pool)
	ctx := context.Background()
	u, _, _ := st.ResolveUser(ctx, params("uid-stale", false))
	key := "00000000-0000-4000-8000-0000000000aa"
	if stored, err := st.BeginIdempotent(ctx, u.ID, key, "r", []byte("h")); err != nil || stored != nil {
		t.Fatal(err)
	}
	if _, err := st.BeginIdempotent(ctx, u.ID, key, "r", []byte("h")); !errors.Is(err, store.ErrIdempotencyInProgress) {
		t.Fatalf("fresh claim blocks: %v", err)
	}
	// Simulate a crash two minutes ago.
	_, _ = pool.Exec(ctx, `UPDATE idempotency_keys SET created_at = now() - interval '2 minutes' WHERE key = $1`, key)
	if stored, err := st.BeginIdempotent(ctx, u.ID, key, "r", []byte("h")); err != nil || stored != nil {
		t.Fatalf("abandoned claim must be retaken: %v %v", stored, err)
	}
	if _, err := st.BeginIdempotent(ctx, u.ID, key, "r", []byte("h")); !errors.Is(err, store.ErrIdempotencyInProgress) {
		t.Fatalf("retaken claim blocks again: %v", err)
	}
}
