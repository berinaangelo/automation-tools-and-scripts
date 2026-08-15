# Git scripts

No config.sh — CLI flags / edit the marked pattern list directly.

- `stale-branch-cleanup.sh [--delete] [--days N] [--base main]` — dry-run
  lists merged+stale branches by default; `--delete` actually removes them
  locally and on `origin`.
- `secrets-scan.sh [--staged]` — greps tracked (or staged) files against a
  pattern list (AWS keys, private keys, GitHub/Slack tokens, inline
  password/api_key assignments). Wire into a pre-commit hook with `--staged`.
