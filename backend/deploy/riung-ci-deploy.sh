#!/bin/sh
# Forced command for the GitHub Actions key of user `deploy` on the VPS.
# Installed as /usr/local/bin/riung-ci-deploy (root:root 755) and bound in
# ~deploy/.ssh/authorized_keys:
#
#   restrict,command="/usr/local/bin/riung-ci-deploy" ssh-ed25519 AAAA… riung-ci@github-actions
#
# The key can do exactly two things, so a leaked key can neither run a shell
# nor change deploy.sh / the compose files (those are copied by an admin):
#
#   check [staging]          sha256 of deploy.sh and the compose file — CI stops
#                            when they differ from the commit it deploys
#   deploy <tag> [staging]   deploy ghcr.io/krisna-achmad31/riung-api:<tag> (hex git
#                            sha) with deploy.sh; stdin = the job's short-lived
#                            GITHUB_TOKEN, used for one `docker login` in a
#                            throw-away config dir
#
# Without "staging": production (/var/www/riung). With it: /var/www/riung-staging.
set -eu

REPO=ghcr.io/krisna-achmad31/riung-api

set -f # no globbing while splitting the client's command
# shellcheck disable=SC2086 # word splitting is intended
set -- ${SSH_ORIGINAL_COMMAND:-}

usage() {
  echo "allowed: check [staging] | deploy <tag> [staging]" >&2
  exit 2
}
cmd="${1:-}"
case "$cmd:$#" in
check:1 | deploy:2) target=production ;;
check:2) target=$2 ;;
deploy:3) target=$3 ;;
*) usage ;;
esac
[ "$target" = production ] || [ "$target" = staging ] || usage

if [ "$target" = staging ]; then
  DIR=/var/www/riung-staging
  RIUNG_COMPOSE_FILE=docker-compose.staging.yml
  RIUNG_CONTAINER=riung-staging-api
else
  DIR=/var/www/riung
  RIUNG_COMPOSE_FILE=docker-compose.prod.yml
  RIUNG_CONTAINER=riung-api
fi
export RIUNG_COMPOSE_FILE RIUNG_CONTAINER

if [ "$cmd" = check ]; then
  cd "$DIR" && sha256sum deploy.sh "$RIUNG_COMPOSE_FILE"
  exit 0
fi

tag=$2
case "$tag" in
*[!0-9a-f]* | "") echo "invalid tag" >&2 && exit 2 ;;
esac
if [ "${#tag}" -lt 7 ] || [ "${#tag}" -gt 40 ]; then
  echo "invalid tag" >&2 && exit 2
fi
DOCKER_CONFIG="$(mktemp -d)"
export DOCKER_CONFIG
trap 'rm -rf "$DOCKER_CONFIG"' EXIT
token="$(cat)"
if [ -n "$token" ]; then
  printf '%s' "$token" | docker login ghcr.io -u riung-ci --password-stdin >/dev/null
fi
cd "$DIR" && ./deploy.sh "$REPO:$tag"
