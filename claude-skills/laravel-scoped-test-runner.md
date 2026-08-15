---
name: scoped-test-runner
description: Runs only the Pest tests relevant to the files that were actually changed, instead of the whole suite, then decides whether the change is risky enough to widen the run. Use after editing files under app/, database/migrations/, or tests/ in this project, or when asked to "run the tests", "run just the affected tests", or "check if this broke anything" without an explicit request for the full suite.
---

# Scoped Test Runner

This project has no git history to diff against, so "what changed" means the files you (or the
user) just edited in this session — not `git diff`. Ask if it's unclear which files are in scope.

## 1. Map changed files to test files

Use Laravel's naming convention to find each changed file's test counterpart:

- `app/Http/Controllers/XController.php` → `tests/Feature/XControllerTest.php`
- `app/Models/X.php` → `tests/Unit/XTest.php` (or `tests/Feature/XTest.php` if it exists instead)
- `app/Services/X.php` → `tests/Unit/XTest.php`
- `app/Http/Requests/XRequest.php` → covered indirectly via the controller's Feature test
- `database/migrations/*_create_x_table.php` → whatever Feature/Unit tests touch the `X` model

If no test file exists at the conventional path, `grep` the class name across `tests/` — it may be
exercised indirectly from another test.

## 2. Run only those tests

```
php artisan test path/to/OneTest.php path/to/AnotherTest.php
```

Don't run the whole suite (`php artisan test` with no args / `composer test`) unless step 3 says to
widen.

## 3. Decide whether to widen

Widen to the full suite instead of trusting the scoped result when:

- The changed file has **no** test file and `grep` found no indirect coverage — say so explicitly,
  don't silently treat it as passing.
- The changed file is shared/core: a base Model, a trait, a Service used by multiple features, a
  migration altering an existing table, or anything in `config/`.
- The scoped run fails — after fixing, re-run scoped first, but widen before declaring done if the
  fix touched shared code.

Otherwise, the scoped run is sufficient — don't pad it out "just in case."

## 4. Report

State which test files ran and why they were the right scope, the pass/fail result, and whether you
widened (and why). If a changed file has zero test coverage, flag that as a gap — don't paper over
it by claiming the scoped run proves correctness.

## Frontend note

This project has no JS test runner configured yet (no Vitest/Jest in `package.json`). If one gets
added later, apply the same scoping logic to `resources/js/` — map changed components/composables to
their spec files before running.
