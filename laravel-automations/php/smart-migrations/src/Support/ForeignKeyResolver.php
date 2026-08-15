<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * Guesses the referenced table for a "*_id" column, e.g. "author_id" -> "authors".
 */
final class ForeignKeyResolver
{
    public static function looksLikeForeignKey(string $columnName): bool
    {
        return $columnName !== 'id' && str_ends_with($columnName, '_id');
    }

    /**
     * Returns null when the column doesn't look like a foreign key.
     */
    public static function guessTable(string $columnName): ?string
    {
        if (! self::looksLikeForeignKey($columnName)) {
            return null;
        }

        return self::pluralize(substr($columnName, 0, -3));
    }

    private static function pluralize(string $word): string
    {
        if (class_exists(\Illuminate\Support\Str::class)) {
            return \Illuminate\Support\Str::plural($word);
        }

        // Minimal fallback so this class stays usable/testable without illuminate/support installed.
        if (preg_match('/(s|x|z|ch|sh)$/', $word) === 1) {
            return $word . 'es';
        }

        if (preg_match('/[^aeiou]y$/', $word) === 1) {
            return substr($word, 0, -1) . 'ies';
        }

        return $word . 's';
    }
}
