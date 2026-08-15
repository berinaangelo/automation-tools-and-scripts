<?php

declare(strict_types=1);

namespace SmartFormRequests\Tests;

use PHPUnit\Framework\TestCase;
use SmartFormRequests\Support\RuleTypeMapper;

final class RuleTypeMapperTest extends TestCase
{
    public function test_it_maps_type_tokens_to_base_rules(): void
    {
        self::assertSame(['string'], RuleTypeMapper::baseRules('string'));
        self::assertSame(['string'], RuleTypeMapper::baseRules('text'));
        self::assertSame(['integer'], RuleTypeMapper::baseRules('integer'));
        self::assertSame(['boolean'], RuleTypeMapper::baseRules('boolean'));
        self::assertSame(['numeric'], RuleTypeMapper::baseRules('decimal'));
        self::assertSame(['date'], RuleTypeMapper::baseRules('date'));
        self::assertSame(['date'], RuleTypeMapper::baseRules('datetime'));
        self::assertSame(['string', 'email'], RuleTypeMapper::baseRules('email'));
        self::assertSame(['string', 'url'], RuleTypeMapper::baseRules('url'));
        self::assertSame(['array'], RuleTypeMapper::baseRules('json'));
        self::assertSame(['integer'], RuleTypeMapper::baseRules('foreignId'));
    }

    public function test_unknown_type_falls_back_to_string(): void
    {
        self::assertSame(['string'], RuleTypeMapper::baseRules('something-unknown'));
    }

    /**
     * @return array<string, array{0: string, 1: string}>
     */
    public static function dbTypeProvider(): array
    {
        return [
            'bigint' => ['bigint', 'integer'],
            'smallint' => ['smallint', 'integer'],
            'boolean' => ['boolean', 'boolean'],
            'bare tinyint is treated as boolean' => ['tinyint', 'boolean'],
            'decimal' => ['decimal', 'decimal'],
            'date' => ['date', 'date'],
            'datetime' => ['datetime', 'datetime'],
            'timestamp' => ['timestamp', 'datetime'],
            'json' => ['json', 'json'],
            'varchar falls back to string' => ['varchar', 'string'],
        ];
    }

    /**
     * @dataProvider dbTypeProvider
     */
    public function test_it_maps_database_types_to_canonical_tokens(string $dbType, string $expected): void
    {
        self::assertSame($expected, RuleTypeMapper::fromDatabaseType($dbType));
    }
}
