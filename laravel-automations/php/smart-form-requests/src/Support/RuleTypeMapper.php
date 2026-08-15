<?php

declare(strict_types=1);

namespace SmartFormRequests\Support;

/**
 * Maps a field-DSL type token (or a raw DB column type) to the base Laravel
 * validation rule(s) that should represent it, before any modifiers/options
 * (unique, exists, min, max, ...) are layered on top.
 */
final class RuleTypeMapper
{
    /** @var array<string, string> Aliases that fold onto a canonical token below. */
    private const ALIASES = [
        'text' => 'string',
        'int' => 'integer',
        'bool' => 'boolean',
        'float' => 'decimal',
        'double' => 'decimal',
        'numeric' => 'decimal',
        'timestamp' => 'datetime',
        'array' => 'json',
    ];

    /** @var array<string, array<int, string>> */
    private const BASE_RULES = [
        'string' => ['string'],
        'integer' => ['integer'],
        'boolean' => ['boolean'],
        'decimal' => ['numeric'],
        'date' => ['date'],
        'datetime' => ['date'],
        'email' => ['string', 'email'],
        'url' => ['string', 'url'],
        'json' => ['array'],
        'foreignId' => ['integer'],
    ];

    public static function canonical(string $type): string
    {
        return self::ALIASES[$type] ?? $type;
    }

    /**
     * @return array<int, string>
     */
    public static function baseRules(string $type): array
    {
        return self::BASE_RULES[self::canonical($type)] ?? ['string'];
    }

    /**
     * Translate a raw DB column type (as reported by Schema::getColumns()/
     * getColumnType()) into one of the canonical type tokens above.
     */
    public static function fromDatabaseType(string $dbType): string
    {
        return match (strtolower($dbType)) {
            'bigint', 'integer', 'int', 'smallint', 'mediumint' => 'integer',
            // MySQL has no native boolean column - Blueprint::boolean() creates a
            // tinyint(1), so we treat bare "tinyint" as boolean, the common case.
            'boolean', 'bool', 'tinyint' => 'boolean',
            'decimal', 'float', 'double', 'real' => 'decimal',
            'date' => 'date',
            'datetime', 'timestamp', 'timestamptz' => 'datetime',
            'json', 'jsonb' => 'json',
            default => 'string',
        };
    }
}
