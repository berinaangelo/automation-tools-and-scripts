#!/usr/bin/env bash
# Zero-drama deploy: pull, composer install, migrate, cache, restart queue.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found. Copy config.example.sh -> config.sh and fill in." >&2
  exit 1
fi

: "${APP_DIR:?Set APP_DIR in config.sh}"
cd "$APP_DIR"

echo "==> Pulling ${DEPLOY_BRANCH:-main}"
git fetch origin
git checkout "${DEPLOY_BRANCH:-main}"
git pull origin "${DEPLOY_BRANCH:-main}"

echo "==> Installing dependencies"
composer install --no-dev --optimize-autoloader

if [ "${RUN_MIGRATIONS:-true}" = true ]; then
  echo "==> Running migrations"
  "$PHP_BIN" "$ARTISAN" migrate --force
fi

echo "==> Rebuilding caches"
"$PHP_BIN" "$ARTISAN" config:cache
"$PHP_BIN" "$ARTISAN" route:cache
"$PHP_BIN" "$ARTISAN" view:cache

if [ -n "${SUPERVISOR_GROUP:-}" ] && command -v supervisorctl >/dev/null 2>&1; then
  echo "==> Restarting queue workers ($SUPERVISOR_GROUP)"
  supervisorctl restart "$SUPERVISOR_GROUP" || echo "Warning: supervisorctl restart failed" >&2
fi

echo "==> Deploy complete"
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  curl -fsS -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"🚀 Deployed $(basename "$APP_DIR") @ $(git rev-parse --short HEAD)\"}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || echo "Warning: Slack notification failed" >&2
fi
