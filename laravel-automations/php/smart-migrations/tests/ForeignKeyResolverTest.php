<?php

declare(strict_types=1);

namespace SmartMigrations\Tests;

use PHPUnit\Framework\TestCase;
use SmartMigrations\Support\ForeignKeyResolver;

final class ForeignKeyResolverTest extends TestCase
{
    public function test_it_recognizes_id_suffixed_columns(): void
    {
        self::assertTrue(ForeignKeyResolver::looksLikeForeignKey('author_id'));
        self::assertFalse(ForeignKeyResolver::looksLikeForeignKey('id'));
        self::assertFalse(ForeignKeyResolver::looksLikeForeignKey('title'));
    }

    public function test_it_guesses_a_pluralized_table_name(): void
    {
        self::assertSame('authors', ForeignKeyResolver::guessTable('author_id'));
        self::assertSame('categories', ForeignKeyResolver::guessTable('category_id'));
        self::assertSame('addresses', ForeignKeyResolver::guessTable('address_id'));
    }

    public function test_it_returns_null_for_non_foreign_key_columns(): void
    {
        self::assertNull(ForeignKeyResolver::guessTable('id'));
        self::assertNull(ForeignKeyResolver::guessTable('title'));
    }
}
