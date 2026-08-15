#!/usr/bin/env bash
# List outdated/inactive plugins via WP-CLI as a quick attack-surface check.
# For real CVE matching, feed plugin slugs+versions into wpvulndb/Patchstack.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found. Copy config.example.sh -> config.sh and fill in." >&2
  exit 1
fi

: "${WP_PATH:?Set WP_PATH in config.sh}"

echo "==> Outdated plugins"
"$WP_CLI" --path="$WP_PATH" plugin list --update=available --format=table

echo
echo "==> Inactive plugins (dead weight / attack surface)"
"$WP_CLI" --path="$WP_PATH" plugin list --status=inactive --format=table

echo
echo "==> Core update check"
"$WP_CLI" --path="$WP_PATH" core check-update --format=table || echo "Core is up to date."
