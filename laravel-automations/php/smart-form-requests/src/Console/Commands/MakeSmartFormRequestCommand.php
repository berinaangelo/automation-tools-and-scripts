<?php

declare(strict_types=1);

namespace SmartFormRequests\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Filesystem\Filesystem;
use Illuminate\Support\Str;
use InvalidArgumentException;
use SmartFormRequests\Support\DatabaseTableInspector;
use SmartFormRequests\Support\ModelFieldInspector;
use SmartFormRequests\Support\RequestRuleRenderer;
use SmartFormRequests\Support\RequestStubBuilder;
use SmartMigrations\Support\FieldDefinition;
use SmartMigrations\Support\FieldDefinitionParser;

class MakeSmartFormRequestCommand extends Command
{
    protected $signature = 'make:smart-form-request
        {name : Base name, e.g. Post -> generates StorePostRequest + UpdatePostRequest}
        {--model= : Fully-qualified Eloquent model to infer fields from}
        {--table= : DB table to introspect for accurate types/nullability, and to target in unique/exists rules}
        {--fields= : Explicit field definitions, same DSL as make:smart-migration (semicolon-separated)}
        {--single : Generate a single request instead of the Store+Update pair}
        {--type=store : Action for --single (store|update)}
        {--route-param= : Route parameter used in ->ignore() for unique rules on update (defaults to the singularized table)}
        {--path= : Requests directory (defaults to app/Http/Requests)}
        {--force : Overwrite existing files}';

    protected $description = 'Generate a FormRequest (or a Store/Update pair) with rules inferred from a model, a DB table, or an explicit field list';

    public function handle(Filesystem $files): int
    {
        $baseName = $this->resolveBaseName();
        $table = $this->resolveTable($baseName);
        $routeParam = $this->option('route-param') ?: Str::singular($table);
        $path = rtrim($this->option('path') ?: $this->defaultRequestsPath(), '/');

        $fields = $this->resolveFields();
        if ($fields === null) {
            return self::FAILURE;
        }

        $actions = $this->option('single') ? [$this->resolveSingleAction()] : ['store', 'update'];
        if ($actions === [null]) {
            return self::FAILURE;
        }

        $allNotes = [];

        foreach ($actions as $action) {
            $result = $this->generate($action, $baseName, $fields, $table, $routeParam, $path, $files);
            if ($result === null) {
                return self::FAILURE;
            }
            $allNotes = [...$allNotes, ...$result];
        }

        foreach (array_unique($allNotes) as $note) {
            $this->components->warn($note);
        }

        return self::SUCCESS;
    }

    private function resolveBaseName(): string
    {
        $name = trim((string) $this->argument('name'));

        return Str::studly(preg_replace('/Request$/i', '', $name) ?: $name);
    }

    private function resolveTable(string $baseName): string
    {
        return $this->option('table') ?: Str::snake(Str::pluralStudly($baseName));
    }

    /**
     * @return array<int, FieldDefinition>|null Null means a fatal error was already reported.
     */
    private function resolveFields(): ?array
    {
        if ($fields = $this->option('fields')) {
            return FieldDefinitionParser::parse($fields);
        }

        if ($table = $this->option('table')) {
            try {
                return DatabaseTableInspector::inspect($table);
            } catch (InvalidArgumentException $e) {
                $this->components->error($e->getMessage());

                return null;
            }
        }

        if ($model = $this->option('model')) {
            try {
                return ModelFieldInspector::inspect($model);
            } catch (InvalidArgumentException $e) {
                $this->components->error($e->getMessage());

                return null;
            }
        }

        $this->components->warn('No --fields, --table, or --model given; generating an empty rules() array to fill in by hand.');

        return [];
    }

    /**
     * @return array<int, string>|array{0: null}
     */
    private function resolveSingleAction(): array
    {
        $type = strtolower((string) $this->option('type'));

        if (! in_array($type, ['store', 'update'], true)) {
            $this->components->error('--type must be "store" or "update".');

            return [null];
        }

        return [$type];
    }

    /**
     * @param  array<int, FieldDefinition>  $fields
     * @return array<int, string>|null Notes on success, null on fatal error.
     */
    private function generate(string $action, string $baseName, array $fields, string $table, string $routeParam, string $path, Filesystem $files): ?array
    {
        $className = Str::studly($action) . $baseName . 'Request';
        $filePath = "{$path}/{$className}.php";

        if ($files->exists($filePath) && ! $this->option('force')) {
            $this->components->error("{$filePath} already exists. Pass --force to overwrite it.");

            return null;
        }

        $rendered = RequestRuleRenderer::render($fields, $action, $table, $routeParam);

        $imports = ['use Illuminate\\Foundation\\Http\\FormRequest;'];
        if ($rendered['usesRuleClass']) {
            $imports[] = 'use Illuminate\\Validation\\Rule;';
        }

        $rulesBlock = $rendered['lines'] === [] ? '            //' : implode("\n", $rendered['lines']);

        $builder = new RequestStubBuilder(dirname(__DIR__, 3) . '/stubs');
        $contents = $builder->build('request.stub', [
            'class' => $className,
            'imports' => implode("\n", $imports),
            'rules' => $rulesBlock,
        ]);

        $files->ensureDirectoryExists($path);
        $files->put($filePath, $contents);

        $this->components->info("Request created: {$filePath}");

        return $rendered['notes'];
    }

    private function defaultRequestsPath(): string
    {
        return function_exists('app_path') ? app_path('Http/Requests') : getcwd() . '/app/Http/Requests';
    }
}
