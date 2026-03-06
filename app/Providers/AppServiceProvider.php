<?php

namespace App\Providers;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Vite;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->ensurePostgresSchema();
    }

    /**
     * Create the configured PostgreSQL schema if it does not exist and set the search_path.
     */
    private function ensurePostgresSchema(): void
    {
        if (config('database.default') !== 'pgsql') {
            return;
        }

        $schema = preg_replace('/[^A-Za-z0-9_]/', '', env('DB_SCHEMA', 'public')) ?: 'public';
        $quotedSchema = str_replace('"', '""', $schema);

        try {
            DB::statement('CREATE SCHEMA IF NOT EXISTS "'.$quotedSchema.'"');
            DB::statement('SET search_path TO "'.$quotedSchema.'"');
        } catch (\Throwable $exception) {
            logger()->warning('Unable to ensure PostgreSQL schema exists.', [
                'schema' => $schema,
                'error' => $exception->getMessage(),
            ]);
        }
    }
}
