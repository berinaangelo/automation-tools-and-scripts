#!/usr/bin/env bash
# DB dump + wp-content tarball backup with rotation, via WP-CLI.
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
: "${BACKUP_DIR:?Set BACKUP_DIR in config.sh}"
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DB_FILE="$BACKUP_DIR/db-${TIMESTAMP}.sql.gz"
CONTENT_FILE="$BACKUP_DIR/wp-content-${TIMESTAMP}.tar.gz"

echo "==> Exporting DB"
"$WP_CLI" --path="$WP_PATH" db export - | gzip > "$DB_FILE"

echo "==> Archiving wp-content"
tar -czf "$CONTENT_FILE" -C "$WP_PATH" wp-content

echo "==> Wrote $DB_FILE and $CONTENT_FILE"

if [ -n "${S3_BUCKET:-}" ]; then
  if command -v aws >/dev/null 2>&1; then
    aws s3 cp "$DB_FILE" "s3://$S3_BUCKET/" || echo "Warning: S3 upload of DB failed" >&2
    aws s3 cp "$CONTENT_FILE" "s3://$S3_BUCKET/" || echo "Warning: S3 upload of wp-content failed" >&2
  else
    echo "Warning: S3_BUCKET set but aws CLI not found, skipping upload" >&2
  fi
fi

echo "==> Pruning backups older than ${BACKUP_RETENTION_DAYS:-14} days"
find "$BACKUP_DIR" \( -name "db-*.sql.gz" -o -name "wp-content-*.tar.gz" \) \
  -mtime "+${BACKUP_RETENTION_DAYS:-14}" -delete

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  curl -fsS -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"✅ WP backup complete: $(basename "$DB_FILE"), $(basename "$CONTENT_FILE")\"}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || echo "Warning: Slack notification failed" >&2
fi
