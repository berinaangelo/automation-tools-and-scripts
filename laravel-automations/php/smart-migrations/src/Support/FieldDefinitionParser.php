<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * Parses the --fields option into FieldDefinition objects.
 *
 * Syntax per field, separated by semicolons (commas are reserved for values
 * like a decimal's "precision=8,2"): name:type:modifier:key=value...
 *   title:string
 *   body:text:nullable
 *   email:string:unique
 *   author_id                       (bare name -> inferred as a foreign key, see ForeignKeyResolver)
 *   author_id:foreignId:constrained=authors
 *   price:decimal:precision=8,2
 *
 * Example: --fields="title:string;body:text:nullable;price:decimal:precision=8,2"
 */
final class FieldDefinitionParser
{
    /**
     * @return array<int, FieldDefinition>
     */
    public static function parse(string $fields): array
    {
        $definitions = [];

        foreach (self::splitFields($fields) as $raw) {
            if ($raw === '') {
                continue;
            }

            $definitions[] = self::parseOne($raw);
        }

        return $definitions;
    }

    private static function parseOne(string $raw): FieldDefinition
    {
        $parts = explode(':', $raw);
        $name = trim(array_shift($parts));
        $type = $parts !== [] ? trim((string) array_shift($parts)) : '';
        $type = $type !== '' ? $type : 'string';

        $modifiers = [];
        $options = [];

        foreach ($parts as $part) {
            $part = trim($part);
            if ($part === '') {
                continue;
            }

            if (str_contains($part, '=')) {
                [$key, $value] = explode('=', $part, 2);
                $options[trim($key)] = trim($value);
            } else {
                $modifiers[] = $part;
            }
        }

        return new FieldDefinition($name, $type, $modifiers, $options);
    }

    /**
     * @return array<int, string>
     */
    private static function splitFields(string $fields): array
    {
        return array_filter(array_map('trim', explode(';', $fields)), static fn (string $f) => $f !== '');
    }
}
