-- Read-only role for the Grafana business dashboard (runbook step 8c).
--
-- Run as the shared-postgres superuser AFTER migration 00004 (schema metrics):
--
--   docker exec -i -e RIUNG_METRICS_PASSWORD="$PW" \
--     shared-postgres psql -U n8n -d riung -v ON_ERROR_STOP=1 \
--     < backend/deploy/sql/create-riung-metrics-role.sql
--
-- riung_metrics can only SELECT the aggregate views in schema metrics (no
-- tables, no user ids or personal data). Safe to run again: it updates the
-- password and re-applies the grants.

\set ON_ERROR_STOP on
\set metrics_password ''
\getenv metrics_password RIUNG_METRICS_PASSWORD

SELECT length(:'metrics_password') >= 16 AS password_ok \gset
\if :password_ok
\else
  DO $$ BEGIN RAISE EXCEPTION 'RIUNG_METRICS_PASSWORD must be set (>= 16 chars)'; END $$;
\endif

SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'riung_metrics') AS role_exists \gset
\if :role_exists
  ALTER ROLE riung_metrics PASSWORD :'metrics_password';
\else
  CREATE ROLE riung_metrics LOGIN PASSWORD :'metrics_password'
      NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION CONNECTION LIMIT 3;
\endif
-- Dashboards must never hold connections or run long queries.
ALTER ROLE riung_metrics SET statement_timeout = '10s';
ALTER ROLE riung_metrics SET default_transaction_read_only = on;

GRANT CONNECT ON DATABASE riung TO riung_metrics;
GRANT USAGE ON SCHEMA metrics TO riung_metrics;
GRANT SELECT ON ALL TABLES IN SCHEMA metrics TO riung_metrics;
