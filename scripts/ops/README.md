# Ops scripts

```bash
cp config.example.sh config.sh
# edit config.sh
```

- `ssl-cert-expiry-check.sh` — checks `DOMAINS` for cert expiry within
  `EXPIRY_WARN_DAYS`, optional Slack alert. Good as a daily cron job.
- `log-rotate-cleanup.sh` — truncates log files matching `LOG_PATHS` older
  than `LOG_RETENTION_DAYS`.
