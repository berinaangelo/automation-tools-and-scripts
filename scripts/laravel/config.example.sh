#!/usr/bin/env bash
# Copy to config.sh (gitignored) and fill in for your project.
# Never commit real paths/credentials in config.sh.

APP_DIR="/var/www/your-app"                  # Laravel project root
PHP_BIN="php"                                 # php binary (or path inside container)
ARTISAN="$APP_DIR/artisan"

# --- Backups (laravel-db-backup.sh) ---
BACKUP_DIR="/var/backups/laravel"
BACKUP_RETENTION_DAYS=14
DB_CONNECTION="mysql"                         # mysql | pgsql
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="laravel"
DB_USER="laravel"
DB_PASSWORD=""                                # prefer ~/.my.cnf / .pgpass over this
S3_BUCKET=""                                  # optional, blank = local-only backups

# --- Deploy (laravel-deploy.sh, laravel-queue-restart.sh) ---
DEPLOY_BRANCH="main"
SUPERVISOR_GROUP="laravel-worker:*"           # queue worker program group
RUN_MIGRATIONS=true

# --- Notifications (optional, all scripts) ---
SLACK_WEBHOOK_URL=""
