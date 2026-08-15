<?php

declare(strict_types=1);

namespace SmartMigrations\Tests;

use PHPUnit\Framework\TestCase;
use SmartMigrations\Support\FieldDefinitionParser;

final class FieldDefinitionParserTest extends TestCase
{
    public function test_it_parses_a_bare_name_as_a_nullable_less_string(): void
    {
        [$field] = FieldDefinitionParser::parse('title');

        self::assertSame('title', $field->name);
        self::assertSame('string', $field->type);
        self::assertSame([], $field->modifiers);
    }

    public function test_it_parses_type_and_modifiers(): void
    {
        [$field] = FieldDefinitionParser::parse('body:text:nullable');

        self::assertSame('text', $field->type);
        self::assertTrue($field->has('nullable'));
    }

    public function test_it_parses_keyed_options(): void
    {
        [$field] = FieldDefinitionParser::parse('price:decimal:precision=8,2');

        self::assertSame('decimal', $field->type);
        self::assertSame('8,2', $field->option('precision'));
        self::assertSame(', 8, 2', $field->typeArgs());
    }

    public function test_it_parses_multiple_semicolon_separated_fields(): void
    {
        $fields = FieldDefinitionParser::parse('title:string;body:text:nullable;author_id');

        self::assertCount(3, $fields);
        self::assertSame('title', $fields[0]->name);
        self::assertSame('body', $fields[1]->name);
        self::assertSame('author_id', $fields[2]->name);
    }

    public function test_it_ignores_blank_entries(): void
    {
        $fields = FieldDefinitionParser::parse('title:string; ; body:text');

        self::assertCount(2, $fields);
    }
}
