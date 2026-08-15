#!/usr/bin/env bash
# Gracefully restart Laravel queue workers (artisan signal + supervisor reload).
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

echo "==> Signaling queue:restart"
"$PHP_BIN" "$ARTISAN" queue:restart

if [ -n "${SUPERVISOR_GROUP:-}" ] && command -v supervisorctl >/dev/null 2>&1; then
  echo "==> Reloading supervisor group $SUPERVISOR_GROUP"
  supervisorctl restart "$SUPERVISOR_GROUP"
else
  echo "Note: no SUPERVISOR_GROUP configured or supervisorctl not found; artisan signal only."
fi
