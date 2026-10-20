#!/bin/sh
# Host cron for `riung watchdog` (runbook step 8b). Installed as
# /usr/local/bin/riung-watchdog (root:root 755):
#
#   */2 * * * * /usr/local/bin/riung-watchdog >/dev/null 2>&1
#
# The watchdog runs in its own short-lived container (same image as
# riung-api, so it works while riung-api is down) and alerts through
# ALERT_TELEGRAM_* from .env. If even that container cannot start, a plain
# Telegram message is sent with curl, at most once an hour.
set -u

DIR=/var/www/riung
STATE=/var/lib/riung-watchdog

# Image of the running API; the last one seen if the container is gone.
if img="$(docker inspect -f '{{.Config.Image}}' riung-api 2>/dev/null)" && [ -n "$img" ]; then
  printf '%s\n' "$img" >"$STATE/image"
else
  img="$(cat "$STATE/image" 2>/dev/null || true)"
fi

rc=1
if [ -n "$img" ]; then
  timeout 90 docker run --rm --name riung-watchdog --read-only --cap-drop ALL --user 65532:65532 \
    --memory 64m --pids-limit 50 --network vps-shared-net \
    --env-file "$DIR/.env" --env-file "$DIR/.env.watchdog" \
    -v /var/backups/riung:/backups:ro -v "$STATE:/state" \
    "$img" watchdog
  rc=$?
fi
[ "$rc" -eq 0 ] && exit 0

# Fallback alarm: the watchdog itself could not run.
marker="$STATE/fallback-sent"
if [ -z "$(find "$marker" -mmin -60 2>/dev/null)" ]; then
  token="$(sed -n 's/^ALERT_TELEGRAM_BOT_TOKEN=//p' "$DIR/.env" | tail -1)"
  chat="$(sed -n 's/^ALERT_TELEGRAM_CHAT_ID=//p' "$DIR/.env" | tail -1)"
  if [ -n "$token" ] && [ -n "$chat" ]; then
    curl -fsS -m 15 -o /dev/null "https://api.telegram.org/bot${token}/sendMessage" \
      --data-urlencode "chat_id=${chat}" \
      --data-urlencode "text=🚨 riung watchdog tidak bisa jalan di $(hostname) (exit ${rc}, image '${img:-tidak ada}'). Cek docker & /var/lib/riung-watchdog." &&
      touch "$marker"
  fi
fi
exit "$rc"
