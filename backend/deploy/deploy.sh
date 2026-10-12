#!/bin/sh
# Deploy a riung-api image on the VPS. Run from /var/www/riung (where
# docker-compose.prod.yml, .env and .env.migrate live):
#
#   ./deploy.sh ghcr.io/krisna-achmad31/riung-api:<git-sha>
#
# Order: pull → migrate (one-shot, DDL credentials) → recreate the API →
# wait for its healthcheck. A failed migration stops the deploy before the
# running API is touched.
set -eu

IMAGE="${1:?usage: deploy.sh <image>}"
export RIUNG_IMAGE="$IMAGE"
COMPOSE="docker compose -f docker-compose.prod.yml"

# An image already on the host (e.g. loaded with `docker load` before the
# first CI release, or a rollback tag) is used as is.
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "==> using local image $IMAGE"
else
  echo "==> pull $IMAGE"
  $COMPOSE --profile migrate pull
fi

echo "==> migrate"
$COMPOSE --profile migrate up --no-deps --abort-on-container-exit --exit-code-from riung-migrate riung-migrate
$COMPOSE --profile migrate rm -f riung-migrate >/dev/null

echo "==> start riung-api"
$COMPOSE up -d --no-deps riung-api

echo "==> wait for healthy"
i=0
while [ "$i" -lt 30 ]; do
  status="$(docker inspect -f '{{.State.Health.Status}}' riung-api 2>/dev/null || echo unknown)"
  if [ "$status" = "healthy" ]; then
    echo "riung-api healthy ($IMAGE)"
    exit 0
  fi
  i=$((i + 1))
  sleep 2
done
echo "riung-api did not become healthy; recent logs:" >&2
docker logs --tail 50 riung-api >&2
exit 1
