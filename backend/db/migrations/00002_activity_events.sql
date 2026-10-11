-- Processed practice events (POST /v1/activities). One row per business key
-- (checkin:<date>, journal:<entryId>, …): a replayed event returns the stored
-- result instead of granting coins, progress or counters twice — including
-- events that were capped and granted nothing.

-- +goose Up
CREATE TABLE activity_events (
    user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    key        text        NOT NULL CHECK (char_length(key) <= 160),
    type       text        NOT NULL,
    result     jsonb       NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, key)
);

-- Append-only for the API role, like the coin ledger.
GRANT SELECT, INSERT ON activity_events TO riung_app;

-- +goose Down
DROP TABLE IF EXISTS activity_events;
