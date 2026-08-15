<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;

/**
 * Builds FieldDefinitions from an Eloquent model's $fillable + $casts, so
 * `--model=App\Models\Post` can drive column generation without a --fields option.
 */
final class ModelColumnInspector
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
            // We only know the model's shape, not DB constraints, so every inferred
            // column defaults to nullable() to avoid generating a migration that fails
            // on existing rows. Tighten it by hand once you review the generated file.
            $definitions[] = new FieldDefinition(
                name: $attribute,
                type: ColumnTypeMapper::fromCast($casts[$attribute] ?? null),
                modifiers: ['nullable'],
            );
        }

        return $definitions;
    }
}
