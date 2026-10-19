#!/bin/sh
# Forced command for the GitHub Actions key of user `deploy` on the VPS.
# Installed as /usr/local/bin/riung-ci-deploy (root:root 755) and bound in
# ~deploy/.ssh/authorized_keys:
#
#   restrict,command="/usr/local/bin/riung-ci-deploy" ssh-ed25519 AAAA… riung-ci@github-actions
#
# The key can do exactly two things, so a leaked key can neither run a shell
# nor change deploy.sh / the compose file (those are copied by an admin):
#
#   check          sha256 of deploy.sh and docker-compose.prod.yml — CI stops
#                  when they differ from the commit it deploys
#   deploy <tag>   deploy ghcr.io/krisna-achmad31/riung-api:<tag> (hex git sha)
#                  with deploy.sh; stdin = the job's short-lived GITHUB_TOKEN,
#                  used for one `docker login` in a throw-away config dir
set -eu

REPO=ghcr.io/krisna-achmad31/riung-api
DIR=/var/www/riung

set -f # no globbing while splitting the client's command
# shellcheck disable=SC2086 # word splitting is intended
set -- ${SSH_ORIGINAL_COMMAND:-}

case "${1:-}:$#" in
check:1)
  cd "$DIR" && sha256sum deploy.sh docker-compose.prod.yml
  ;;
deploy:2)
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
  ;;
*)
  echo "allowed: check | deploy <tag>" >&2
  exit 2
  ;;
esac
