<?php

declare(strict_types=1);

namespace SmartMigrations\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Filesystem\Filesystem;
use Illuminate\Support\Str;
use InvalidArgumentException;
use SmartMigrations\Support\ExistingMigrationScanner;
use SmartMigrations\Support\FieldDefinition;
use SmartMigrations\Support\FieldDefinitionParser;
use SmartMigrations\Support\MigrationColumnRenderer;
use SmartMigrations\Support\MigrationNameParser;
use SmartMigrations\Support\MigrationStubBuilder;
use SmartMigrations\Support\ModelColumnInspector;

class MakeSmartMigrationCommand extends Command
{
    protected $signature = 'make:smart-migration
        {name : Migration name, e.g. create_posts_table or add_status_to_posts_table}
        {--table= : Explicit table name (inferred from the migration name if omitted)}
        {--model= : Fully-qualified Eloquent model class to infer columns from}
        {--fields= : Semicolon-separated field definitions, e.g. "title:string;body:text:nullable;author_id"}
        {--soft-deletes : Add a softDeletes() column (create migrations only)}
        {--no-timestamps : Skip timestamps() on "create" migrations}
        {--path= : Migrations directory (defaults to database/migrations)}
        {--force : Generate even if a migration already creates this table}';

    protected $description = 'Generate a migration with columns inferred from a model, explicit --fields, or the migration name';

    public function handle(Filesystem $files): int
    {
        $name = Str::snake(trim((string) $this->argument('name')));
        $path = rtrim($this->resolveMigrationsPath(), '/');

        $parsed = MigrationNameParser::parse($name);
        $action = $parsed['action'];
        $table = $this->option('table') ?: $parsed['table'];

        if ($action === 'unknown') {
            $action = $this->choice(
                'Could not tell "create" from "update" from the migration name. Which is this?',
                ['create', 'update'],
                0
            );
        }

        if (! $table) {
            $table = $this->ask('What table does this migration target?');
        }

        if (! $table) {
            $this->components->error('A table name is required (via the migration name, --table, or the prompt above).');

            return self::FAILURE;
        }

        if ($action === 'create' && ! $this->option('force') && ExistingMigrationScanner::hasCreateMigrationFor($table, $path)) {
            $this->components->error("A migration that already creates `{$table}` exists in {$path}. Pass --force to generate anyway.");

            return self::FAILURE;
        }

        if ($action === 'update' && ! ExistingMigrationScanner::hasAnyMigrationFor($table, $path)) {
            $this->components->warn("No existing migration references `{$table}` yet — make sure it's created before this one runs.");
        }

        $fields = $this->resolveFields();
        $rendered = MigrationColumnRenderer::render($fields);

        foreach ($rendered['notes'] as $note) {
            $this->components->warn($note);
        }

        $stubsPath = dirname(__DIR__, 3) . '/stubs';
        $builder = new MigrationStubBuilder($stubsPath);
        $stubName = $action === 'create' ? 'create.stub' : 'update.stub';

        $replacements = [
            'table' => $table,
            'columns' => $this->buildColumnsBlock($rendered['lines'], $action),
        ];

        if ($action === 'update') {
            $replacements['reverseColumns'] = $this->buildReverseBlock($rendered);
        }

        $contents = $builder->build($stubName, $replacements);
        $filePath = $this->nextAvailablePath($path, $name, $files);

        $files->ensureDirectoryExists($path);
        $files->put($filePath, $contents);

        $this->components->info("Migration created: {$filePath}");

        return self::SUCCESS;
    }

    /**
     * @return array<int, FieldDefinition>
     */
    private function resolveFields(): array
    {
        if ($fields = $this->option('fields')) {
            return FieldDefinitionParser::parse($fields);
        }

        if ($model = $this->option('model')) {
            try {
                return ModelColumnInspector::inspect($model);
            } catch (InvalidArgumentException $e) {
                $this->components->error($e->getMessage());
            }
        }

        return [];
    }

    /**
     * @param  array<int, string>  $lines
     */
    private function buildColumnsBlock(array $lines, string $action): string
    {
        $block = $lines === [] ? '            // TODO: add columns' : implode("\n", $lines);

        if ($action !== 'create') {
            return $block;
        }

        if (! $this->option('no-timestamps')) {
            $block .= "\n            \$table->timestamps();";
        }

        if ($this->option('soft-deletes')) {
            $block .= "\n            \$table->softDeletes();";
        }

        return $block;
    }

    /**
     * @param  array{foreignDropLines: array<int, string>, plainDropNames: array<int, string>}  $rendered
     */
    private function buildReverseBlock(array $rendered): string
    {
        $lines = $rendered['foreignDropLines'];

        if ($rendered['plainDropNames'] !== []) {
            $names = implode("', '", $rendered['plainDropNames']);
            $lines[] = "            \$table->dropColumn(['{$names}']);";
        }

        return $lines === [] ? '            //' : implode("\n", $lines);
    }

    private function nextAvailablePath(string $path, string $name, Filesystem $files): string
    {
        $timestamp = time();
        $candidate = "{$path}/" . date('Y_m_d_His', $timestamp) . "_{$name}.php";

        // Guard against a same-second collision when the command runs twice back to back.
        while ($files->exists($candidate)) {
            $timestamp++;
            $candidate = "{$path}/" . date('Y_m_d_His', $timestamp) . "_{$name}.php";
        }

        return $candidate;
    }

    private function resolveMigrationsPath(): string
    {
        if ($path = $this->option('path')) {
            return $path;
        }

        return function_exists('database_path') ? database_path('migrations') : getcwd() . '/database/migrations';
    }
}
