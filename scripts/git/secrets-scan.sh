#!/usr/bin/env bash
# Pre-commit-style scan for likely secrets in tracked or staged files.
# Usage: ./secrets-scan.sh [--staged]
set -euo pipefail

MODE="${1:---all}"

# --- tweak me: add/remove patterns as needed ---
PATTERNS=(
  'AKIA[0-9A-Z]{16}'                              # AWS access key
  'aws_secret_access_key'
  '-----BEGIN (RSA|EC|OPENSSH|DSA) PRIVATE KEY-----'
  'ghp_[0-9A-Za-z]{36}'                            # GitHub PAT
  'xox[baprs]-[0-9A-Za-z-]{10,}'                   # Slack token
  '["\x27]?password["\x27]?[[:space:]]*[:=][[:space:]]*["\x27][^"\x27]{6,}["\x27]'
  'api[_-]?key[[:space:]]*[:=][[:space:]]*["\x27][A-Za-z0-9]{16,}["\x27]'
)
# ------------------------------------------------

if [ "$MODE" = "--staged" ]; then
  FILES="$(git diff --cached --name-only --diff-filter=ACM)"
else
  FILES="$(git ls-files)"
fi

HITS_FILE="$(mktemp)"
trap 'rm -f "$HITS_FILE"' EXIT

FOUND=0
for FILE in $FILES; do
  [ -f "$FILE" ] || continue
  for PATTERN in "${PATTERNS[@]}"; do
    if grep -EnI "$PATTERN" "$FILE" > "$HITS_FILE" 2>/dev/null; then
      echo "!! $FILE"
      sed 's/^/     /' "$HITS_FILE"
      FOUND=1
    fi
  done
done

if [ "$FOUND" -eq 1 ]; then
  echo "==> Potential secrets found above. Review before committing." >&2
  exit 1
fi
echo "==> No obvious secrets found."
