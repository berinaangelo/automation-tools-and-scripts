<?php

declare(strict_types=1);

namespace SmartFormRequests\Support;

use RuntimeException;

/**
 * Fills the request.stub file's {{ token }} placeholders with generated content.
 */
final class RequestStubBuilder
{
    public function __construct(private readonly string $stubsPath)
    {
    }

    /**
     * @param  array<string, string>  $replacements
     */
    public function build(string $stubName, array $replacements): string
    {
        $stubFile = rtrim($this->stubsPath, '/') . '/' . $stubName;
        $stub = @file_get_contents($stubFile);

        if ($stub === false) {
            throw new RuntimeException("Unable to read request stub [{$stubFile}].");
        }

        foreach ($replacements as $token => $value) {
            $stub = str_replace('{{ ' . $token . ' }}', $value, $stub);
        }

        return $stub;
    }
}
