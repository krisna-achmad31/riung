#!/bin/sh
# Local development only: creates the riung roles and database inside the dev
# Postgres container using the same script as production, with fixed dev
# passwords. Runs once on an empty volume (docker-entrypoint-initdb.d).
set -eu
export RIUNG_MIGRATOR_PASSWORD=riung_migrator_dev_pw
export RIUNG_APP_PASSWORD=riung_app_dev_pw_local
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -f /riung/create-riung-db.sql
