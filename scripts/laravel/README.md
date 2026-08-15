# Laravel scripts

Day-to-day ops for a Laravel project.

```bash
cp config.example.sh config.sh
# edit config.sh
```

- `laravel-new-project.sh <name> [dir]` — scaffold a new app wired to the
  `docker-images/laravel-ubuntu-alpine` template. No config.sh needed.
- `laravel-db-backup.sh` — dump + gzip + rotate the DB, optional S3 upload.
- `laravel-deploy.sh` — pull, composer install, migrate, cache, restart queue.
- `laravel-queue-restart.sh` — restart queue workers only.

Wire `laravel-db-backup.sh` and `laravel-deploy.sh` into cron/CI as needed —
they're idempotent and safe to re-run.
