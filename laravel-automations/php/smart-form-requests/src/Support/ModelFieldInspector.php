<?php

declare(strict_types=1);

namespace SmartFormRequests\Support;

use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;
use SmartMigrations\Support\FieldDefinition;

/**
 * Builds FieldDefinitions from an Eloquent model's $fillable + $casts, so
 * `--model=App\Models\Post` can drive rule generation without --fields/--table.
 */
final class ModelFieldInspector
{
    /**
     * @return array<int, FieldDefinition>
     */
    public static function inspect(string $modelClass): array
    {
        if (! class_exists($modelClass)) {
            throw new InvalidArgumentException("Model class [{$modelClass}] does not exist.");
        }

        if (! is_subclass_of($modelClass, Model::class)) {
            throw new InvalidArgumentException("Class [{$modelClass}] is not an Eloquent model.");
        }

        /** @var Model $model */
        $model = new $modelClass();

        $casts = $model->getCasts();
        $attributes = $model->getFillable() !== [] ? $model->getFillable() : array_keys($casts);

        $definitions = [];

        foreach ($attributes as $attribute) {
            // A model alone doesn't tell us whether a column is actually required in
            // the DB, so every inferred field defaults to "sometimes" (validated only
            // when present) rather than guessing "required" and risking false failures.
            $definitions[] = new FieldDefinition(
                name: $attribute,
                type: self::castToType($casts[$attribute] ?? null),
                modifiers: ['sometimes'],
            );
        }

        return $definitions;
    }

    private static function castToType(?string $cast): string
    {
        if ($cast === null || $cast === '') {
            return 'string';
        }

        $base = strtolower((string) strtok($cast, ':'));

        return match (true) {
            in_array($base, ['int', 'integer'], true) => 'integer',
            in_array($base, ['bool', 'boolean'], true) => 'boolean',
            in_array($base, ['real', 'float', 'double', 'decimal'], true) => 'decimal',
            in_array($base, ['array', 'json', 'collection', 'object'], true) => 'json',
            in_array($base, ['date', 'immutable_date'], true) => 'date',
            in_array($base, ['datetime', 'immutable_datetime', 'timestamp'], true) => 'datetime',
            str_contains($base, 'custom_datetime') => 'datetime',
            default => 'string',
        };
    }
}
