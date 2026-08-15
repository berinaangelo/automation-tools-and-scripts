<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * Guards against generating a duplicate "create" migration for a table that
 * already has one, and warns when an "update" migration has no create to build on.
 */
final class ExistingMigrationScanner
{
    public static function hasCreateMigrationFor(string $table, string $path): bool
    {
        return self::anyFileContains($path, "Schema::create('{$table}'");
    }

    public static function hasAnyMigrationFor(string $table, string $path): bool
    {
        return self::anyFileContains($path, "'{$table}'");
    }

    private static function anyFileContains(string $path, string $needle): bool
    {
        if (! is_dir($path)) {
            return false;
        }

        foreach (glob(rtrim($path, '/') . '/*.php') ?: [] as $file) {
            $contents = file_get_contents($file);
            if ($contents !== false && str_contains($contents, $needle)) {
                return true;
            }
        }

        return false;
    }
}
