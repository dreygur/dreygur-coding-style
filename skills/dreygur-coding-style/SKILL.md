---
name: dreygur-coding-style
description: Use when writing any code for dreygur in Go, TypeScript, JavaScript, Rust, Python, or PHP/Laravel/WordPress. Trigger on "write code in my style", "follow my patterns", "use my architecture", "create a new project", "add a service/repository/handler", when ordering functions within a file, when writing tests or a commit message, when writing a README, doc, comment, or PR body that should not read as machine-written, or when reviewing code for style violations.
version: 2.8.0
---

# dreygur Coding Style

## The Shape of a File

Poetry and a story at the same time. Poetry: nothing wasted, the shape on the page carries meaning. Story: it reads in order, each part following from the last. Ordering is the argument, not an accident.

### 1. Dependencies Above, Composite Last
A function's dependencies are defined **above** it, never below. Write the composite, then place everything it calls above it. Reading top to bottom, you never meet a name before its parts.

```
constants -> leaf helpers -> mid-level helpers -> public entry point
```

No forward references. New helper + new caller means the helper goes first. This is the **opposite** of the common Rust/Go habit of parking helpers at the bottom. Do not follow that habit here.

Exception: when inserting into an existing section that already reads caller-first, keep the local convention rather than reordering existing code.

### 2. Constants Are the Rules of the Play
Timeouts, ports, limits, fixed strings sit at the very top of the file, before any behavior.

### 3. One File, One Purpose
Prefer a new file over growing an existing one when the concern is distinct.

### 4. Small Parts, Small Cast
Each part sets up only what it needs, with a cast small enough to hold in mind at once.

### 5. Never Label the Code
No section-divider comments, no banner comments with dashes, no block labels, not even plain descriptive ones. The shape is meant to be **felt in how the code reads, never announced in the text**.

```ts
// ---------- Helpers ----------        // never
// Scene: token refresh                 // never
// The composite                        // never
```

A comment earns its place only by explaining **why** something is the way it is, or a non-obvious constraint. Doc comments on exported items still apply (Universal Rule 8); those describe contract and intent, not layout.

---

## Universal Rules

### 1. Types First
Contracts before implementations.
- TS/JS: `types.ts` | Go: `models/` | Rust: `types.rs` | Python: base class | PHP: `src/Contracts/`

### 2. Layered Architecture

| Layer | TS/JS | Go | Rust | Python | PHP |
|---|---|---|---|---|---|
| Types | `types.ts` | `models/` | `types.rs` | base class | `src/Support/` |
| Services | `*.service.ts` | `methods/` | `*/manager.rs` | class methods | `src/Services/` |
| Repositories | `*.repository.ts` | `db/`, `repo/` | `*/store.rs` | class+DB | Eloquent+Concerns |
| Controllers | `*.handler.ts` | `handlers/` | `src/cli/` | route fns | `src/Http/Controllers/` |
| Middleware | `*.middleware.ts` | `hooks/` | `*/middleware.rs` | decorators | `src/Http/Middleware/` |
| Utils | `utils/` | `utils/`, `lib/` | `src/util/` | helpers | `src/Support/` |
| Config | `constants.ts` | `common/vars.go` | `src/config/` | `constants.py` | `config/*.php` |

### 3. Typed Errors, Never Raw Strings
- TS: class hierarchy extending `Error`
- Go: sentinel vars `var ErrX = errors.New(...)`
- Rust: `thiserror` enum
- Python: custom `Exception` subclasses
- PHP: `\InvalidArgumentException` or project-prefixed class

### 4. Singleton Exports
```ts
export const tokenService = new TokenService();
```
```go
var Collection = &db.MongoDB{Address: os.Getenv("DB_URI")}
```

### 5. Leveled Logging, Never Raw print/console.log in Library Code
| Language | Tool |
|---|---|
| Go | custom `PrintLog` + `fatih/color` (`[+]`/`[-]`/`[!]`/`[*]`) |
| TypeScript | `debugLog`/`infoLog`/`warnLog` wrappers or Winston |
| Rust | `tracing` (`info!`/`warn!`/`error!`/`debug!`) |
| Python | stdlib `logging` |

### 6. No Magic Values: constants/config files only
### 7. Never Swallow Errors: propagate with context
### 8. Doc Comments on every exported item: comment the *why*, never the layout
### 9. Filenames
- TS/JS: `kebab-case` + layer suffix, as in `token.service.ts`, `auth.middleware.ts`
- Go: `snake_case.go`, as in `token.go`, `cmd_handler.go`
- Rust: `snake_case.rs`, as in `error.rs`, `config_watcher.rs`
- Python: `snake_case.py`
- PHP: `PascalCase.php` matching class name

### 10. No Casts to Silence the Type Checker
Never wrap an expression to make an error go away: `/** @type {X} */ (expr)` in JS, `as any`/`as unknown as X` in TS. Every such cast is masking a real defect: a missing runtime guard, dead config, or a dynamic dispatch that should be explicit branches.

Fix it by narrowing at runtime or fixing the declaration. Annotating a `const` on its own line is fine. Types belong in `types.ts` / `types/*.d.ts`, not inline at the call site.

Only tolerated at a generic base-class boundary the type system genuinely cannot express (see `BaseRepository` below).

### 11. Tests Prove Behavior, Not Signatures
A clean `cargo build`, `tsc --noEmit`, or `go vet` is **not** evidence of correctness. Neither is a `no_run` doctest; it type-checks a signature and proves nothing.

- Every new function gets a test that **executes** it and asserts on real behavior, including error paths.
- Prefer hermetic tests that run in the default runner (`cargo test`, `pnpm test`, `go test ./...`) over ones needing live services; add a gated/`#[ignore]` integration test when the real contract matters.
- Never report work as done on the strength of a successful compile.

### 12. Test Doubles Are `mock`, Never `fake`
`mock_cdp`, `MockTokenStore`, `mock_server.go`. Not `fake_*`.

---

## TypeScript / JavaScript

### Structure
```
src/
├── index.ts        # barrel exports
├── types.ts
├── constants.ts
├── config.ts
├── errors.ts
├── services/       # *.service.ts
├── repositories/   # *.repository.ts
├── strategies/     # *.strategy.ts
├── middleware/     # *.middleware.ts
├── handlers/       # *.handler.ts
└── utils/
    ├── logger.ts
    └── mutex.ts
```

### Error Classes
```ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public recoverable = true,
    public userMessage?: string,
  ) {
    super(message);
    this.name = "AppError";
    Error.captureStackTrace(this, this.constructor);
  }
}
export class NetworkError extends AppError {
  constructor(message: string, userMessage?: string) {
    super(message, "NETWORK_ERROR", true, userMessage || "Network request failed.");
    this.name = "NetworkError";
  }
}
```

```ts
export function isRecoverableError(e: unknown): boolean {
  return e instanceof AppError ? e.recoverable : false;
}
export function getUserMessage(e: unknown): string {
  if (e instanceof AppError && e.userMessage) return e.userMessage;
  if (e instanceof Error) return e.message;
  return "An unexpected error occurred";
}
```

### Rules
- **Always semicolons**
- `import type` for type-only imports
- `async/await` everywhere, no `.then()/.catch()` chains
- `index.ts` re-exports everything (`export * from "./services/token.service.js"`)
- Classes: `PascalCase` + suffix, as in `TokenService`, `CredentialRepository`
- Instances: `camelCase`; Constants: `SCREAMING_SNAKE_CASE`

### Log Prefix (even without logger)
```ts
console.log(`[+] Waiting...`);
console.log(`[-] ${err.message}`);
```

### Graceful Shutdown
```ts
process.on('SIGINT', (signal) => { console.log(`[+] ${signal} Exiting...`); process.exit(0); });
process.on('SIGHUP', (signal) => { console.log(`[+] ${signal} Exiting...`); process.exit(0); });
```

### Script Entry (IIFE)
```ts
(async () => await main())();
```

### Branded Types for Entity IDs
```ts
export type Brand<T, B extends string> = T & { __brand: B };
export function asBrand<T extends Brand<any, any>>(value: any): T { return value as T; }
export function assertValidId<T extends Brand<string, any>>(value: unknown, idType: string): T {
  if (!isValidUUID(value)) throw new Error(`Invalid ${idType}: expected UUID`);
  return value as T;
}
export type UserId = Brand<string, 'UserId'>;
export type OrganizationId = Brand<string, 'OrganizationId'>;
```
Never use plain `string` for entity IDs. Always the specific branded type.

### Drizzle ORM Schema
```ts
export const users = pgTable('user', {
  id: uuid('id').notNull().primaryKey().defaultRandom(),
  email: varchar('email').notNull().unique(),
  ...timestamps,
});
export type TUser = typeof users.$inferSelect;
export type TUserInsert = typeof users.$inferInsert;
export const ZUserCreate = createInsertSchema(users);
export const ZUserUpdate = createUpdateSchema(users);
export const ZUserSelect = createSelectSchema(users);
```

### Base Repository (Drizzle)
```ts
export abstract class BaseRepository<T extends AnyPgTable & { id: any }, TId extends string = string> {
  constructor(protected readonly db: NodePgDatabase, protected readonly table: T) {}

  async findById(id: TId): Promise<T['$inferSelect']> { ... }
  async create(data: Partial<T['$inferInsert']>): Promise<TId> { ... }
  async update(id: TId, values: Partial<T['$inferInsert']>): Promise<TId> { ... }

  async delete(id: TId, tx?: ConnectionType) {
    return (tx ?? this.db).update(this.table).set({ deleted: true } as any)
      .where(eq(this.table.id, id as string)).execute();
  }
  async restore(id: TId, tx?: ConnectionType) {
    return (tx ?? this.db).update(this.table).set({ deleted: false } as any)
      .where(eq(this.table.id, id as string)).execute();
  }
  async withTransaction<R>(fn: (tx: ConnectionType) => Promise<R>): Promise<R> {
    return this.db.transaction(fn as any);
  }
}
```
Always soft delete (`deleted: true`). Optional `tx?` on mutating methods.

### tRPC Setup
```ts
export const t = initTRPC.context<Context>().meta<OpenApiMeta>().create({
  transformer: superjson,
  errorFormatter: ({ shape }) => ({
    ...shape,
    data: { ...shape.data, stack: process.env.NODE_ENV === 'development' ? shape.data?.stack : undefined },
  }),
});
export const router = t.router;
export const middleware = t.middleware;
export const createCallerFactory = t.createCallerFactory;
```

### Project-Prefixed Errors
```ts
export class PoachApiError extends Error {
  constructor(message: string, public success = false, public operational = true, stack = '') {
    super(message);
    this.name = 'PoachApiError';
    if (stack) this.stack = stack;
    else Error.captureStackTrace(this, this.constructor);
  }
}
export class PTRPCError extends TRPCError {
  public timestamp = new Date();
  public requestId?: string;
  constructor(params: ConstructorParameters<typeof TRPCError>[0] & { requestId?: string }) {
    super(params);
    this.requestId = params.requestId;
  }
}
```

### Winston Logger with Custom Levels
```ts
declare module 'winston' { interface Logger { db(msg: string | Error, ...meta: any[]): Logger; } }

const customLevels = {
  levels: { error: 0, warn: 1, info: 2, db: 3, debug: 4 },
  colors: { error: 'red', warn: 'yellow', info: 'green', db: 'magenta', debug: 'blue' },
};
winston.addColors(customLevels.colors);

export const logger = winston.createLogger({
  levels: customLevels.levels,
  level: process.env.NODE_ENV === 'development' ? 'debug' : 'db',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message }) => `[${level}] ${timestamp}: ${message}`),
  ),
  transports: [new winston.transports.Console({ stderrLevels: ['error'] })],
});
```

### Monorepo (Turborepo + pnpm)
```
project/
├── apps/api/           # Express + tRPC
├── apps/ui/            # Next.js App Router
├── packages/
│   ├── schema/         # Drizzle tables + drizzle-zod
│   ├── repository/     # BaseRepository + per-entity
│   ├── service/        # *.service.ts per entity
│   ├── trpc/           # router + context + middleware
│   ├── shared/         # branded-types, errors, constants
│   ├── validator/      # Zod validators
│   ├── logger/         # Winston
│   ├── email/          # provider pattern
│   └── telemetry/      # OpenTelemetry
├── cdk/                # AWS CDK (if cloud)
├── turbo.json
└── pnpm-workspace.yaml
```
Package naming: `@projectname/schema`, `@projectname/repository`, etc.

---

## Go

### Structure
**Libraries:**
```
project/
├── main.go  ├── go.mod  ├── Makefile  ├── sample.env
├── models/  ├── methods/interface.go  ├── hooks/  ├── handlers/
├── lib/  ├── utils/  ├── db/  └── tests/
```
**Applications:**
```
project/
├── main.go  ├── go.mod  ├── Makefile  ├── .env.example
└── internal/
    ├── models/  ├── config/  ├── ai/  ├── discord/
    ├── google/  ├── store/  └── worker/
```

### Interface First
```go
// methods/interface.go
type BkashService interface {
    GetToken() (*models.TokenResponse, error)
    CreatePayment(*models.CreateRequest, *models.TokenResponse) (*models.CreatePaymentResponse, error)
}
// Constructor returns interface, not concrete type
func GetBkash(appKey, appSecret string, isLive bool) methods.BkashService {
    return &methods.Bkash{AppKey: appKey, IsLiveStore: isLive}
}
```

### Error Handling
```go
if !utils.RequireNonEmpty(b.AppKey, b.AppSecret) {
    return nil, common.ErrEmptyRequiredField
}
if err != nil {
    return fmt.Errorf("fetch reviews: %w", err)
}
```
Bare `return nil, err` when no context adds value; `fmt.Errorf("context: %w", err)` when it does.

### Typed String Constants
```go
type ApprovalStatus string
const (
    StatusPending  ApprovalStatus = "pending"
    StatusApproved ApprovalStatus = "approved"
    StatusRejected ApprovalStatus = "rejected"
)
```

### Constructors That Can Fail
```go
func NewBot(token, channelID string) (*Bot, error) {
    session, err := discordgo.New("Bot " + token)
    if err != nil { return nil, fmt.Errorf("create discord session: %w", err) }
    return &Bot{session: session, channelID: channelID}, nil
}
```

### Concurrent-Safe Structs
```go
type Bot struct {
    session *discordgo.Session
    mu      sync.RWMutex
    pending map[string]*models.PendingApproval
}
func (b *Bot) isUserAllowed(id string) bool {
    b.mu.RLock(); defer b.mu.RUnlock()
    return b.allowedUsers[id]
}
```

### Primary + Fallbacks
```go
type Generator struct { providers map[string]Provider; primary string; fallbacks []string }

for _, name := range append([]string{g.primary}, g.fallbacks...) {
    if resp, err := providers[name].Generate(ctx, req); err == nil { return resp, nil }
}
```

### Map-Based Dispatch
```go
var Handlers = map[string]func(*discordgo.Session, *discordgo.InteractionCreate){
    "help": Help, "points": Points,
}
if fn, ok := Handlers[name]; ok { fn(s, i) }
```

### Graceful Shutdown
```go
sig := make(chan os.Signal, 1)
signal.Notify(sig, os.Interrupt)
<-sig
```

### Logging
```go
func PrintLog(text, status string) {
    switch status {
    case "info":  color.New(color.FgGreen).Println("[+] " + text)
    case "error": color.New(color.FgRed).Println("[-] " + text)
    case "warn":  color.New(color.FgYellow).Println("[!] " + text)
    default:      color.New(color.FgCyan).Println("[*] " + text)
    }
}
```

---

## Rust

### Structure
```
project/
├── Cargo.toml  ├── src/main.rs  ├── src/lib.rs  ├── src/error.rs
├── src/config/mod.rs  └── crates/*/src/{lib.rs,error.rs}
```

### Error Types (`thiserror` always)
```rust
#[derive(thiserror::Error, Debug)]
pub enum AppError {
    #[error("Transport: {0}")] Transport(String),
    #[error("IO: {0}")] Io(#[from] std::io::Error),
    #[error("JSON: {0}")] Json(#[from] serde_json::Error),
}
pub type Result<T> = std::result::Result<T, AppError>;
```
`anyhow`/`eyre` only in binary entry points. Library crates use typed `Result` alias.

### Binaries
```rust
#[tokio::main]
async fn main() -> eyre::Result<()> { ... }  // preferred in newer projects
// or anyhow::Result<()>
```

### Shared State
```rust
let store = Arc::new(Store::new());
tokio::spawn(async move {
    let store = Arc::clone(&store);  // explicit Arc::clone, not .clone()
    handle(stream, store).await
});
```

### tokio::select!
```rust
loop {
    tokio::select! {
        Some(event) = events.next() => { ... }
        _ = sleep(Duration::from_secs(30)) => { /* tick */ }
    }
}
```

### CLI (clap)
```rust
#[derive(Parser)]
#[command(name = "app", version = env!("CARGO_PKG_VERSION"))]
struct Cli {
    #[command(subcommand)] command: Option<Commands>,
    #[arg(long, global = true)] debug: bool,
}
#[derive(Subcommand)]
enum Commands { Init { #[arg(long)] force: bool }, Serve }
```

### lib.rs Re-exports
```rust
pub mod error; pub mod client;
pub use error::{AppError, Result};
pub use client::Client;
```

### Logging
```rust
use tracing::{debug, error, info, warn};
info!("started"); warn!("retry {attempt}"); error!("{err}");
```

---

## Python

### Structure
```
package/
├── __init__.py  ├── base.py  ├── payment.py  └── utils.py
Tests/
└── test_general.py
```

### Rules
- Shebang: `#!/usr/bin/env python`
- **2-space indent** (deliberate)
- Type hints on every method signature
- Docstrings with `Args:` / `Returns:` on every public method
- `@staticmethod` for pure utilities

### Base + Subclass + Accumulator
```python
class SSLCommerz:
  def __init__(self, is_sandbox: bool = True) -> None:
    self.integration_data: Dict[str, str] = {}

class SSLCSession(SSLCommerz):
  def set_customer_info(self, name: str, email: str) -> None:
    self.integration_data.update({'cus_name': name, 'cus_email': email})

  def init_payment(self) -> Dict:
    return requests.post(self.session_api, self.integration_data).json()
```

---

## PHP

### WordPress Plugins

#### Plugin Header + Security Guard
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

#### Complex Plugin: `final` Singleton
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

#### Minimal Plugin: Direct `new`
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

#### `final class Init` Per Feature
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

#### `private const` for Config + Status Maps
```php
private const STATUS_MAP = ['VALID' => 'paid', 'FAILED' => 'failed', 'CANCELLED' => 'cancelled'];
private function mapStatus(string $s): string { return self::STATUS_MAP[$s] ?? 'failed'; }
```

#### WP HTTP API (not curl/Guzzle)
```php
$response = wp_remote_post($url, ['timeout' => 60, 'sslverify' => !$isSandbox, 'body' => $data]);
if (is_wp_error($response)) return ['status' => 'FAILED', 'reason' => $response->get_error_message()];
$code = wp_remote_retrieve_response_code($response);
$body = wp_remote_retrieve_body($response);
```

#### Input + i18n
```php
// Sanitize all $_POST
$val = sanitize_text_field(wp_unslash($_POST['key']));
// All user-facing strings
throw new \InvalidArgumentException(__('Order ID required', 'myplugin'));
```

#### Error Handling
```php
// Catch Throwable not Exception (PHP 7+)
try { $this->process($data); } catch (Throwable $e) {
    if (defined('WP_DEBUG') && WP_DEBUG) error_log('Error: ' . $e->getMessage());
    $result->status = 'failed'; $result->reason = $e->getMessage(); return $result;
}
// Validate early
if (empty($data->order_id)) throw new \InvalidArgumentException(__('Order ID required', 'myplugin'));
```

#### Vue 3 + Vite Admin UI
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

#### Plugin Structures
```
# Complex:                          # Minimal:
plugin/                             plugin/
├── plugin.php (singleton)          └── plugin.php (header + new ClassName())
├── integration/Init.php
├── payments/Provider/Provider.php
├── assets/
└── vendor/
```

---

### PHP CLI (Symfony Console)

#### Structure
```
tool/
├── bin/toolname        # #!/usr/bin/env php entry
├── src/
│   ├── Commands/       # one class per command
│   └── Extensions/     # custom Application
└── composer.json       # "bin": ["bin/toolname"]
```

#### CLI Entry
```php
#!/usr/bin/env php
<?php
set_time_limit(0);

foreach ([__DIR__.'/../../vendor/autoload.php', __DIR__.'/../../../../autoload.php', 'vendor/autoload.php'] as $f) {
    if (file_exists($f)) { require $f; break; }
}

$app = new ToolApplication('My CLI', 'v1.0.0');
$app->add(new InstallCommand);
$app->run();
```
`composer.json`: `"bin": ["bin/toolname"]`, `"require": {"symfony/console": "^5.2"}`

#### Custom Application: Strip Unused Options
```php
class ToolApplication extends Application {
    protected function getDefaultInputDefinition(): InputDefinition {
        return new InputDefinition([
            new InputArgument('command', InputArgument::REQUIRED, 'Command'),
            new InputOption('--help', '-h', InputOption::VALUE_NONE, 'Help'),
        ]);
    }
}
```

#### Command Pattern
```php
class InstallCommand extends Command {
    const Q_INPUT = 1; const Q_CONFIRM = 2; const Q_CHOICE = 3;
    private $input; private $output;

    protected function configure(): void {
        $this->setName('install')->setDescription('Install project')
             ->addArgument('name', InputArgument::REQUIRED, 'Name');
    }
    protected function execute(InputInterface $input, OutputInterface $output): int {
        $this->input = $input; $this->output = $output;
        $name = $this->ask('Project name:', self::Q_INPUT, 'myproject');
        if ($this->ask('Proceed?', self::Q_CONFIRM) === 'yes') {
            $output->writeln('Installing...');
        }
        return Command::SUCCESS;
    }
    private function ask(string $q, int $type, string $default = '', array $opts = []): string {
        $helper = $this->getHelper('question');
        $question = match($type) {
            self::Q_INPUT   => new Question($q, $default),
            self::Q_CONFIRM => new ChoiceQuestion($q, ['yes','no'], $default),
            self::Q_CHOICE  => new ChoiceQuestion($q, $opts, $default),
        };
        return $helper->ask($this->input, $this->output, $question);
    }
}
```
`$output->writeln()`, never `echo`. Return `Command::SUCCESS`/`Command::FAILURE`.

#### Cross-Platform + State
```php
$isWindows = in_array(PHP_OS, ['WIN32', 'Windows', 'WINNT']);
passthru($isWindows ? "php -S {$domain}:80" : "sudo php -S {$domain}:80 -t {$domain}/");

// State as JSON
file_put_contents("{$name}.json", json_encode(['domain' => $domain], JSON_PRETTY_PRINT));
if (file_exists("{$name}.json")) { /* already exists */ }
```

---

### Laravel Packages

#### Structure
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

#### ServiceProvider
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

#### Config-Driven
```php
$model = config('package.user_model', 'App\\Models\\User');
$roles = config('package.admin_roles', ['admin', 'super-admin']);
$disk  = config('package.uploads.disk', 'public');
```

#### Abstract BaseController
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

#### HasCrud Concern
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

#### Routes
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

#### Granular Publishing
```php
$this->publishes([__DIR__.'/../../config/package.php' => config_path('package.php')], 'package-config');
$this->publishes([$views => resource_path('views/vendor/package')], 'package-views');
$this->publishes([$views.'/partials/styles.blade.php' => ...], 'package-styles');
// + combined 'package' group
```

#### Middleware + View Composers + Commands
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

#### Naming
- Classes: `PascalCase` + role, as in `ResourceController`, `EnsureIsAdmin`, `HasCrud`
- Config keys: `kebab-case.dot.notation`, as in `package.admin_roles`
- Blade: `kebab-case.blade.php` namespaced, as in `package::partials.flash-messages`
- PHPDoc `@param`/`@return` on every public method

---

## Writing Like a Human

Every character that ships is text someone reads: comments, doc comments, README and docs, commit messages, PR bodies, error strings, CLI output, variable names, test names. All of it should read as if dreygur typed it. Generated-sounding prose is as much a defect as a swallowed error.

### 1. No Em Dashes
Never `—`. Not in code, comments, commits, docs, PR bodies, or chat about the work. It is the loudest machine tell there is.

Rewrite instead:

| Instead of | Write |
|---|---|
| `token expired — refresh first` | `token expired, refresh first` |
| `Two modes — sandbox and live` | `Two modes: sandbox and live` |
| `It fails silently — the caller never knows` | `It fails silently. The caller never knows.` |
| `The retry — when enabled — wraps fetch` | `The retry, when enabled, wraps fetch` |

Comma, colon, semicolon, parentheses, or a full stop. One of those always fits.

Also out: `–` (en dash) outside numeric ranges, ` -- ` standing in for an em dash, `…` (write three periods, or nothing), curly quotes `“” ‘’` anywhere near code or config.

### 2. Cut the Stock Vocabulary
These words are not wrong, they are just what a model reaches for first. Reach past them.

| Avoid | Use |
|---|---|
| delve into, dive into, explore | look at, read, check |
| leverage, utilize | use |
| robust, comprehensive, powerful | say what it actually does |
| seamless, effortless, elegant | drop the adjective |
| ensure that | make sure, or just the imperative |
| it's worth noting, it's important to note | state the thing |
| crucial, vital, essential | needed, required, or drop it |
| in order to | to |
| a wide range of, a variety of | name the range |
| unlock, elevate, streamline, supercharge | describe the change |
| additionally, furthermore, moreover | and, also, or start the sentence |

### 3. No Antithesis Reflex
Stop reaching for the contrast frame. `not just X, but Y`, `it isn't A, it's B`, `X isn't about A. It's about B.` Once in a long document is fine. Twice in a paragraph is a signature.

```
// wrong
// This isn't a cache, it's a coalescer.
// right
// Coalesces concurrent refreshes so only one request goes out.
```

### 4. No Padding
- No preamble restating the question or the task.
- No closing paragraph summarizing what the reader just read.
- No "Overview" / "Conclusion" / "Key Takeaways" headings on a document under two pages.
- No hedging stack: pick a position, or say plainly that it depends and on what.
- No apology or self-congratulation in commits, comments, or docs.

### 5. Vary the Shape
Uniform output reads generated even when every word is fine.

- Do not make every list exactly three items.
- Do not give every bullet a bolded lead-in and a colon.
- Do not open consecutive sentences with the same construction.
- Mix sentence lengths. A short one lands harder after a long one.
- Prose is allowed. Not every explanation needs to become a table or a bullet list.

### 6. No Emoji, No Decoration
None in code, comments, commit messages, docs, or CLI output. The log prefixes `[+]` `[-]` `[!]` `[*]` are the whole visual vocabulary. No checkmark bullets, no banner ASCII art, no `🚀` in a README.

### 7. Comments Are Notes, Not Narration
A comment records why, or a constraint that is not visible in the code. It never restates the line below it, and it never announces structure (see The Shape of a File, rule 5).

```go
// wrong
// Loop over the users and send each one an email.
for _, u := range users { ... }

// right
// bKash rate-limits to 5 req/s per app key; batching keeps us under it.
for _, batch := range chunk(users, 5) { ... }
```

Write them in the same clipped register as the code. Sentence fragments are fine. Trailing periods optional, but stay consistent within a file.

### 8. Commit Messages Sound Like a Person
- Imperative mood, present tense: `fix token refresh race`, not `Fixed` or `Fixes`.
- Say what changed and, when it is not obvious, why. Skip the body entirely for a one-line change.
- Never `This commit ...`, never a bulleted essay for a two-line diff, never a "Summary of changes" heading.
- No em dashes in the subject or body.
- No agent attribution of any kind (see Commits & Attribution).

```
# wrong
feat: implement a comprehensive solution for token refresh — ensures seamless auth

# right
fix: coalesce concurrent token refreshes

Two requests racing on an expired token each triggered a refresh and the
second overwrote the first. Guard with the shared mutex.
```

### 9. Docs Assume a Reader With the Repo Open
Skip the marketing paragraph. Skip "In today's fast-paced world". Open with what the thing does and the first command that runs it. Show real values in examples, not `foo` and `bar`. If a section only exists because documents usually have one, delete it.

### 10. Identifiers and Strings Carry the Same Rule
No thesaurus names (`orchestrateComprehensiveSync`). Name it what it does: `syncPlaylist`. Error messages state the failure and the input, with no apology and no exclamation mark: `invalid order id: %q`, not `Oops! Something went wrong with the order!`.

---

## Reviewing Code: Flag These

- Missing types/interfaces for exported items
- DB calls in handlers (wrong layer)
- Raw error strings instead of typed errors
- Magic values not in constants
- Swallowed errors (`catch {}`, ignored `Result`, `except: pass`)
- Missing doc comments on exports
- Wrong filename casing
- Missing TS/JS semicolons
- 4-space indent in Python
- Raw `console.log`/`print`/`println!` in library code
- Services instantiated per-call instead of singleton export
- `$_POST` without sanitization in PHP
- Missing `defined('ABSPATH') || exit` in WP files
- Helper defined *below* its caller
- Constants buried mid-file instead of at the top
- Section-divider or block-label comments (`// ---- Helpers ----`)
- Casts that silence the type checker (`as any`, `/** @type {X} */ (expr)`)
- New function with no test that actually runs it
- Test doubles named `fake_*` instead of `mock_*`
- Any AI/agent attribution in commits, comments, or docs
- Em dash anywhere: code, comment, doc, commit, PR body
- Curly quotes, en dashes, or `...` characters in text
- Stock model vocabulary (delve, leverage, robust, seamless, ensure that, it's worth noting)
- `not just X, but Y` phrasing, or any repeated antithesis frame
- Comment that restates the line below it
- Commit subject in past tense, or a bulleted essay on a two-line diff
- Emoji in code, commits, docs, or CLI output
- Preamble or a summary paragraph on a doc that does not need one

## Commits & Attribution

- **Never** add agent attribution anywhere. No `Co-Authored-By: Claude`, no "Generated with Claude Code", no robot footers. Not in commit messages, PR bodies, code comments, or docs. The history reads as dreygur's own work. Where the repo supports it, set `attribution.commit` and `attribution.pr` to `""` in `.claude/settings.json` rather than relying on memory.
- Finish every outstanding request **before** committing. A commit is a checkpoint; reaching it with an open ask captures the wrong state.
- No unrequested edits to `README` files. Requested prose goes in chat unless a file is named.

## Additional Resources
- **`references/patterns.md`**: extended patterns and anti-patterns per language, including before/after rewrites for machine-sounding prose
