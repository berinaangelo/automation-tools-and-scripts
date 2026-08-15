<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * Reads Laravel's own migration-naming convention to infer intent + table,
 * the same way `artisan make:migration` does, e.g.:
 *   create_posts_table            -> create / posts
 *   add_status_to_posts_table     -> update / posts
 *   remove_status_from_posts_table -> update / posts
 *   posts_table                   -> update / posts (ambiguous, treated as an alter)
 */
final class MigrationNameParser
{
    /**
     * @return array{action: 'create'|'update'|'unknown', table: ?string}
     */
    public static function parse(string $name): array
    {
        $name = strtolower($name);

        if (preg_match('/^create_(.+)_table$/', $name, $m) === 1) {
            return ['action' => 'create', 'table' => $m[1]];
        }

        if (preg_match('/^(?:add|remove|drop|update|modify|rename)_.*_(?:to|from|in|on)_(.+)_table$/', $name, $m) === 1) {
            return ['action' => 'update', 'table' => $m[1]];
        }

        if (preg_match('/^(.+)_table$/', $name, $m) === 1) {
            return ['action' => 'update', 'table' => $m[1]];
        }

        return ['action' => 'unknown', 'table' => null];
    }
}
