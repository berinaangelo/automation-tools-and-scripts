#!/usr/bin/env bash
# Copy to config.sh (gitignored) and fill in for your site.

WP_PATH="/var/www/your-site"           # path containing wp-config.php
WP_CLI="wp"                             # wp-cli binary; add --allow-root wrapper if needed

# --- Backups (wp-backup.sh) ---
BACKUP_DIR="/var/backups/wordpress"
BACKUP_RETENTION_DAYS=14
S3_BUCKET=""                            # optional, blank = local-only

# --- Staging sync (wp-staging-sync.sh) ---
STAGING_PATH=""                         # target WP install, e.g. /var/www/your-site-staging
PROD_URL="https://example.com"
STAGING_URL="https://staging.example.com"

# --- Notifications (optional) ---
SLACK_WEBHOOK_URL=""
