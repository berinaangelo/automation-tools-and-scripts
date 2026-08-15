# WordPress scripts

Day-to-day ops for a WordPress site, wrapping WP-CLI.

```bash
cp config.example.sh config.sh
# edit config.sh
```

- `wp-backup.sh` — DB export + `wp-content` tarball, rotated, optional S3.
- `wp-plugin-audit.sh` — outdated/inactive plugins + core update check.
- `wp-staging-sync.sh` — prod → staging DB + uploads sync with URL
  search-replace. **Destructive to staging**, confirms before running.

Requires [WP-CLI](https://wp-cli.org/) on PATH.
