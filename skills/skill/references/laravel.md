# Laravel Packages

## Structure
```
package/
├── src/
│   ├── Http/{Controllers/,Middleware/}
│   ├── Providers/PackageServiceProvider.php
│   ├── Concerns/     # Eloquent traits (HasCrud)
│   ├── Traits/       # general PHP traits
│   └── Support/
├── config/package.php
├── database/migrations/
├── resources/views/
├── routes/web.php
└── composer.json
```

## ServiceProvider
```php
class PackageServiceProvider extends ServiceProvider {
    public function register(): void {
        $this->mergeConfigFrom(__DIR__.'/../../config/package.php', 'package');
    }
    public function boot(): void {
        $this->registerPublishing();
        $this->loadMigrationsFrom(__DIR__.'/../../database/migrations');
        $this->registerRoutes();
        $this->registerViews();
        $this->registerViewComposers();
        $this->registerMiddleware();
        $this->registerCommands();
        $this->registerEventListeners();
    }
    // one protected method per concern above
}
```

## Config-Driven
```php
$model = config('package.user_model', 'App\\Models\\User');
$roles = config('package.admin_roles', ['admin', 'super-admin']);
$disk  = config('package.uploads.disk', 'public');
```

## Abstract BaseController
```php
abstract class BaseController extends Controller {
    protected function isAdmin(): bool {
        $user = auth()->user();
        if (!$user || !method_exists($user, 'roleSlugs')) return false;
        return !empty(array_intersect(config('package.admin_roles', ['admin']), $user->roleSlugs()));
    }
    protected function getViewData(array $data = []): array {
        return array_merge(['isAdmin' => $this->isAdmin(), 'user' => auth()->user()], $data);
    }
}
```

## HasCrud Concern
```php
trait HasCrud {
    public static function getResourceConfig(): array {
        $i = new static;
        return [
            'model'    => static::class,
            'title'    => $i->resourceTitle ?? Str::title(Str::plural(Str::snake(class_basename(static::class)))),
            'fields'   => $i->resourceFields ?? static::getCachedFieldsOrGenerate($i),
            'roles'    => $i->resourceRoles ?? [],
            'readonly' => $i->resourceReadonly ?? [],
        ];
    }
    public static function getResourceKey(): string {
        $i = new static;
        return $i->resourceKey ?? Str::plural(Str::snake(class_basename(static::class)));
    }
}
```
Cache fields with content-hash key: `Cache::get('pkg_'.md5($class).'_'.md5(serialize($fillable)))`.

## Routes
```php
Route::group([
    'prefix' => config('package.routes.prefix', 'dashboard'),
    'middleware' => config('package.routes.middleware', ['web', 'auth']),
], fn() => $this->loadRoutesFrom(__DIR__.'/../../routes/web.php'));

// Dev/example routes
if (!app()->environment('production')) {
    Route::get('/components', [ComponentsController::class, 'components']);
}
```

## Granular Publishing
```php
$this->publishes([__DIR__.'/../../config/package.php' => config_path('package.php')], 'package-config');
$this->publishes([$views => resource_path('views/vendor/package')], 'package-views');
$this->publishes([$views.'/partials/styles.blade.php' => ...], 'package-styles');
// + combined 'package' group
```

## Middleware + View Composers + Commands
```php
protected function registerMiddleware(): void {
    $this->app['router']->aliasMiddleware('package.admin', EnsureIsAdmin::class);
    $this->app['router']->pushMiddlewareToGroup('web', HandleImpersonation::class);
}
View::composer(['package::*'], fn($v) => $v->with('user', auth()->user()));
protected function registerCommands(): void {
    if (!$this->app->runningInConsole()) return;
    $this->commands([InstallCommand::class, MakeResourceCommand::class]);
}
```

## Naming
- Classes: `PascalCase` + role, as in `ResourceController`, `EnsureIsAdmin`, `HasCrud`
- Config keys: `kebab-case.dot.notation`, as in `package.admin_roles`
- Blade: `kebab-case.blade.php` namespaced, as in `package::partials.flash-messages`
- PHPDoc `@param`/`@return` on every public method

## Field Type Auto-Detection

In `HasCrud`, guess field type from name patterns first, then fall back to DB column type. Priority order:

1. `*_id` suffix → `select` (relationship)
2. `email` / `password` / `url` → typed input
3. `is_*` / `has_*` / `can_*` → `boolean`
4. contains `description`/`bio`/`body` → `textarea`, `hide_in_index: true`
5. contains `image`/`photo`/`file` → `file`, `hide_in_index: true`
6. DB column type → `boolean`/`integer`/`decimal`/`text`/`date`/`datetime`
7. Default → `text`

## Reflection-Based Model Discovery

Scan `app/Models/` with `RecursiveIteratorIterator` to find models using a trait. Cache the result in a `static` variable:

```php
protected function getModelsWithTrait($trait): array {
    static $cachedModels = null;
    if ($cachedModels !== null) return $cachedModels;
    // scan app_path('Models') ...
    return $cachedModels = $models;
}
```

## Anti-Patterns to Avoid (PHP / Laravel)

- Business logic in `register()`: only bindings there
- Hardcoded strings where config key + default should be used
- Single monolithic `publishes()` group: split by concern
- Commands defined inline: always a separate class per command
- Auth/role checks duplicated across controllers: move to BaseController or middleware
- `echo` / `var_dump` in library code
- No PHPDoc on public methods
- Missing `runningInConsole()` guard before registering commands
