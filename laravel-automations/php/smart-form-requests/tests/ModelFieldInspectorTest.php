<?php

declare(strict_types=1);

namespace SmartFormRequests\Tests;

use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;
use SmartFormRequests\Support\ModelFieldInspector;

final class ModelFieldInspectorTest extends TestCase
{
    public function test_it_builds_field_definitions_from_fillable_and_casts(): void
    {
        $fields = ModelFieldInspector::inspect(FakeCommentModel::class);

        $byName = [];
        foreach ($fields as $field) {
            $byName[$field->name] = $field;
        }

        self::assertSame('string', $byName['body']->type);
        self::assertSame('boolean', $byName['approved']->type);
        self::assertSame('json', $byName['meta']->type);
        self::assertSame('datetime', $byName['posted_at']->type);

        // Model-inferred fields default to "sometimes" - we don't know DB constraints.
        self::assertTrue($byName['body']->has('sometimes'));
    }

    public function test_it_rejects_a_non_model_class(): void
    {
        $this->expectException(InvalidArgumentException::class);

        ModelFieldInspector::inspect(self::class);
    }

    public function test_it_rejects_an_unknown_class(): void
    {
        $this->expectException(InvalidArgumentException::class);

        ModelFieldInspector::inspect('App\\Models\\DoesNotExist');
    }
}

final class FakeCommentModel extends Model
{
    protected $fillable = ['body', 'approved', 'meta', 'posted_at'];

    protected $casts = [
        'approved' => 'boolean',
        'meta' => 'array',
        'posted_at' => 'datetime',
    ];
}
