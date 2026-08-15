<?php

declare(strict_types=1);

namespace SmartMigrations\Tests;

use PHPUnit\Framework\TestCase;
use SmartMigrations\Support\FieldDefinitionParser;
use SmartMigrations\Support\MigrationColumnRenderer;

final class MigrationColumnRendererTest extends TestCase
{
    public function test_it_renders_plain_columns(): void
    {
        $fields = FieldDefinitionParser::parse('title:string;body:text:nullable');
        $rendered = MigrationColumnRenderer::render($fields);

        self::assertSame(
            "            \$table->string('title');",
            $rendered['lines'][0]
        );
        self::assertSame(
            "            \$table->text('body')->nullable();",
            $rendered['lines'][1]
        );
        self::assertSame(['title', 'body'], $rendered['plainDropNames']);
        self::assertSame([], $rendered['foreignDropLines']);
        self::assertSame([], $rendered['notes']);
    }

    public function test_it_auto_detects_a_foreign_key_from_a_bare_id_column(): void
    {
        $fields = FieldDefinitionParser::parse('author_id');
        $rendered = MigrationColumnRenderer::render($fields);

        self::assertSame(
            "            \$table->foreignId('author_id')->constrained('authors')->cascadeOnDelete();",
            $rendered['lines'][0]
        );
        self::assertSame(
            "            \$table->dropConstrainedForeignId('author_id');",
            $rendered['foreignDropLines'][0]
        );
        self::assertCount(1, $rendered['notes']);
        self::assertStringContainsString('authors', $rendered['notes'][0]);
    }

    public function test_an_explicit_constrained_table_suppresses_the_guess_note(): void
    {
        $fields = FieldDefinitionParser::parse('owner_id:foreignId:constrained=users');
        $rendered = MigrationColumnRenderer::render($fields);

        self::assertSame(
            "            \$table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();",
            $rendered['lines'][0]
        );
        self::assertSame([], $rendered['notes']);
    }

    public function test_it_renders_a_default_value(): void
    {
        $fields = FieldDefinitionParser::parse('status:string:default=draft');
        $rendered = MigrationColumnRenderer::render($fields);

        self::assertSame(
            "            \$table->string('status')->default('draft');",
            $rendered['lines'][0]
        );
    }
}
