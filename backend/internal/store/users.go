package store

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
)

// User is a row of users.
type User struct {
	ID             string
	CreatedAt      time.Time
	LastSeenAt     time.Time
	IsAnonymous    bool
	DisplayName    string
	AvatarID       string
	Locale         string
	Persona        *string
	OnboardingDone bool
	TZ             string
}

const userColumns = `u.id::text, u.created_at, u.last_seen_at, u.is_anonymous, u.display_name, u.avatar_id,
	u.locale, u.persona, u.onboarding_done, u.tz`

func scanUser(row pgx.Row) (User, error) {
	var u User
	err := row.Scan(&u.ID, &u.CreatedAt, &u.LastSeenAt, &u.IsAnonymous, &u.DisplayName, &u.AvatarID,
		&u.Locale, &u.Persona, &u.OnboardingDone, &u.TZ)
	return u, notFound(err)
}

// ResolveParams describes a verified caller to map onto a user.
type ResolveParams struct {
	Provider  string
	Subject   string
	Anonymous bool
	// Create allows creating the user when the identity is unknown.
	Create bool
	// IPHash and Day key the per-address signup counter; SignupLimit caps
	// how many accounts one address may create that day.
	IPHash      string
	Day         time.Time
	SignupLimit int
}

// lastSeenEvery throttles last_seen_at writes to at most one per hour.
const lastSeenEvery = time.Hour

// ResolveUser returns the user for an identity, creating it (with an empty
// wallet and streak) when p.Create is set. A permanent sign-in on a user still
// flagged anonymous flips the flag, so a forgotten /me/link can never leave a
// real account exposed to anonymous-account cleanup.
func (s *Store) ResolveUser(ctx context.Context, p ResolveParams) (User, bool, error) {
	for attempt := 0; attempt < 2; attempt++ {
		u, err := scanUser(s.pool.QueryRow(ctx,
			`SELECT `+userColumns+` FROM auth_identities ai JOIN users u ON u.id = ai.user_id
			 WHERE ai.provider = $1 AND ai.subject = $2`, p.Provider, p.Subject))
		if err == nil {
			if (u.IsAnonymous && !p.Anonymous) || time.Since(u.LastSeenAt) > lastSeenEvery {
				u, err = scanUser(s.pool.QueryRow(ctx,
					`UPDATE users u SET is_anonymous = u.is_anonymous AND $2, last_seen_at = now()
					 WHERE u.id = $1 RETURNING `+userColumns, u.ID, p.Anonymous))
				if err != nil {
					return User{}, false, fmt.Errorf("touch user: %w", err)
				}
			}
			return u, false, nil
		}
		if !errors.Is(err, ErrNotFound) {
			return User{}, false, fmt.Errorf("lookup identity: %w", err)
		}
		if !p.Create {
			return User{}, false, ErrNotFound
		}
		u, err = s.createUser(ctx, p)
		if errors.Is(err, errIdentityRace) {
			continue // a concurrent first request created it; read it back
		}
		return u, err == nil, err
	}
	return User{}, false, errors.New("resolve user: identity race not settled")
}

var errIdentityRace = errors.New("identity created concurrently")

func (s *Store) createUser(ctx context.Context, p ResolveParams) (User, error) {
	var u User
	err := s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		ipHash := p.IPHash
		if ipHash == "" {
			ipHash = "unknown"
		}
		var count int
		if err := tx.QueryRow(ctx,
			`INSERT INTO signup_counters (ip_hash, day, count) VALUES ($1, $2, 1)
			 ON CONFLICT (ip_hash, day) DO UPDATE SET count = signup_counters.count + 1
			 RETURNING count`, ipHash, p.Day).Scan(&count); err != nil {
			return fmt.Errorf("signup counter: %w", err)
		}
		if count > p.SignupLimit {
			return ErrSignupLimited
		}
		var err error
		u, err = scanUser(tx.QueryRow(ctx,
			`INSERT INTO users AS u (is_anonymous) VALUES ($1) RETURNING `+userColumns, p.Anonymous))
		if err != nil {
			return fmt.Errorf("insert user: %w", err)
		}
		if _, err := tx.Exec(ctx,
			`INSERT INTO auth_identities (provider, subject, user_id) VALUES ($1, $2, $3)`,
			p.Provider, p.Subject, u.ID); err != nil {
			if isUniqueViolation(err) {
				return errIdentityRace
			}
			return fmt.Errorf("insert identity: %w", err)
		}
		if _, err := tx.Exec(ctx, `INSERT INTO wallets (user_id) VALUES ($1)`, u.ID); err != nil {
			return fmt.Errorf("insert wallet: %w", err)
		}
		if _, err := tx.Exec(ctx, `INSERT INTO streaks (user_id) VALUES ($1)`, u.ID); err != nil {
			return fmt.Errorf("insert streak: %w", err)
		}
		return nil
	})
	return u, err
}

// UserByIdentity looks up a user without creating one.
func (s *Store) UserByIdentity(ctx context.Context, provider, subject string) (User, error) {
	return scanUser(s.pool.QueryRow(ctx,
		`SELECT `+userColumns+` FROM auth_identities ai JOIN users u ON u.id = ai.user_id
		 WHERE ai.provider = $1 AND ai.subject = $2`, provider, subject))
}

// ProfilePatch holds optional profile fields; nil means "leave unchanged".
type ProfilePatch struct {
	DisplayName    *string
	AvatarID       *string
	Locale         *string
	Persona        *string
	OnboardingDone *bool
	TZ             *string
}

// UpdateProfile applies patch and returns the updated user.
func (s *Store) UpdateProfile(ctx context.Context, userID string, p ProfilePatch) (User, error) {
	return scanUser(s.pool.QueryRow(ctx, `UPDATE users u SET
			display_name    = COALESCE($2, u.display_name),
			avatar_id       = COALESCE($3, u.avatar_id),
			locale          = COALESCE($4, u.locale),
			persona         = COALESCE($5, u.persona),
			onboarding_done = u.onboarding_done OR COALESCE($6, false),
			tz              = COALESCE($7, u.tz)
		WHERE u.id = $1 RETURNING `+userColumns,
		userID, p.DisplayName, p.AvatarID, p.Locale, p.Persona, p.OnboardingDone, p.TZ))
}

// MarkPermanent clears is_anonymous after a successful account link.
func (s *Store) MarkPermanent(ctx context.Context, userID string) (User, error) {
	return scanUser(s.pool.QueryRow(ctx,
		`UPDATE users u SET is_anonymous = false WHERE u.id = $1 RETURNING `+userColumns, userID))
}

// DeleteUser removes the user and everything that cascades from it, keeps
// purchases anonymised (FK SET NULL) and records the hashed id so a restored
// backup can be re-scrubbed.
func (s *Store) DeleteUser(ctx context.Context, userID, userHash string) error {
	return s.inTx(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx,
			`INSERT INTO deleted_users (user_hash) VALUES ($1) ON CONFLICT DO NOTHING`, userHash); err != nil {
			return fmt.Errorf("record deletion: %w", err)
		}
		tag, err := tx.Exec(ctx, `DELETE FROM users WHERE id = $1`, userID)
		if err != nil {
			return fmt.Errorf("delete user: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return ErrNotFound
		}
		return nil
	})
}
