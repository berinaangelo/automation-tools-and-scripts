# Terraform scripts

Thin wrappers around the templates in `terraform-templates/`. No config.sh —
pass the target directory as `$1` (defaults to cwd).

- `tf-plan-apply.sh [dir]` — fmt check, init, validate, plan, confirm-gated
  apply.
- `tf-drift-check.sh [dir]` — plan-only, exits 2 on drift, optional Slack
  alert via `SLACK_WEBHOOK_URL` env var. Good for a nightly cron/CI job.
