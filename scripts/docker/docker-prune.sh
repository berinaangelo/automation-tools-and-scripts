#!/usr/bin/env bash
# Safe periodic cleanup: stopped containers, dangling images, unused
# volumes, and old build cache. Does NOT touch running containers or
# tagged images still in use.
set -euo pipefail

# --- tweak me ---
BUILD_CACHE_RETENTION_HOURS="${BUILD_CACHE_RETENTION_HOURS:-168}"  # 7 days
# ----------------

echo "==> Removing stopped containers"
docker container prune -f

echo "==> Removing dangling images"
docker image prune -f

echo "==> Removing unused volumes"
docker volume prune -f

echo "==> Removing build cache older than ${BUILD_CACHE_RETENTION_HOURS}h"
docker builder prune -f --filter "until=${BUILD_CACHE_RETENTION_HOURS}h"

echo "==> Done. Disk usage:"
docker system df
