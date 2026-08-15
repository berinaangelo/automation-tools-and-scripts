#!/usr/bin/env bash
# List (default) or delete local + remote branches merged into the base
# branch and untouched for N+ days.
# Usage: ./stale-branch-cleanup.sh [--delete] [--days N] [--base main]
set -euo pipefail

DELETE=false
DAYS=30
BASE_BRANCH="main"

while [ $# -gt 0 ]; do
  case "$1" in
    --delete) DELETE=true ;;
    --days) DAYS="$2"; shift ;;
    --base) BASE_BRANCH="$2"; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

git fetch --prune

echo "==> Branches merged into $BASE_BRANCH, untouched for ${DAYS}+ days:"
CUTOFF="$(date -v-"${DAYS}"d +%s 2>/dev/null || date -d "-${DAYS} days" +%s)"

git for-each-ref --format='%(refname:short) %(committerdate:unix)' refs/heads/ \
  | while read -r BRANCH COMMIT_TS; do
      [ "$BRANCH" = "$BASE_BRANCH" ] && continue
      git merge-base --is-ancestor "$BRANCH" "$BASE_BRANCH" 2>/dev/null || continue
      [ "$COMMIT_TS" -lt "$CUTOFF" ] || continue
      echo "  $BRANCH"
      if [ "$DELETE" = true ]; then
        git branch -d "$BRANCH"
        git push origin --delete "$BRANCH" 2>/dev/null || true
      fi
    done

[ "$DELETE" = true ] || echo "==> Dry run only. Re-run with --delete to remove these branches."
