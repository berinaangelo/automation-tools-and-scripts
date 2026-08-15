<?php

declare(strict_types=1);

namespace SmartMigrations\Tests;

use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use SmartMigrations\Support\ModelColumnInspector;

final class ModelColumnInspectorTest extends TestCase
{
    public function test_it_builds_field_definitions_from_fillable_and_casts(): void
    {
        $fields = ModelColumnInspector::inspect(FakePostModel::class);

        $byName = [];
        foreach ($fields as $field) {
            $byName[$field->name] = $field;
        }

        self::assertSame('string', $byName['title']->type);
        self::assertSame('boolean', $byName['published']->type);
        self::assertSame('json', $byName['meta']->type);
        self::assertSame('dateTime', $byName['published_at']->type);

        // Model-inferred columns are always nullable since we can't know DB constraints.
        self::assertTrue($byName['title']->has('nullable'));
    }

    public function test_it_rejects_a_non_model_class(): void
    {
        $this->expectException(InvalidArgumentException::class);

        ModelColumnInspector::inspect(self::class);
    }

    public function test_it_rejects_an_unknown_class(): void
    {
        $this->expectException(InvalidArgumentException::class);

        ModelColumnInspector::inspect('App\\Models\\DoesNotExist');
    }
}

final class FakePostModel extends Model
{
    protected $fillable = ['title', 'published', 'meta', 'published_at'];

    protected $casts = [
        'published' => 'boolean',
        'meta' => 'array',
        'published_at' => 'datetime',
    ];
}
