<?php

declare(strict_types=1);

namespace SmartFormRequests\Support;

use Illuminate\Support\Str;
use SmartMigrations\Support\FieldDefinition;
use SmartMigrations\Support\ForeignKeyResolver;

/**
 * Renders FieldDefinitions into the lines of a FormRequest's rules() array,
 * for either a "store" (defaults required) or "update" (defaults sometimes,
 * ->ignore()s unique rules) action.
 */
final class RequestRuleRenderer
{
    private const INDENT = '            ';

    /**
     * @param  array<int, FieldDefinition>  $fields
     * @return array{lines: array<int, string>, notes: array<int, string>, usesRuleClass: bool}
     */
    public static function render(array $fields, string $action, ?string $table, string $routeParam): array
    {
        $lines = [];
        $notes = [];
        $usesRuleClass = false;

        foreach ($fields as $field) {
            $result = self::renderField($field, $action, $table, $routeParam);
            $lines[] = $result['line'];
            if ($result['note'] !== null) {
                $notes[] = $result['note'];
            }
            $usesRuleClass = $usesRuleClass || $result['usesRuleClass'];
        }

        return ['lines' => $lines, 'notes' => $notes, 'usesRuleClass' => $usesRuleClass];
    }

    /**
     * @return array{line: string, note: ?string, usesRuleClass: bool}
     */
    private static function renderField(FieldDefinition $field, string $action, ?string $table, string $routeParam): array
    {
        $elements = self::presenceElements($field, $action);
        $note = null;
        $usesRuleClass = false;

        if (self::isForeignKey($field)) {
            [$fkElements, $fkNote] = self::foreignKeyElements($field, $table);
            $elements = [...$elements, ...$fkElements];
            $note = $fkNote;
        } else {
            $elements = [...$elements, ...self::typeElements($field)];
        }

        $elements = [...$elements, ...self::constraintElements($field)];

        if ($field->has('unique') && ! self::isForeignKey($field)) {
            [$uniqueElement, $uniqueNote, $needsRuleClass] = self::uniqueElement($field, $action, $table, $routeParam);
            if ($uniqueElement !== null) {
                $elements[] = $uniqueElement;
            }
            $note ??= $uniqueNote;
            $usesRuleClass = $needsRuleClass;
        }

        $line = self::INDENT . "'{$field->name}' => [" . implode(', ', $elements) . '],';

        return ['line' => $line, 'note' => $note, 'usesRuleClass' => $usesRuleClass];
    }

    /**
     * @return array<int, string>
     */
    private static function presenceElements(FieldDefinition $field, string $action): array
    {
        $forceRequired = $field->has('required');
        $forceSometimes = $field->has('sometimes');
        $nullable = $field->has('nullable');

        if ($action === 'update' && ! $forceRequired) {
            return $nullable ? [self::quote('sometimes'), self::quote('nullable')] : [self::quote('sometimes'), self::quote('required')];
        }

        if ($forceSometimes) {
            return $nullable ? [self::quote('sometimes'), self::quote('nullable')] : [self::quote('sometimes')];
        }

        return $nullable ? [self::quote('nullable')] : [self::quote('required')];
    }

    private static function isForeignKey(FieldDefinition $field): bool
    {
        if ($field->type === 'foreignId') {
            return true;
        }

        return RuleTypeMapper::canonical($field->type) === 'string' && ForeignKeyResolver::looksLikeForeignKey($field->name);
    }

    /**
     * @return array{0: array<int, string>, 1: ?string}
     */
    private static function foreignKeyElements(FieldDefinition $field, ?string $table): array
    {
        $elements = [self::quote('integer')];

        $explicitTable = $field->option('exists');
        $guessedTable = $explicitTable ?? ForeignKeyResolver::guessTable($field->name);

        if ($guessedTable === null) {
            return [$elements, "Could not guess an FK target table for `{$field->name}` — add exists=table to --fields to set it manually."];
        }

        $elements[] = self::quote("exists:{$guessedTable},id");

        $note = $explicitTable === null
            ? "Guessed FK target table `{$guessedTable}` for `{$field->name}` — please verify this is correct."
            : null;

        return [$elements, $note];
    }

    /**
     * @return array<int, string>
     */
    private static function typeElements(FieldDefinition $field): array
    {
        return array_map(self::quote(...), RuleTypeMapper::baseRules($field->type));
    }

    /**
     * @return array<int, string>
     */
    private static function constraintElements(FieldDefinition $field): array
    {
        $elements = [];

        if ($field->has('confirmed')) {
            $elements[] = self::quote('confirmed');
        }

        foreach (['min', 'max', 'in'] as $option) {
            if (($value = $field->option($option)) !== null) {
                $elements[] = self::quote("{$option}:{$value}");
            }
        }

        return $elements;
    }

    /**
     * @return array{0: ?string, 1: ?string, 2: bool}
     */
    private static function uniqueElement(FieldDefinition $field, string $action, ?string $table, string $routeParam): array
    {
        if ($table === null) {
            return [null, "Skipped the unique rule for `{$field->name}` — pass --table (or --fields exists=...) so it knows which table to check.", false];
        }

        if ($action !== 'update') {
            return [self::quote("unique:{$table},{$field->name}"), null, false];
        }

        $escapedParam = addslashes($routeParam);

        return ["Rule::unique('{$table}', '{$field->name}')->ignore(\$this->route('{$escapedParam}'))", null, true];
    }

    private static function quote(string $rule): string
    {
        return "'" . addslashes($rule) . "'";
    }
}
