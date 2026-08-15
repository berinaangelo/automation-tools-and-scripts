# laravel-automations

Automations for Laravel projects that are actual code/packages rather than shell wrappers — those live in [`scripts/laravel`](../scripts/laravel) instead. Organized one subdirectory per language, since tooling here won't always be PHP (e.g. a Node-based build helper down the line):

```
laravel-automations/
  php/
    smart-migrations/     # make:smart-migration Artisan command
    smart-form-requests/  # make:smart-form-request Artisan command (depends on smart-migrations)
```

Each tool is self-contained under its language folder with its own `composer.json`/`package.json`/etc. and README — see the tool's own README for install/usage.
