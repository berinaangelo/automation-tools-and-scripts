# Docker scripts

No config.sh needed — tweak the marked variables at the top of each file or
pass CLI args.

- `docker-prune.sh` — periodic cleanup of stopped containers, dangling
  images, unused volumes, stale build cache. Safe for cron.
- `docker-image-build-push.sh <image-dir> <registry/name> [tag]` — build,
  tag (date+sha), push. Defaults `image-dir` to none — always pass it
  explicitly, e.g. `docker-images/laravel-ubuntu-alpine`.
