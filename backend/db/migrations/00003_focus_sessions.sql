-- When a redeemed Focus session ended (focus_completed occurredAt). Used to
-- refuse sessions that overlap an earlier one: several tickets cannot be
-- "completed" for the same stretch of time.

-- +goose Up
ALTER TABLE focus_tickets ADD COLUMN session_ended_at timestamptz;
CREATE INDEX focus_tickets_sessions_idx ON focus_tickets (user_id, session_ended_at)
    WHERE session_ended_at IS NOT NULL;

-- +goose Down
DROP INDEX IF EXISTS focus_tickets_sessions_idx;
ALTER TABLE focus_tickets DROP COLUMN IF EXISTS session_ended_at;
