<?php

declare(strict_types=1);

namespace SmartFormRequests;

use Illuminate\Support\ServiceProvider;
use SmartFormRequests\Console\Commands\MakeSmartFormRequestCommand;

class SmartFormRequestsServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                MakeSmartFormRequestCommand::class,
            ]);
        }
    }
}
