package store_test

import (
	"context"
	"testing"
	"time"

	"github.com/krisna-achmad31/riung/backend/internal/store"
	"github.com/krisna-achmad31/riung/backend/internal/testdb"
)

func TestInactiveAnonymousCleanup(t *testing.T) {
	pool := testdb.Pool(t)
	st := store.New(pool)
	ctx := context.Background()

	old, _, _ := st.ResolveUser(ctx, params("anon-old", true))
	recent, _, _ := st.ResolveUser(ctx, params("anon-recent", true))
	perm, _, _ := st.ResolveUser(ctx, params("perm-old", false))
	for _, id := range []string{old.ID, perm.ID} {
		if _, err := pool.Exec(ctx, `UPDATE users SET last_seen_at = now() - interval '100 days' WHERE id = $1`, id); err != nil {
			t.Fatal(err)
		}
	}
	cutoff := time.Now().Add(-90 * 24 * time.Hour)
	list, err := st.InactiveAnonymousUsers(ctx, cutoff, 10)
	if err != nil || len(list) != 1 || list[0].UserID != old.ID || len(list[0].Subjects) != 1 || list[0].Subjects[0] != "anon-old" {
		t.Fatalf("only the inactive anonymous account: %+v %v", list, err)
	}
	// A sign-in between listing and deleting saves the account.
	if _, err := pool.Exec(ctx, `UPDATE users SET last_seen_at = now() WHERE id = $1`, old.ID); err != nil {
		t.Fatal(err)
	}
	if ok, err := st.DeleteInactiveAnonymous(ctx, old.ID, "h_old", cutoff); err != nil || ok {
		t.Fatalf("active again: %v %v", ok, err)
	}
	if _, err := pool.Exec(ctx, `UPDATE users SET last_seen_at = now() - interval '100 days' WHERE id = $1`, old.ID); err != nil {
		t.Fatal(err)
	}
	if ok, err := st.DeleteInactiveAnonymous(ctx, old.ID, "h_old", cutoff); err != nil || !ok {
		t.Fatalf("delete: %v %v", ok, err)
	}
	if _, err := st.UserByIdentity(ctx, "firebase", "anon-old"); err == nil {
		t.Fatal("deleted account must be gone")
	}
	for _, id := range []string{recent.ID, perm.ID} {
		if _, err := st.Snapshot(ctx, id, time.Now()); err != nil {
			t.Fatalf("other accounts stay: %v", err)
		}
	}
	hashes, err := st.DeletedUserHashes(ctx)
	if err != nil || !hashes["h_old"] {
		t.Fatalf("deletion recorded for backup restores: %v %v", hashes, err)
	}
}

func TestUserIDsAfterPagesAllUsers(t *testing.T) {
	st := store.New(testdb.Pool(t))
	ctx := context.Background()
	want := map[string]bool{}
	for _, s := range []string{"p1", "p2", "p3"} {
		u, _, _ := st.ResolveUser(ctx, params(s, true))
		want[u.ID] = true
	}
	seen := map[string]bool{}
	after := "00000000-0000-0000-0000-000000000000"
	for {
		ids, err := st.UserIDsAfter(ctx, after, 2)
		if err != nil {
			t.Fatal(err)
		}
		if len(ids) == 0 {
			break
		}
		for _, id := range ids {
			seen[id] = true
		}
		after = ids[len(ids)-1]
	}
	for id := range want {
		if !seen[id] {
			t.Fatalf("paging missed %s", id)
		}
	}
	if err := st.DeleteUserByID(ctx, after); err != nil {
		t.Fatal(err)
	}
}
