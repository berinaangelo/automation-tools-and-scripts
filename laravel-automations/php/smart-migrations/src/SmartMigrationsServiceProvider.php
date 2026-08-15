<?php

declare(strict_types=1);

namespace SmartMigrations;

use Illuminate\Support\ServiceProvider;
use SmartMigrations\Console\Commands\MakeSmartMigrationCommand;

class SmartMigrationsServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                MakeSmartMigrationCommand::class,
            ]);
        }
    }
}
