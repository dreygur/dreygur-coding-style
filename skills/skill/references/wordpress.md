# WordPress Plugins

## Plugin Header + Security Guard
```php
<?php
/**
 * Plugin Name:    MyPlugin
 * Version:        1.0.0
 * Author:         Name
 * Text Domain:    myplugin
 * Domain Path:    /languages
 */
defined('ABSPATH') || exit;  // top of EVERY PHP file
```

## Complex Plugin: `final` Singleton
```php
final class MyPlugin {
    private static $instance = null;
    public static function get_instance(): self {
        if (null === self::$instance) self::$instance = new self();
        return self::$instance;
    }
    private function __construct() { $this->init(); }
    private function init(): void {
        $this->load_dependencies();
        $this->define_constants();
        $this->init_hooks();
    }
    private function load_dependencies(): void { require_once __DIR__ . '/vendor/autoload.php'; }
    private function define_constants(): void {
        define('MYPLUGIN_VERSION', '1.0.0');
        define('MYPLUGIN_URL', plugin_dir_url(__FILE__));
        define('MYPLUGIN_PATH', plugin_dir_path(__FILE__));
    }
    private function init_hooks(): void {
        add_action('plugins_loaded', [$this, 'init_feature'], 100);
    }
}
MyPlugin::get_instance();
```

## Minimal Plugin: Direct `new`
Single-responsibility plugins skip singleton:
```php
class SingleSession {
    public function __construct() {
        add_action('wp_login', [$this, 'force_single_session'], 10, 2);
    }
    public function force_single_session($login, $user) {
        if (is_a($user, 'WP_User')) {
            $sessions = get_user_meta($user->ID, 'session_tokens', true);
            if ($sessions && is_array($sessions))
                update_user_meta($user->ID, 'session_tokens', array_slice($sessions, -1));
        }
    }
}
new SingleSession();
```

## `final class Init` Per Feature
All hooks in constructor:
```php
final class Init {
    public function __construct() {
        add_filter('plugin_gateways', [self::class, 'add_gateways']);
        add_filter('plugin_payment_methods', [$this, 'add_method'], 100);
        add_action('init', [$this, 'process_form']);
    }
}
```

## `private const` for Config + Status Maps
```php
private const STATUS_MAP = ['VALID' => 'paid', 'FAILED' => 'failed', 'CANCELLED' => 'cancelled'];
private function mapStatus(string $s): string { return self::STATUS_MAP[$s] ?? 'failed'; }
```

## WP HTTP API (not curl/Guzzle)
```php
$response = wp_remote_post($url, ['timeout' => 60, 'sslverify' => !$isSandbox, 'body' => $data]);
if (is_wp_error($response)) return ['status' => 'FAILED', 'reason' => $response->get_error_message()];
$code = wp_remote_retrieve_response_code($response);
$body = wp_remote_retrieve_body($response);
```

## Input + i18n
```php
// Sanitize all $_POST
$val = sanitize_text_field(wp_unslash($_POST['key']));
// All user-facing strings
throw new \InvalidArgumentException(__('Order ID required', 'myplugin'));
```

## Error Handling
```php
// Catch Throwable not Exception (PHP 7+)
try { $this->process($data); } catch (Throwable $e) {
    if (defined('WP_DEBUG') && WP_DEBUG) error_log('Error: ' . $e->getMessage());
    $result->status = 'failed'; $result->reason = $e->getMessage(); return $result;
}
// Validate early
if (empty($data->order_id)) throw new \InvalidArgumentException(__('Order ID required', 'myplugin'));
```

## Vue 3 + Vite Admin UI
```php
// In plugin class __construct():
add_action('admin_enqueue_scripts', [$this, 'loadAssets']);
add_action('admin_menu', [$this, 'adminMenu']);
add_filter('script_loader_tag', [$this, 'asModule'], 10, 3);  // WP can't do type="module" natively

function asModule($tag, $handle, $src) {
    if ('my-handle' !== $handle) return $tag;
    return '<script type="module" src="' . esc_url($src) . '"></script>';
}
function loadAssets() {
    // Dev: Vite HMR. Prod: dist/assets/main.js
    wp_enqueue_script('my-handle', '//localhost:5173/src/main.js', [], time(), true);
    wp_localize_script('my-handle', 'myplugin', [
        'url' => plugin_dir_url(__FILE__), 'nonce' => wp_create_nonce('wp_rest'), 'api' => get_rest_url(),
    ]);
}
```
Admin page template: just `<div class="wrap"><div id="app"></div></div>`

Vue entry (`src/main.js`):
```js
import { createApp } from 'vue';
import App from './App.vue';
createApp(App).mount('#app');
```
Access localized data: `window.myplugin.url`. `<script setup>` in all SFCs.

`vite.config.js`:
```js
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
export default defineConfig({ plugins: [vue()] });
```

## Plugin Structures
```
# Complex:                          # Minimal:
plugin/                             plugin/
├── plugin.php (singleton)          └── plugin.php (header + new ClassName())
├── integration/Init.php
├── payments/Provider/Provider.php
├── assets/
└── vendor/
```

## WordPress Plugin Patterns

### Hook Registration Location

All hooks/filters in `__construct()` of the `Init` class or `init_hooks()` of the main class, never scattered across files:

```php
public function __construct() {
    add_filter('tutor_gateways_with_class', [self::class, 'add_gateways']);
    add_filter('tutor_payment_methods', [$this, 'add_method'], 100);
    add_action('init', [$this, 'process_form']);
}
```

### Static vs Instance Methods on Hooks

- `[self::class, 'method']`: for static methods on filters that need no instance state
- `[$this, 'method']`: for instance methods that need object properties

### Plugin Constants Pattern

```php
define('PLUGIN_VERSION', '1.0.0');
define('PLUGIN_URL', plugin_dir_url(__FILE__));
define('PLUGIN_PATH', plugin_dir_path(__FILE__));
```

Prefix all constants with plugin slug: `TSPAY_VERSION`, `TSPAY_URL`, `TSPAY_PATH`.

## WordPress + Vue 3 Script Module Pattern

WP's `wp_enqueue_script` outputs `<script src>` not `<script type="module" src>`. Use `script_loader_tag` filter to fix:

```php
add_filter('script_loader_tag', function($tag, $handle, $src) {
    if ('my-handle' !== $handle) return $tag;
    return '<script type="module" src="' . esc_url($src) . '"></script>';
}, 10, 3);
```

## Dev vs Prod Asset URL

```php
$isDev = defined('WP_DEBUG') && WP_DEBUG;
$src = $isDev
    ? '//localhost:5173/src/main.js'       // Vite HMR
    : plugin_dir_url(__FILE__) . 'dist/assets/main.js'; // Built
wp_enqueue_script('my-handle', $src, [], time(), true);
```

## Anti-Patterns to Avoid (PHP / WordPress)

- Missing `defined('ABSPATH') || exit` at top of file
- Raw `$_POST`/`$_GET`: always `sanitize_text_field(wp_unslash(...))`
- User-facing strings without `__('string', 'text-domain')`
- `curl_*` / Guzzle for HTTP: use `wp_remote_post()` / `wp_remote_get()`
- `error_log()` without `WP_DEBUG` guard
- `catch (Exception $e)`: use `catch (Throwable $e)` for PHP 7+
- Non-final main plugin class (for complex plugins)
- Multiple plugin singletons: one main class, one `get_instance()`
- Hooks registered outside `__construct()` or `init_hooks()`
- Hardcoded URLs or nonces in JS: always `wp_localize_script`
- Missing `type="module"` on Vite/ES module scripts: use the `script_loader_tag` filter
- Using `Options API` in Vue SFCs: always `<script setup>` (Composition API)
