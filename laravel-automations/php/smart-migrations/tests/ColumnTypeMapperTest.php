<?php

declare(strict_types=1);

namespace SmartMigrations\Tests;

use PHPUnit\Framework\TestCase;
use SmartMigrations\Support\ColumnTypeMapper;

final class ColumnTypeMapperTest extends TestCase
{
    /**
     * @return array<string, array{0: ?string, 1: string}>
     */
    public static function castProvider(): array
    {
        return [
            'null cast defaults to string' => [null, 'string'],
            'boolean' => ['boolean', 'boolean'],
            'integer' => ['integer', 'integer'],
            'array' => ['array', 'json'],
            'plain decimal' => ['decimal', 'decimal'],
            'decimal with precision' => ['decimal:2', 'decimal'],
            'datetime' => ['datetime', 'dateTime'],
            'custom datetime format' => ['datetime:Y-m-d', 'dateTime'],
            'unknown cast falls back to string' => ['encrypted', 'string'],
        ];
    }

    /**
     * @dataProvider castProvider
     */
    public function test_it_maps_casts_to_blueprint_types(?string $cast, string $expected): void
    {
        self::assertSame($expected, ColumnTypeMapper::fromCast($cast));
    }
}
