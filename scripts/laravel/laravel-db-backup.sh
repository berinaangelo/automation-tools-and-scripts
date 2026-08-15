#!/usr/bin/env bash
# Dump + gzip + rotate the Laravel app's database. Optional S3 upload and
# Slack notification. Copy config.example.sh -> config.sh first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found. Copy config.example.sh -> config.sh and fill in." >&2
  exit 1
fi

: "${BACKUP_DIR:?Set BACKUP_DIR in config.sh}"
: "${DB_NAME:?Set DB_NAME in config.sh}"
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
FILENAME="${DB_NAME}-${TIMESTAMP}.sql.gz"
FILEPATH="$BACKUP_DIR/$FILENAME"

echo "==> Dumping $DB_CONNECTION database '$DB_NAME'"
case "$DB_CONNECTION" in
  mysql)
    MYSQL_PWD="${DB_PASSWORD:-}" mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" "$DB_NAME" \
      | gzip > "$FILEPATH"
    ;;
  pgsql)
    PGPASSWORD="${DB_PASSWORD:-}" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" \
      | gzip > "$FILEPATH"
    ;;
  *)
    echo "Error: unsupported DB_CONNECTION '$DB_CONNECTION' (expected mysql|pgsql)" >&2
    exit 1
    ;;
esac
echo "==> Wrote $FILEPATH"

if [ -n "${S3_BUCKET:-}" ]; then
  if command -v aws >/dev/null 2>&1; then
    echo "==> Uploading to s3://$S3_BUCKET/"
    aws s3 cp "$FILEPATH" "s3://$S3_BUCKET/$FILENAME" \
      || echo "Warning: S3 upload failed, backup kept locally at $FILEPATH" >&2
  else
    echo "Warning: S3_BUCKET set but aws CLI not found, skipping upload" >&2
  fi
fi

echo "==> Pruning backups older than ${BACKUP_RETENTION_DAYS:-14} days"
find "$BACKUP_DIR" -name "${DB_NAME}-*.sql.gz" -mtime "+${BACKUP_RETENTION_DAYS:-14}" -delete

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  curl -fsS -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"✅ DB backup complete: $FILENAME\"}" \
    "$SLACK_WEBHOOK_URL" >/dev/null || echo "Warning: Slack notification failed" >&2
fi
