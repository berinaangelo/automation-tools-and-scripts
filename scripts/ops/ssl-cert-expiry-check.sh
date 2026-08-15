#!/usr/bin/env bash
# Check TLS cert expiry for configured domains, warn if within N days.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.sh" ]; then
  # shellcheck source=config.sh
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found. Copy config.example.sh -> config.sh and fill in." >&2
  exit 1
fi

WARN_DAYS="${EXPIRY_WARN_DAYS:-30}"
ALERTS=()

for DOMAIN in "${DOMAINS[@]}"; do
  EXPIRY_DATE="$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)"

  if [ -z "$EXPIRY_DATE" ]; then
    echo "!! $DOMAIN: could not fetch certificate" >&2
    continue
  fi

  EXPIRY_TS="$(date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null \
    || date -d "$EXPIRY_DATE" +%s)"
  NOW_TS="$(date +%s)"
  DAYS_LEFT=$(( (EXPIRY_TS - NOW_TS) / 86400 ))

  if [ "$DAYS_LEFT" -le "$WARN_DAYS" ]; then
    echo "!! $DOMAIN expires in $DAYS_LEFT days ($EXPIRY_DATE)"
    ALERTS+=("$DOMAIN expires in $DAYS_LEFT days")
  else
    echo "OK $DOMAIN expires in $DAYS_LEFT days"
  fi
done

if [ "${#ALERTS[@]}" -gt 0 ] && [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  MSG="⚠️ Cert expiry: $(printf '%s; ' "${ALERTS[@]}")"
  curl -fsS -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$MSG\"}" "$SLACK_WEBHOOK_URL" >/dev/null \
    || echo "Warning: Slack notification failed" >&2
fi
