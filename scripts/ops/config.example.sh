#!/usr/bin/env bash
# Copy to config.sh (gitignored) and fill in.

DOMAINS=(example.com staging.example.com)   # for ssl-cert-expiry-check.sh
EXPIRY_WARN_DAYS=30

LOG_PATHS=(/var/log/nginx/*.log)             # for log-rotate-cleanup.sh
LOG_RETENTION_DAYS=30

# --- Notifications (optional) ---
SLACK_WEBHOOK_URL=""
