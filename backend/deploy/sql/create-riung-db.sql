-- One-time setup of the riung database on shared-postgres (PostgreSQL 16).
--
-- Run as the shared-postgres superuser. Passwords come from the environment so
-- they never appear in shell history or the process list:
--
--   docker exec -i \
--     -e RIUNG_MIGRATOR_PASSWORD="$(openssl rand -base64 32)" \
--     -e RIUNG_APP_PASSWORD="$(openssl rand -base64 32)" \
--     shared-postgres psql -U n8n -d postgres -v ON_ERROR_STOP=1 \
--     < backend/deploy/sql/create-riung-db.sql
--
-- (Generate the passwords first, keep them for /var/www/riung/.env and
-- .env.migrate, then pass them with -e as above.)
--
-- Result:
--   riung_migrator  owns database riung and all tables (DDL, used by `riung migrate`)
--   riung_app       DML only, privileges set by the migrations (used by `riung api`)
-- Neither role is a superuser or can create roles/databases.

\set ON_ERROR_STOP on
\set migrator_password ''
\set app_password ''
\getenv migrator_password RIUNG_MIGRATOR_PASSWORD
\getenv app_password RIUNG_APP_PASSWORD

-- Abort (non-zero exit) unless both passwords are set and at least 16 chars.
SELECT length(:'migrator_password') >= 16 AND length(:'app_password') >= 16 AS passwords_ok \gset
\if :passwords_ok
\else
  DO $$ BEGIN RAISE EXCEPTION 'RIUNG_MIGRATOR_PASSWORD and RIUNG_APP_PASSWORD must be set (>= 16 chars)'; END $$;
\endif

CREATE ROLE riung_migrator LOGIN PASSWORD :'migrator_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION CONNECTION LIMIT 5;
CREATE ROLE riung_app LOGIN PASSWORD :'app_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION CONNECTION LIMIT 20;

CREATE DATABASE riung OWNER riung_migrator ENCODING 'UTF8' TEMPLATE template0;
REVOKE ALL ON DATABASE riung FROM PUBLIC;
GRANT CONNECT ON DATABASE riung TO riung_app;

\connect riung
-- PG15+ already gives schema public to the database owner; be explicit.
ALTER SCHEMA public OWNER TO riung_migrator;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO riung_app;
