# laravel-smart-form-requests

An Artisan command, `make:smart-form-request`, that generates a Store/Update `FormRequest` pair with a real `rules()` body — from an Eloquent model, a live DB table, or an explicit field list — instead of an empty stub.

Built on top of [`laravel-smart-migrations`](../smart-migrations), which supplies the shared field-DSL parser and foreign-key guesser so both tools speak the same `--fields` syntax.

## What "smart" means here

- **Three rule sources**, in priority order: explicit `--fields`, a live `--table` (accurate types + nullability straight from the DB schema), or `--model` (best-effort from `$fillable`/`$casts` — always generated `sometimes`, since a model alone can't tell you what's actually required).
- **Store + Update pair by default**: `StoreXRequest` gets `required`/`nullable`; `UpdateXRequest` auto-relaxes to `sometimes` (+ `required` if the field isn't nullable, so an explicitly-sent empty value still fails) — pass `--single --type=update` for just one.
- **Guesses foreign keys**: a `*_id` field (bare, or typed `foreignId`) gets `exists:{table},id`, with the guessed table printed as a warning to verify — same heuristic as `smart-migrations`.
- **Unique-with-ignore on update**: a `:unique` field becomes a plain `'unique:table,column'` string on Store, and a `Rule::unique('table', 'column')->ignore($this->route($param))` object on Update, so editing a record doesn't fail against its own row.

## Install

```bash
composer require kornbip69/laravel-smart-form-requests
```

Auto-discovered via Laravel's package discovery.

## Usage

```bash
# Infer from a live table: accurate types + nullability, table used in exists/unique rules.
php artisan make:smart-form-request Post --table=posts

# Infer from a model's $fillable/$casts (fields default to "sometimes" — review before shipping).
php artisan make:smart-form-request Post --model="App\Models\Post"

# Be fully explicit — same DSL as make:smart-migration.
php artisan make:smart-form-request Post \
  --fields="title:string;body:text:nullable;published:boolean;author_id;email:string:unique;price:decimal:min=0"

# Only one request instead of the Store+Update pair.
php artisan make:smart-form-request Post --fields="status:string:in=draft,published" --single --type=update
```

### `--fields` syntax

Same DSL as `smart-migrations`: fields separated by `;`, each one `name:type:modifier:key=value...`.

| Example | Store rule |
|---|---|
| `title:string` | `['required', 'string']` |
| `body:text:nullable` | `['nullable', 'string']` |
| `email:string:unique` | `['required', 'string', 'unique:posts,email']` |
| `age:integer:min=18:max=99` | `['required', 'integer', 'min:18', 'max:99']` |
| `role:string:in=admin,editor` | `['required', 'string', 'in:admin,editor']` |
| `password:string:confirmed` | `['required', 'string', 'confirmed']` |
| `author_id` | `['required', 'integer', 'exists:authors,id']` (table guessed) |
| `owner_id:foreignId:exists=users` | `['required', 'integer', 'exists:users,id']` (table explicit) |
| `title:string:required` (on an Update request) | stays `['required', 'string']` instead of being relaxed to `sometimes` |

Supported type tokens: `string`, `text`, `integer`, `boolean`, `decimal`, `date`, `datetime`, `email`, `url`, `json`, `foreignId`.

### Options

| Option | Purpose |
|---|---|
| `--model=` | Eloquent model to infer fields from |
| `--table=` | DB table to introspect; also the table used in `exists`/`unique` rules |
| `--fields=` | Explicit field list (wins over `--table`/`--model` if more than one is passed) |
| `--single` | Generate one request instead of the Store+Update pair |
| `--type=` | `store` or `update`, required with `--single` |
| `--route-param=` | Route param used in `->ignore()` on Update's unique rules (defaults to the singularized table) |
| `--path=` | Requests directory, defaults to `app/Http/Requests` |
| `--force` | Overwrite existing files |

## Design notes / limitations

- `--model`-inferred fields are always `sometimes` — the model's shape doesn't tell you what's actually required at the DB level. Prefer `--table` when a migration already exists.
- `--table` introspection needs Laravel 11+'s `Schema::getColumns()` for nullability; on Laravel 10 it falls back to `Schema::getColumnListing()`/`getColumnType()` (needs `doctrine/dbal`) and can't determine nullability, so those fields default to `nullable`.
- Foreign-key table guesses are a naive pluralization of the column name minus `_id`. Always check the printed warning before shipping.
- `id`, `created_at`, `updated_at`, and `deleted_at` are skipped automatically when inferring from a model or table — they're framework-managed, not user input.

## Development

```bash
composer install
vendor/bin/phpunit
```
