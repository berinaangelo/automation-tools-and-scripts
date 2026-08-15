<?php

declare(strict_types=1);

namespace SmartFormRequests\Tests;

use PHPUnit\Framework\TestCase;
use SmartFormRequests\Support\RequestRuleRenderer;
use SmartMigrations\Support\FieldDefinitionParser;

final class RequestRuleRendererTest extends TestCase
{
    public function test_store_defaults_a_plain_field_to_required(): void
    {
        $fields = FieldDefinitionParser::parse('title:string');
        $rendered = RequestRuleRenderer::render($fields, 'store', 'posts', 'post');

        self::assertSame("            'title' => ['required', 'string'],", $rendered['lines'][0]);
    }

    public function test_store_uses_nullable_when_the_field_is_marked_nullable(): void
    {
        $fields = FieldDefinitionParser::parse('body:text:nullable');
        $rendered = RequestRuleRenderer::render($fields, 'store', 'posts', 'post');

        self::assertSame("            'body' => ['nullable', 'string'],", $rendered['lines'][0]);
    }

    public function test_update_relaxes_a_required_field_to_sometimes_required(): void
    {
        $fields = FieldDefinitionParser::parse('title:string');
        $rendered = RequestRuleRenderer::render($fields, 'update', 'posts', 'post');

        self::assertSame("            'title' => ['sometimes', 'required', 'string'],", $rendered['lines'][0]);
    }

    public function test_update_relaxes_a_nullable_field_to_sometimes_nullable(): void
    {
        $fields = FieldDefinitionParser::parse('body:text:nullable');
        $rendered = RequestRuleRenderer::render($fields, 'update', 'posts', 'post');

        self::assertSame("            'body' => ['sometimes', 'nullable', 'string'],", $rendered['lines'][0]);
    }

    public function test_an_explicit_required_modifier_survives_update_relaxation(): void
    {
        $fields = FieldDefinitionParser::parse('title:string:required');
        $rendered = RequestRuleRenderer::render($fields, 'update', 'posts', 'post');

        self::assertSame("            'title' => ['required', 'string'],", $rendered['lines'][0]);
    }

    public function test_a_bare_id_column_is_auto_detected_as_a_foreign_key(): void
    {
        $fields = FieldDefinitionParser::parse('author_id');
        $rendered = RequestRuleRenderer::render($fields, 'store', 'posts', 'post');

        self::assertSame(
            "            'author_id' => ['required', 'integer', 'exists:authors,id'],",
            $rendered['lines'][0]
        );
        self::assertCount(1, $rendered['notes']);
        self::assertStringContainsString('authors', $rendered['notes'][0]);
    }

    public function test_an_explicit_exists_table_suppresses_the_guess_note(): void
    {
        $fields = FieldDefinitionParser::parse('owner_id:foreignId:exists=users');
        $rendered = RequestRuleRenderer::render($fields, 'store', 'posts', 'post');

        self::assertSame(
            "            'owner_id' => ['required', 'integer', 'exists:users,id'],",
            $rendered['lines'][0]
        );
        self::assertSame([], $rendered['notes']);
    }

    public function test_store_uses_a_plain_unique_string_rule(): void
    {
        $fields = FieldDefinitionParser::parse('email:string:unique');
        $rendered = RequestRuleRenderer::render($fields, 'store', 'users', 'user');

        self::assertSame(
            "            'email' => ['required', 'string', 'unique:users,email'],",
            $rendered['lines'][0]
        );
        self::assertFalse($rendered['usesRuleClass']);
    }

    public function test_update_uses_a_rule_unique_object_with_ignore(): void
    {
        $fields = FieldDefinitionParser::parse('email:string:unique');
        $rendered = RequestRuleRenderer::render($fields, 'update', 'users', 'user');

        self::assertSame(
            "            'email' => ['sometimes', 'required', 'string', Rule::unique('users', 'email')->ignore(\$this->route('user'))],",
            $rendered['lines'][0]
        );
        self::assertTrue($rendered['usesRuleClass']);
    }

    public function test_unique_without_a_table_is_skipped_with_a_note(): void
    {
        $fields = FieldDefinitionParser::parse('email:string:unique');
        $rendered = RequestRuleRenderer::render($fields, 'store', null, 'user');

        self::assertSame("            'email' => ['required', 'string'],", $rendered['lines'][0]);
        self::assertCount(1, $rendered['notes']);
        self::assertStringContainsString('table', $rendered['notes'][0]);
    }

    public function test_it_renders_min_max_in_and_confirmed_constraints(): void
    {
        $fields = FieldDefinitionParser::parse('age:integer:min=18:max=99;role:string:in=admin,editor;password:string:confirmed');
        $rendered = RequestRuleRenderer::render($fields, 'store', 'users', 'user');

        self::assertSame("            'age' => ['required', 'integer', 'min:18', 'max:99'],", $rendered['lines'][0]);
        self::assertSame("            'role' => ['required', 'string', 'in:admin,editor'],", $rendered['lines'][1]);
        self::assertSame("            'password' => ['required', 'string', 'confirmed'],", $rendered['lines'][2]);
    }
}
