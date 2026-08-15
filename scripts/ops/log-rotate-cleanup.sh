#!/usr/bin/env bash
# Truncate app/nginx logs older than N days on servers provisioned via
# terraform-templates/system-setup.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found. Copy config.example.sh -> config.sh and fill in." >&2
  exit 1
fi

RETENTION="${LOG_RETENTION_DAYS:-30}"

for PATTERN in "${LOG_PATHS[@]}"; do
  for FILE in $PATTERN; do
    [ -f "$FILE" ] || continue
    if find "$FILE" -mtime "+$RETENTION" -print -quit | grep -q .; then
      echo "==> Truncating $FILE (older than ${RETENTION}d)"
      : > "$FILE"
    fi
  done
done

echo "==> Log cleanup complete"
