-- Riung initial schema (docs/backend-go-plan.md §3, docs/backend-api-spec.md §7).
--
-- Run as riung_migrator (owner of every table). The API connects as riung_app,
-- whose privileges are set at the end of this file: append-only on the
-- financial and admin audit trails, column-limited updates on purchases.
--
-- Never stored here: journal text, check-in mood/factors/notes, Kenali Dirimu
-- results, Better Me reflections, sleep data, app-usage statistics.

-- +goose Up
CREATE EXTENSION IF NOT EXISTS citext;

-- Identity -------------------------------------------------------------------

CREATE TABLE users (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at      timestamptz NOT NULL DEFAULT now(),
    last_seen_at    timestamptz NOT NULL DEFAULT now(),
    is_anonymous    boolean     NOT NULL,
    display_name    text        NOT NULL DEFAULT '' CHECK (char_length(display_name) <= 40),
    avatar_id       text        NOT NULL DEFAULT 'av1' CHECK (char_length(avatar_id) <= 64),
    locale          text        NOT NULL DEFAULT 'id' CHECK (locale IN ('id', 'en')),
    persona         text        CHECK (char_length(persona) <= 64),
    onboarding_done boolean     NOT NULL DEFAULT false,
    tz              text        NOT NULL DEFAULT 'Asia/Jakarta' CHECK (char_length(tz) <= 64)
);
CREATE INDEX users_anonymous_last_seen_idx ON users (last_seen_at) WHERE is_anonymous;

-- Login identities, so moving off Firebase Auth later only adds rows here.
CREATE TABLE auth_identities (
    provider   text        NOT NULL CHECK (provider IN ('firebase')),
    subject    text        NOT NULL CHECK (char_length(subject) BETWEEN 1 AND 128),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (provider, subject)
);
CREATE INDEX auth_identities_user_idx ON auth_identities (user_id);

-- Profile state ----------------------------------------------------------------

CREATE TABLE subscriptions (
    user_id        uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    plan           text        NOT NULL CHECK (plan IN ('premium_monthly', 'premium_yearly')),
    status         text        NOT NULL CHECK (status IN ('active', 'in_grace', 'on_hold', 'paused', 'canceled', 'expired', 'revoked')),
    expires_at     timestamptz,
    auto_renewing  boolean     NOT NULL DEFAULT false,
    purchase_token text        UNIQUE,
    updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE streaks (
    user_id           uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    current_days      integer NOT NULL DEFAULT 0 CHECK (current_days >= 0),
    longest_days      integer NOT NULL DEFAULT 0 CHECK (longest_days >= 0),
    last_checkin_date date
);

CREATE TABLE assessments (
    user_id            uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    dominant_saboteurs text[]      NOT NULL DEFAULT '{}',
    scores             jsonb       NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(scores) = 'object'),
    completed_at       timestamptz
);

CREATE TABLE monster_progress (
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    saboteur_id text        NOT NULL CHECK (char_length(saboteur_id) <= 64),
    state       text        NOT NULL DEFAULT 'wild' CHECK (state IN ('wild', 'taming', 'tamed')),
    progress    smallint    NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
    tamed_at    timestamptz,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, saboteur_id)
);

-- Coins --------------------------------------------------------------------------

-- Balance shown in the app = earned_coins + purchased_coins. Aplikasi Beku
-- unlocks may spend earned_coins only (CLAUDE.md ethical guard).
CREATE TABLE wallets (
    user_id         uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    earned_coins    integer     NOT NULL DEFAULT 0 CHECK (earned_coins >= 0),
    purchased_coins integer     NOT NULL DEFAULT 0 CHECK (purchased_coins >= 0),
    debt_coins      integer     NOT NULL DEFAULT 0 CHECK (debt_coins >= 0),
    lifetime_earned integer     NOT NULL DEFAULT 0 CHECK (lifetime_earned >= 0),
    lifetime_spent  integer     NOT NULL DEFAULT 0 CHECK (lifetime_spent >= 0),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

-- One row per business event; the bucket split is recorded in the deltas so a
-- spend that touches both buckets stays a single idempotent row.
CREATE TABLE coin_ledger (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    type            text        NOT NULL CHECK (type IN ('earn', 'spend', 'purchase', 'refund', 'adjust')),
    amount          integer     NOT NULL,
    earned_delta    integer     NOT NULL DEFAULT 0,
    purchased_delta integer     NOT NULL DEFAULT 0,
    debt_delta      integer     NOT NULL DEFAULT 0,
    reason          text        NOT NULL CHECK (char_length(reason) <= 64),
    ref             text        CHECK (char_length(ref) <= 128),
    idempotency_key text        NOT NULL CHECK (char_length(idempotency_key) <= 160),
    balance_after   integer     NOT NULL CHECK (balance_after >= 0),
    -- clock_timestamp(): rows written in one transaction (reward + bonus) keep
    -- their real order; now() would give them all the transaction start time.
    created_at      timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (user_id, idempotency_key),
    CHECK (amount = earned_delta + purchased_delta)
);
CREATE INDEX coin_ledger_user_created_idx ON coin_ledger (user_id, created_at DESC, id DESC);

-- Business caps per local day (missions, minigame fights, rewarded journal/
-- meditation, paid unlocks, free focus tickets, premium daily coins).
CREATE TABLE daily_counters (
    user_id uuid    NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day     date    NOT NULL,
    key     text    NOT NULL CHECK (char_length(key) <= 64),
    count   integer NOT NULL DEFAULT 0 CHECK (count >= 0),
    PRIMARY KEY (user_id, day, key)
);

-- Ownership & loadouts ----------------------------------------------------------------

CREATE TABLE inventory (
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    item_id     text        NOT NULL CHECK (char_length(item_id) <= 64),
    source      text        NOT NULL CHECK (source IN ('shop', 'bundle', 'grant')),
    acquired_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, item_id)
);

CREATE TABLE consumables (
    user_id uuid    NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    kind    text    NOT NULL CHECK (kind IN ('streak_shield', 'prepaid_focus')),
    qty     integer NOT NULL DEFAULT 0 CHECK (qty >= 0),
    PRIMARY KEY (user_id, kind)
);

CREATE TABLE monster_loadouts (
    user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    saboteur_id text        NOT NULL CHECK (char_length(saboteur_id) <= 64),
    item_ids    text[]      NOT NULL DEFAULT '{}',
    updated_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, saboteur_id)
);

CREATE TABLE character_loadouts (
    user_id       uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    test_id       text        NOT NULL CHECK (char_length(test_id) <= 64),
    accessory_ids text[]      NOT NULL DEFAULT '{}',
    card_style    text        CHECK (char_length(card_style) <= 64),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, test_id)
);

CREATE TABLE betterme_completions (
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    lesson_id    text        NOT NULL CHECK (char_length(lesson_id) <= 64),
    completed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, lesson_id)
);

-- Focus & Aplikasi Beku ---------------------------------------------------------------

CREATE TABLE focus_tickets (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    source       text        NOT NULL CHECK (source IN ('free_daily', 'prepaid', 'coins')),
    duration_min integer     NOT NULL CHECK (duration_min IN (25, 45, 60)),
    issued_at    timestamptz NOT NULL DEFAULT now(),
    expires_at   timestamptz NOT NULL,
    consumed_at  timestamptz,
    CHECK (expires_at > issued_at)
);
CREATE INDEX focus_tickets_open_idx ON focus_tickets (user_id) WHERE consumed_at IS NULL;

-- Only paid-unlock counts and prices; no app-usage history is kept.
CREATE TABLE appbeku_unlocks (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    target     text        NOT NULL CHECK (char_length(target) <= 64),  -- catalog app id or bundle id
    minutes    integer     NOT NULL CHECK (minutes > 0),
    price      integer     NOT NULL CHECK (price >= 0),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX appbeku_unlocks_user_created_idx ON appbeku_unlocks (user_id, created_at DESC);

-- Purchases ---------------------------------------------------------------------------

-- Kept (anonymised) after account deletion for refunds and disputes.
CREATE TABLE purchases (
    purchase_token  text PRIMARY KEY CHECK (char_length(purchase_token) <= 512),
    user_id         uuid        REFERENCES users (id) ON DELETE SET NULL,
    user_hash       text        NOT NULL,
    product_id      text        NOT NULL CHECK (char_length(product_id) <= 64),
    kind            text        NOT NULL CHECK (kind IN ('consumable', 'subscription')),
    order_id        text,
    state           text        NOT NULL,
    credited_at     timestamptz,
    acknowledged_at timestamptz,
    voided_at       timestamptz,
    superseded_by   text,
    raw             jsonb,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX purchases_user_idx ON purchases (user_id);

CREATE TABLE rtdn_messages (
    message_id  text PRIMARY KEY CHECK (char_length(message_id) <= 128),
    received_at timestamptz NOT NULL DEFAULT now()
);

-- Journal PIN backup: hash is HMAC(server pepper, hash computed on the phone).
CREATE TABLE journal_pin_backups (
    user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    hash       text        NOT NULL,
    salt       text        NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pin_attempts (
    user_id      uuid    NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    day          date    NOT NULL,
    failures     integer NOT NULL DEFAULT 0 CHECK (failures >= 0),
    locked_until timestamptz,
    PRIMARY KEY (user_id, day)
);

-- Request safety -------------------------------------------------------------------------

CREATE TABLE idempotency_keys (
    user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    key          uuid        NOT NULL,
    route        text        NOT NULL,
    request_hash bytea       NOT NULL,
    status       integer     NOT NULL,
    response     bytea       NOT NULL,   -- exact bytes, replayed verbatim
    created_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, key)
);
CREATE INDEX idempotency_keys_created_idx ON idempotency_keys (created_at);

CREATE TABLE appcheck_jti (
    jti        text PRIMARY KEY CHECK (char_length(jti) <= 256),
    expires_at timestamptz NOT NULL
);

CREATE TABLE signup_counters (
    ip_hash text    NOT NULL,
    day     date    NOT NULL,
    count   integer NOT NULL DEFAULT 0 CHECK (count >= 0),
    PRIMARY KEY (ip_hash, day)
);

-- Hashed ids of deleted accounts, replayed after restoring a backup.
CREATE TABLE deleted_users (
    user_hash  text PRIMARY KEY,
    deleted_at timestamptz NOT NULL DEFAULT now()
);

-- Public content & waitlist ------------------------------------------------------------------

CREATE TABLE content_items (
    kind       text        NOT NULL CHECK (char_length(kind) <= 64),
    id         text        NOT NULL CHECK (char_length(id) <= 64),
    locale     text        NOT NULL CHECK (locale IN ('id', 'en')),
    position   integer     NOT NULL DEFAULT 0,
    data       jsonb       NOT NULL CHECK (jsonb_typeof(data) = 'object'),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (kind, id, locale)
);

CREATE TABLE waitlist (
    id         bigserial PRIMARY KEY,
    email      citext      NOT NULL UNIQUE CHECK (char_length(email) <= 254),
    lang       text        CHECK (char_length(lang) <= 8),
    source     text        CHECK (char_length(source) <= 32),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Admin ------------------------------------------------------------------------------------------

CREATE TABLE app_settings (
    key        text PRIMARY KEY CHECK (char_length(key) <= 64),
    value      jsonb       NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    updated_by text        NOT NULL
);

CREATE TABLE admins (
    user_id    uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    granted_at timestamptz NOT NULL DEFAULT now(),
    granted_by text        NOT NULL
);

CREATE TABLE admin_audit_log (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id uuid,   -- no FK: the trail outlives the admin account
    actor         text        NOT NULL,   -- 'admin:<hash>' or 'cli'
    action        text        NOT NULL,
    key           text,
    old_value     jsonb,
    new_value     jsonb,
    reason        text        NOT NULL CHECK (char_length(reason) BETWEEN 3 AND 500),
    request_id    text,
    created_at    timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX admin_audit_log_created_idx ON admin_audit_log (created_at DESC, id DESC);

-- Privileges for the API role ------------------------------------------------------------------

GRANT USAGE ON SCHEMA public TO riung_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO riung_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO riung_app;

-- Append-only trails: the API can add rows but never rewrite or remove them.
-- (Account deletion still cascades: referential actions run as the owner.)
REVOKE UPDATE, DELETE, TRUNCATE ON coin_ledger, admin_audit_log FROM riung_app;

-- Purchases: insert, read and update status columns only.
REVOKE UPDATE, DELETE, TRUNCATE ON purchases FROM riung_app;
GRANT UPDATE (state, credited_at, acknowledged_at, voided_at, superseded_by, raw, updated_at) ON purchases TO riung_app;

REVOKE TRUNCATE ON ALL TABLES IN SCHEMA public FROM riung_app;

-- +goose Down
DROP TABLE IF EXISTS
    admin_audit_log, admins, app_settings, waitlist, content_items, deleted_users,
    signup_counters, appcheck_jti, idempotency_keys, pin_attempts, journal_pin_backups,
    rtdn_messages, purchases, appbeku_unlocks, focus_tickets, betterme_completions,
    character_loadouts, monster_loadouts, consumables, inventory, daily_counters,
    coin_ledger, wallets, monster_progress, assessments, streaks, subscriptions,
    auth_identities, users;
