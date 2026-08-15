#!/usr/bin/env bash
# Build + tag + push a Docker image, tagged by date + git sha (falls back
# to "local" outside a git repo) plus :latest.
#
# Usage: ./docker-image-build-push.sh <image-dir> <registry/name> [tag]
# Example:
#   ./docker-image-build-push.sh ../../docker-images/laravel-ubuntu-alpine \
#       myregistry/laravel-app
set -euo pipefail

IMAGE_DIR="${1:?Usage: $0 <image-dir> <registry/name> [tag]}"
IMAGE_NAME="${2:?Usage: $0 <image-dir> <registry/name> [tag]}"
TAG="${3:-$(date +%Y%m%d)-$(git -C "$IMAGE_DIR" rev-parse --short HEAD 2>/dev/null || echo local)}"

echo "==> Building $IMAGE_NAME:$TAG from $IMAGE_DIR"
docker build -t "$IMAGE_NAME:$TAG" -t "$IMAGE_NAME:latest" "$IMAGE_DIR"

echo "==> Pushing $IMAGE_NAME:$TAG and :latest"
docker push "$IMAGE_NAME:$TAG"
docker push "$IMAGE_NAME:latest"

echo "==> Pushed. Pin deployments to $IMAGE_NAME:$TAG, not :latest."
