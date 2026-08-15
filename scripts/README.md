# scripts

Day-to-day automation scripts, grouped by domain. Each subdirectory that
touches real infra/credentials ships a `config.example.sh` — copy it to
`config.sh` (gitignored) in the same directory and fill in before running
anything. Scripts fail loudly with a clear message if `config.sh` is missing
or a required variable is unset.

## Layout

- `laravel/` — backup, deploy, queue restart, new-project scaffold.
- `wordpress/` — backup, plugin audit, prod→staging sync.
- `docker/` — image prune, build + tag + push.
- `terraform/` — plan/apply wrapper, drift check (wraps `terraform-templates/`).
- `git/` — stale-branch cleanup, secrets scan.
- `ops/` — SSL expiry check, log rotation.

## Convention

```bash
cd scripts/<category>
cp config.example.sh config.sh
# edit config.sh — real values, never committed
./the-script.sh
```

Scripts that don't touch secrets (e.g. `docker-prune.sh`) skip the config
file and just take CLI args or env var overrides at the top of the file —
tweak those directly.

All scripts use `set -euo pipefail`, guard required vars with `${VAR:?...}`,
and fall back to a safe default or a clear warning on optional/fallible
steps (S3 upload, Slack notify, etc.) rather than failing the whole run.
