-- Aggregates for the business dashboard in Grafana. The read-only role
-- riung_metrics (deploy/sql/create-riung-metrics-role.sql) may read these
-- views and nothing else: counts and sums only — no user id, email, token or
-- content. Days are Asia/Jakarta (the users' default timezone). Views run
-- with the owner's rights, so riung_metrics needs no access to the tables.

-- +goose Up
CREATE SCHEMA metrics;

CREATE VIEW metrics.users_summary AS
SELECT count(*)                                                         AS accounts,
       count(*) FILTER (WHERE NOT is_anonymous)                         AS permanent,
       count(*) FILTER (WHERE last_seen_at > now() - interval '1 day')  AS active_1d,
       count(*) FILTER (WHERE last_seen_at > now() - interval '7 days') AS active_7d,
       count(*) FILTER (WHERE last_seen_at > now() - interval '30 days') AS active_30d
FROM users;

CREATE VIEW metrics.daily_signups AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       count(*)                                       AS accounts,
       count(*) FILTER (WHERE NOT is_anonymous)       AS permanent_now
FROM users
GROUP BY 1;

-- Users who practised (any accepted activity) per day.
CREATE VIEW metrics.daily_active_users AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       count(DISTINCT user_id)                        AS users
FROM activity_events
GROUP BY 1;

CREATE VIEW metrics.daily_activity AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       type,
       count(*)                                       AS events,
       count(DISTINCT user_id)                        AS users
FROM activity_events
GROUP BY 1, 2;

CREATE VIEW metrics.daily_coins AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       type,
       reason,
       count(*)                                       AS entries,
       sum(amount)                                    AS coins,
       sum(earned_delta)                              AS earned,
       sum(purchased_delta)                           AS purchased,
       sum(debt_delta)                                AS debt
FROM coin_ledger
GROUP BY 1, 2, 3;

CREATE VIEW metrics.daily_purchases AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       CASE WHEN purchase_token LIKE 'appstore:%' THEN 'app_store' ELSE 'play' END AS store,
       product_id,
       kind,
       -- Play/App Store test purchases (license testers, sandbox, TestFlight).
       COALESCE((raw ->> 'Test')::boolean, (raw ->> 'environment') <> 'Production', false) AS test,
       count(*)                                       AS purchases,
       count(*) FILTER (WHERE voided_at IS NOT NULL)  AS refunded
FROM purchases
GROUP BY 1, 2, 3, 4, 5;

CREATE VIEW metrics.premium_status AS
SELECT plan,
       status,
       count(*)                                       AS subscriptions,
       count(*) FILTER (WHERE expires_at > now())     AS not_expired,
       count(*) FILTER (WHERE auto_renewing)          AS auto_renewing
FROM subscriptions
GROUP BY 1, 2;

CREATE VIEW metrics.monster_states AS
SELECT saboteur_id, state, count(*) AS users
FROM monster_progress
GROUP BY 1, 2;

CREATE VIEW metrics.daily_focus AS
SELECT (issued_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       source,
       duration_min,
       count(*)                                       AS tickets,
       count(*) FILTER (WHERE consumed_at IS NOT NULL) AS redeemed
FROM focus_tickets
GROUP BY 1, 2, 3;

CREATE VIEW metrics.daily_appbeku AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       count(*)                                       AS unlocks,
       sum(minutes)                                   AS minutes,
       sum(price)                                     AS coins
FROM appbeku_unlocks
GROUP BY 1;

CREATE VIEW metrics.daily_waitlist AS
SELECT (created_at AT TIME ZONE 'Asia/Jakarta')::date AS day,
       COALESCE(source, '')                           AS source,
       count(*)                                       AS signups
FROM waitlist
GROUP BY 1, 2;

-- The role is created outside migrations (it needs a password); grant when
-- it already exists, the role script grants again otherwise.
-- +goose StatementBegin
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'riung_metrics') THEN
        GRANT USAGE ON SCHEMA metrics TO riung_metrics;
        GRANT SELECT ON ALL TABLES IN SCHEMA metrics TO riung_metrics;
    END IF;
END
$$;
-- +goose StatementEnd

-- +goose Down
DROP SCHEMA IF EXISTS metrics CASCADE;
