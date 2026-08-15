<?php

declare(strict_types=1);

namespace SmartMigrations\Support;

/**
 * A single parsed column: name, Blueprint method to call, bare modifiers
 * ("nullable", "unique", "index"), and keyed options ("default=18", "constrained=authors").
 */
final class FieldDefinition
{
    /**
     * @param  array<int, string>  $modifiers
     * @param  array<string, string>  $options
     */
    public function __construct(
        public readonly string $name,
        public readonly string $type,
        public readonly array $modifiers = [],
        public readonly array $options = [],
    ) {
    }

    public function has(string $modifier): bool
    {
        return in_array($modifier, $this->modifiers, true);
    }

    public function option(string $key): ?string
    {
        return $this->options[$key] ?? null;
    }

    /**
     * Extra constructor arguments for the Blueprint type-method call, e.g.
     * ", 8, 2" for a decimal:precision=8,2 field. Empty string when none apply.
     */
    public function typeArgs(): string
    {
        if ($this->type === 'decimal' && ($precision = $this->option('precision')) !== null) {
            $parts = array_map('trim', explode(',', $precision));

            return ', ' . implode(', ', $parts);
        }

        if ($this->type === 'string' && ($length = $this->option('length')) !== null) {
            return ", {$length}";
        }

        return '';
    }
}
