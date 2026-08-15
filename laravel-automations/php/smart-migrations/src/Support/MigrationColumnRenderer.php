<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * Turns FieldDefinitions into the Blueprint statement lines used in the
 * generated migration's up() (and, for alter migrations, down()) closures.
 */
final class MigrationColumnRenderer
{
    private const INDENT = '            ';

    /**
     * @param  array<int, FieldDefinition>  $fields
     * @return array{
     *     lines: array<int, string>,
     *     foreignDropLines: array<int, string>,
     *     plainDropNames: array<int, string>,
     *     notes: array<int, string>,
     * }
     */
    public static function render(array $fields): array
    {
        $lines = [];
        $foreignDropLines = [];
        $plainDropNames = [];
        $notes = [];

        foreach ($fields as $field) {
            if (self::isForeignKey($field)) {
                [$line, $dropLine, $note] = self::renderForeignKey($field);
                $lines[] = $line;
                $foreignDropLines[] = $dropLine;
                if ($note !== null) {
                    $notes[] = $note;
                }

                continue;
            }

            $lines[] = self::renderColumn($field);
            $plainDropNames[] = $field->name;
        }

        return [
            'lines' => $lines,
            'foreignDropLines' => $foreignDropLines,
            'plainDropNames' => $plainDropNames,
            'notes' => $notes,
        ];
    }

    /**
     * A field is treated as a foreign key when explicitly typed "foreignId", or when
     * its name looks like one ("author_id") and no other type was explicitly given.
     */
    private static function isForeignKey(FieldDefinition $field): bool
    {
        if ($field->type === 'foreignId') {
            return true;
        }

        return $field->type === 'string' && ForeignKeyResolver::looksLikeForeignKey($field->name);
    }

    /**
     * @return array{0: string, 1: string, 2: ?string}
     */
    private static function renderForeignKey(FieldDefinition $field): array
    {
        $explicitTable = $field->option('constrained');
        $guessedTable = $explicitTable ?? ForeignKeyResolver::guessTable($field->name);

        $call = self::INDENT . "\$table->foreignId('{$field->name}')";
        $call .= $guessedTable !== null ? "->constrained('{$guessedTable}')" : '->constrained()';

        if ($field->has('nullable')) {
            $call .= '->nullable()';
        }

        $call .= '->cascadeOnDelete();';

        $note = $explicitTable === null && $guessedTable !== null
            ? "Guessed FK target table `{$guessedTable}` for `{$field->name}` — please verify this is correct."
            : null;

        $dropLine = self::INDENT . "\$table->dropConstrainedForeignId('{$field->name}');";

        return [$call, $dropLine, $note];
    }

    private static function renderColumn(FieldDefinition $field): string
    {
        $call = self::INDENT . "\$table->{$field->type}('{$field->name}'{$field->typeArgs()})";

        foreach ($field->modifiers as $modifier) {
            $call .= match ($modifier) {
                'nullable' => '->nullable()',
                'unique' => '->unique()',
                'index' => '->index()',
                default => '',
            };
        }

        if (($default = $field->option('default')) !== null) {
            $call .= is_numeric($default) ? "->default({$default})" : "->default('{$default}')";
        }

        return $call . ';';
    }
}
