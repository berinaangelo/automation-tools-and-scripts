---
name: security-db-audit
description: Audits this Laravel project's database layer for security issues — mass assignment, exposed PII/PHI, missing model hiding/casts, injection-prone raw queries, missing authorization scoping, and credential handling in migrations/seeders/config. Use before shipping a schema change, model, or query touching patient/appointment data, or when asked to "audit the database", "check for SQL injection", or "review this migration/model for security".
---

# Security DB Audit

This is a medical reservation system — patient names, contact info, DOB, appointment details, and
any clinical notes are sensitive by default. Treat them as PII/PHI even if the code doesn't say so
explicitly.

## Checklist

1. **Mass assignment** — flag any Model using `protected $guarded = [];` (allows every field to be
   mass-assigned). Prefer `$fillable` as an explicit allowlist, especially on models touching
   patient/appointment data.
2. **Sensitive field exposure** — check each Model's `$hidden`/`$visible` covers `password`,
   `remember_token`, and any PII/PHI fields not meant for API output. Check API Resources
   (`app/Http/Resources`) explicitly allowlist fields rather than `return new Resource($model)`
   wrapping a model whose attributes were never scoped down.
3. **Encryption at rest** — sensitive columns (SSN/national ID, insurance info, clinical notes)
   should use Laravel's `encrypted` (or `encrypted:array`) cast rather than a plain `string` column.
4. **Injection risk** — `grep` for `DB::raw(`, `whereRaw(`, `selectRaw(`, and string-concatenated
   queries. Flag any that interpolate unbound user input instead of using parameter bindings or
   Eloquent's query builder.
5. **Authorization scoping (IDOR)** — every controller/query returning patient or appointment data
   must be scoped to the authenticated user/role — via a Policy, route middleware, or an explicit
   `where('user_id', $request->user()->id)`. Flag any lookup-by-ID-alone with no ownership check.
6. **Migrations** — foreign keys should declare explicit delete behavior
   (`->constrained()->cascadeOnDelete()` or similar), not silently orphan related records. Watch for
   nullable PII columns that should be required, and required columns that should be nullable.
7. **Seeders/factories** — no realistic-looking PII or hardcoded credentials/API keys; Faker-
   generated data only.
8. **Credential handling** — DB credentials only via `env()`/`config('database...')`, never
   hardcoded. Confirm `.env` stays out of version control and `.env.example` contains no real
   secrets.
9. **Bulk exposure** — endpoints returning lists of patient/appointment data should paginate and
   respect the same authorization scoping as single-record endpoints; unscoped or unpaginated list
   endpoints enable bulk scraping.

## Process

1. Identify the migrations, Models, Controllers, and Resources in scope — recently edited files in
   this session, or ask which ones if invoked standalone.
2. Walk the checklist against each file. Skip categories that plainly don't apply (e.g. no raw SQL
   to check) rather than forcing a finding.
3. Report findings as **Critical** / **Warning** / **Note**, each with `file:line` and a concrete
   exploit scenario — e.g. "`Patient` model uses `$guarded = []`; a POST to `/api/patients` could
   set `is_admin` or override `user_id`, reassigning the record to another account."
4. Don't flag theoretical issues with no realistic trigger path in this app — stay concrete, and say
   what's fine, not just what's wrong.
