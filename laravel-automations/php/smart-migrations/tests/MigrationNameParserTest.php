<?php

declare(strict_types=1);

namespace SmartMigrations\Tests;

use PHPUnit\Framework\TestCase;
use SmartMigrations\Support\MigrationNameParser;

final class MigrationNameParserTest extends TestCase
{
    public function test_create_convention(): void
    {
        $result = MigrationNameParser::parse('create_posts_table');

        self::assertSame('create', $result['action']);
        self::assertSame('posts', $result['table']);
    }

    public function test_add_column_convention(): void
    {
        $result = MigrationNameParser::parse('add_status_to_posts_table');

        self::assertSame('update', $result['action']);
        self::assertSame('posts', $result['table']);
    }

    public function test_remove_column_convention(): void
    {
        $result = MigrationNameParser::parse('remove_status_from_posts_table');

        self::assertSame('update', $result['action']);
        self::assertSame('posts', $result['table']);
    }

    public function test_bare_table_suffix_is_treated_as_update(): void
    {
        $result = MigrationNameParser::parse('posts_table');

        self::assertSame('update', $result['action']);
        self::assertSame('posts', $result['table']);
    }

    public function test_unrecognized_name_is_unknown(): void
    {
        $result = MigrationNameParser::parse('tweak_things');

        self::assertSame('unknown', $result['action']);
        self::assertNull($result['table']);
    }
}
