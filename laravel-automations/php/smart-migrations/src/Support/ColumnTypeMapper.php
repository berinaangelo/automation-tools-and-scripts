<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * Maps an Eloquent $casts value (e.g. "boolean", "decimal:2", "datetime:Y-m-d")
 * to the Blueprint column-type method that should be used to create it.
 */
final class ColumnTypeMapper
{
    /** @var array<string, string> */
    private const MAP = [
        'int' => 'integer',
        'integer' => 'integer',
        'real' => 'double',
        'float' => 'double',
        'double' => 'double',
        'bool' => 'boolean',
        'boolean' => 'boolean',
        'array' => 'json',
        'json' => 'json',
        'collection' => 'json',
        'object' => 'json',
        'date' => 'date',
        'datetime' => 'dateTime',
        'immutable_date' => 'date',
        'immutable_datetime' => 'dateTime',
        'timestamp' => 'timestamp',
        'string' => 'string',
    ];

    public static function fromCast(?string $cast): string
    {
        if ($cast === null || $cast === '') {
            return 'string';
        }

        $base = strtolower((string) strtok($cast, ':'));

        if ($base === 'decimal') {
            return 'decimal';
        }

        if (str_contains($base, 'custom_datetime')) {
            return 'dateTime';
        }

        return self::MAP[$base] ?? 'string';
    }
}
