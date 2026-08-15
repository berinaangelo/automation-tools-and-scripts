#!/usr/bin/env bash
# Periodic drift check: plan without applying, exit non-zero (and optionally
# alert Slack) if the plan shows changes. Good as a cron/CI job.
# Usage: SLACK_WEBHOOK_URL=... ./tf-drift-check.sh [terraform-dir]
set -euo pipefail

TF_DIR="${1:-.}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
cd "$TF_DIR"

terraform init -input=false >/dev/null

set +e
terraform plan -input=false -detailed-exitcode -out=/dev/null
EXIT_CODE=$?
set -e

case "$EXIT_CODE" in
  0)
    echo "==> No drift detected."
    ;;
  2)
    echo "==> Drift detected in $TF_DIR" >&2
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
      curl -fsS -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"⚠️ Terraform drift detected in $(basename "$(pwd)")\"}" \
        "$SLACK_WEBHOOK_URL" >/dev/null || echo "Warning: Slack notification failed" >&2
    fi
    exit 2
    ;;
  *)
    echo "==> terraform plan failed (exit $EXIT_CODE)" >&2
    exit "$EXIT_CODE"
    ;;
esac
