#!/usr/bin/env bash
# Pull prod DB + uploads down to staging, with URL search-replace.
# DESTRUCTIVE to the staging DB — confirms before running.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found. Copy config.example.sh -> config.sh and fill in." >&2
  exit 1
fi

: "${WP_PATH:?Set WP_PATH (prod) in config.sh}"
: "${STAGING_PATH:?Set STAGING_PATH in config.sh}"
: "${PROD_URL:?Set PROD_URL in config.sh}"
: "${STAGING_URL:?Set STAGING_URL in config.sh}"

read -r -p "This will OVERWRITE the staging DB at $STAGING_PATH. Continue? [y/N] " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

TMP_SQL="$(mktemp)"
trap 'rm -f "$TMP_SQL"' EXIT

echo "==> Exporting prod DB"
"$WP_CLI" --path="$WP_PATH" db export "$TMP_SQL"

echo "==> Importing into staging"
"$WP_CLI" --path="$STAGING_PATH" db import "$TMP_SQL"

echo "==> Search-replace URLs"
"$WP_CLI" --path="$STAGING_PATH" search-replace "$PROD_URL" "$STAGING_URL" \
  --all-tables --skip-columns=guid

echo "==> Syncing uploads"
rsync -avz --delete "$WP_PATH/wp-content/uploads/" "$STAGING_PATH/wp-content/uploads/"

echo "==> Staging sync complete"
