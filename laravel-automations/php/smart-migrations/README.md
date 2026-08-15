# laravel-smart-migrations

An Artisan command, `make:smart-migration`, that generates a migration's `up()`/`down()` body for you instead of a bare stub — from an Eloquent model's `$fillable`/`$casts`, an explicit `--fields` list, or nothing at all (name-only, same as `make:migration`).

It builds on top of Laravel's own naming convention, so it slots in next to `make:migration` rather than replacing it.

## What "smart" means here

- **Reads the migration name** the same way Laravel does — `create_posts_table` vs `add_status_to_posts_table` — to decide between a `Schema::create` and a `Schema::table` stub, and to infer the table name.
- **Infers columns from a model** via `--model=App\Models\Post`: reads `$fillable` + `$casts` and maps each cast (`boolean`, `array`, `datetime:Y-m-d`, `decimal:2`, ...) to the matching `Blueprint` column type.
- **Infers columns from `--fields`** when you'd rather be explicit: `title:string;body:text:nullable;price:decimal:precision=8,2`.
- **Guesses foreign keys**: any field named `*_id` (explicitly typed `foreignId` or left as a bare name) becomes `$table->foreignId('author_id')->constrained('authors')->cascadeOnDelete()`, with the guessed table name printed as a warning so you can double check/correct it before running the migration.
- **Writes a real `down()`** for alter migrations — `dropConstrainedForeignId()` for guessed FKs, a single `dropColumn([...])` for the rest — instead of leaving it empty.
- **Guards against duplicates**: refuses to generate a second "create" migration for a table that already has one (`--force` to override), and warns when an "update" migration doesn't have any prior migration for that table.

## Install

```bash
composer require kornbip69/laravel-smart-migrations
```

Auto-discovered via Laravel's package discovery — no manual provider registration needed.

## Usage

```bash
# Same output shape as make:migration, just name + table, no columns.
php artisan make:smart-migration create_posts_table

# Infer columns from a model's $fillable/$casts.
php artisan make:smart-migration create_posts_table --model="App\Models\Post"

# Or be explicit about columns.
php artisan make:smart-migration create_posts_table \
  --fields="title:string;body:text:nullable;published:boolean:default=0;author_id;price:decimal:precision=8,2"

# Alter migrations work the same way and generate a matching down().
php artisan make:smart-migration add_status_to_posts_table --fields="status:string:default=draft;editor_id"
```

### `--fields` syntax

Fields are separated by `;` (not `,` — commas are reserved for multi-value options like a decimal's precision). Each field is `name:type:modifier:key=value...`:

| Example | Result |
|---|---|
| `title:string` | `$table->string('title');` |
| `body:text:nullable` | `$table->text('body')->nullable();` |
| `email:string:unique` | `$table->string('email')->unique();` |
| `status:string:default=draft` | `$table->string('status')->default('draft');` |
| `price:decimal:precision=8,2` | `$table->decimal('price', 8, 2);` |
| `author_id` | `$table->foreignId('author_id')->constrained('authors')->cascadeOnDelete();` (table guessed) |
| `owner_id:foreignId:constrained=users` | `$table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();` (table explicit) |

### Options

| Option | Purpose |
|---|---|
| `--table=` | Explicit table name (otherwise inferred from the migration name) |
| `--model=` | Fully-qualified Eloquent model to infer columns from |
| `--fields=` | Explicit field list (wins over `--model` if both are passed) |
| `--soft-deletes` | Add `softDeletes()` (create migrations only) |
| `--no-timestamps` | Skip the automatic `timestamps()` on create migrations |
| `--path=` | Migrations directory, defaults to `database/migrations` |
| `--force` | Generate even if a migration already creates this table |

## Design notes / limitations

- Columns inferred from `--model` are always generated `nullable()` — the inspector only knows the model's shape, not your DB constraints, so it defaults to the safer option. Review and tighten the generated file before running it.
- Foreign-key table guesses are a naive pluralization of the column name minus `_id` (`author_id` → `authors`). The CLI prints a warning for every guess; always confirm before migrating.
- The duplicate-table guard does a plain string scan of existing migration files (looking for `Schema::create('table'`), not a real schema read — it won't catch a table created via raw SQL or a differently-named table.

## Development

```bash
composer install
vendor/bin/phpunit
```
