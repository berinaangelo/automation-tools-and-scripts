<?php

declare(strict_types=1);

namespace SmartFormRequests\Support;

use Illuminate\Support\Facades\Schema;
use InvalidArgumentException;
use SmartMigrations\Support\FieldDefinition;
use Throwable;

/**
 * Builds FieldDefinitions straight from a live DB table's columns, so
 * `--table=posts` gives accurate types + nullability instead of a guess.
 *
 * id/created_at/updated_at/deleted_at are skipped - they're framework-managed,
 * not user input a FormRequest should validate.
 */
final class DatabaseTableInspector
{
    /** @var array<int, string> */
    private const SKIPPED_COLUMNS = ['id', 'created_at', 'updated_at', 'deleted_at'];

    /**
     * @return array<int, FieldDefinition>
     */
    public static function inspect(string $table): array
    {
        if (! Schema::hasTable($table)) {
            throw new InvalidArgumentException("Table [{$table}] does not exist.");
        }

        // Schema::getColumns() (Laravel 11+) reports name/type/nullable in one call
        // and needs no extra package. Older Laravel needs doctrine/dbal for column
        // types and can't report nullability at all, so we fall back to a
        // permissive "nullable" default there rather than guessing wrong.
        if (method_exists(Schema::getFacadeRoot(), 'getColumns')) {
            return self::viaGetColumns($table);
        }

        return self::viaLegacyApi($table);
    }

    /**
     * @return array<int, FieldDefinition>
     */
    private static function viaGetColumns(string $table): array
    {
        $definitions = [];

        foreach (Schema::getColumns($table) as $column) {
            if (in_array($column['name'], self::SKIPPED_COLUMNS, true)) {
                continue;
            }

            $type = RuleTypeMapper::fromDatabaseType($column['type_name'] ?? '');
            $modifiers = ($column['nullable'] ?? true) ? ['nullable'] : [];

            $definitions[] = new FieldDefinition($column['name'], $type, $modifiers);
        }

        return $definitions;
    }

    /**
     * @return array<int, FieldDefinition>
     */
    private static function viaLegacyApi(string $table): array
    {
        $definitions = [];

        foreach (Schema::getColumnListing($table) as $name) {
            if (in_array($name, self::SKIPPED_COLUMNS, true)) {
                continue;
            }

            $definitions[] = new FieldDefinition($name, self::legacyColumnType($table, $name), ['nullable']);
        }

        return $definitions;
    }

    private static function legacyColumnType(string $table, string $column): string
    {
        try {
            return RuleTypeMapper::fromDatabaseType(Schema::getColumnType($table, $column));
        } catch (Throwable) {
            // Requires doctrine/dbal on Laravel <11; fall back to a safe default
            // rather than failing the whole generation over one column.
            return 'string';
        }
    }
}
