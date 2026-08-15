#!/usr/bin/env bash
# Scaffold a new Laravel project wired to the laravel-ubuntu-alpine Docker
# template from this repo.
#
# Usage: ./laravel-new-project.sh <project-name> [target-dir]
set -euo pipefail

PROJECT_NAME="${1:?Usage: $0 <project-name> [target-dir]}"
TARGET_DIR="${2:-./$PROJECT_NAME}"
DOCKER_TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../docker-images/laravel-ubuntu-alpine" && pwd)"

if [ -e "$TARGET_DIR" ]; then
  echo "Error: $TARGET_DIR already exists." >&2
  exit 1
fi

echo "==> Creating Laravel project '$PROJECT_NAME' in $TARGET_DIR"
composer create-project laravel/laravel "$TARGET_DIR"

echo "==> Copying Docker setup from laravel-ubuntu-alpine template"
cp -r "$DOCKER_TEMPLATE_DIR/docker" "$TARGET_DIR/docker"
cp "$DOCKER_TEMPLATE_DIR/Dockerfile" "$TARGET_DIR/Dockerfile"
cp "$DOCKER_TEMPLATE_DIR/docker-compose.yml" "$TARGET_DIR/docker-compose.yml"

cat >> "$TARGET_DIR/.gitignore" <<'EOF'

# Local overrides
docker-compose.override.yml
EOF

echo "==> Done. Next steps:"
echo "    cd $TARGET_DIR"
echo "    cp .env.example .env"
echo "    docker compose up -d --build"
echo "    docker compose exec app php artisan key:generate"
