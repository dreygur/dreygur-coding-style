---
name: dreygur-coding-style
description: This skill should be used when writing any code for dreygur — Go, TypeScript, JavaScript, Rust, Python, or PHP/Laravel. Use when the user asks to "write code in my style", "follow my coding patterns", "use my architecture", "create a new project", "add a service", "add a repository", "write a handler", or whenever generating code that should match dreygur's established patterns. Also use when reviewing existing code for style violations.
version: 2.5.0
---

# dreygur Coding Style Guide

Derived empirically from dreygur's open-source projects across Go, TypeScript, Rust, Python, and PHP/Laravel. Apply these rules silently when writing code, call out style decisions when they're non-obvious, and flag violations when reviewing code.

## Universal Rules (All Languages)

These apply regardless of language or stack. Never break them.

### 1. Types / Interfaces First

Define contracts before implementations. Types live in a dedicated file:
- TypeScript/JS: `types.ts`
- Go: `models/requests.go`, `models/responses.go`
- Rust: `crates/*/src/lib.rs` or a `types.rs`
- Python: base class or dataclasses before subclasses
- PHP: interface files or abstract base classes in `src/Contracts/` or `src/Support/`

### 2. Service Provider / Clean Architecture

Always layer code into:

| Layer | TS/JS | Go | Rust | Python | PHP |
|---|---|---|---|---|---|
| Types/Models | `types.ts`, `models/` | `models/` | `types.rs`, structs | base class / dataclasses | `src/Support/`, Eloquent models |
| Services | `*.service.ts` | `methods/`, `api/` | `src/*/manager.rs` | class methods | `src/Services/` |
| Repositories | `*.repository.ts` | `db/`, `repo/` | `src/*/store.rs` | class with DB methods | Eloquent + Concerns |
| Handlers/Controllers | `*.handler.ts` | `handlers/`, `cmds/` | `src/cli/` | route functions | `src/Http/Controllers/` |
| Middleware/Hooks | `*.middleware.ts` | `hooks/` | `src/*/middleware.rs` | decorators / wrappers | `src/Http/Middleware/` |
| Strategies | `*.strategy.ts` | (pattern in methods/) | `src/*/strategy.rs` | — | — |
| Utils | `utils/` | `utils/`, `lib/` | `src/util/` | helpers | `src/Support/` |
| Config/Constants | `config.ts`, `constants.ts` | `common/vars.go`, `lib/settings.go` | `src/config/` | `constants.py` | `config/*.php` |

### 3. Custom Error Hierarchy

Never use raw strings or generic errors. Every project has typed errors with context.

- TypeScript: class hierarchy extending `Error` (see TS section)
- Go: sentinel error variables (`var ErrEmptyRequiredField = errors.New(...)`)
- Rust: `thiserror` enum (see Rust section)
- Python: custom exception classes extending `Exception`

### 4. Singleton Service/Repository Exports

Export initialized instances, not just classes:

```ts
// TS
export const tokenService = new TokenService();
export const credentialRepository = new CredentialRepository();
```
```go
// Go
var Collection = &db.MongoDB{ Address: os.Getenv("DB_URI"), ... }
```

### 5. Leveled Structured Logging

Always use a proper logging abstraction with levels. Never raw `print`/`console.log` in library code:

| Language | Tool | Levels |
|---|---|---|
| Go | custom `PrintLog` + `fatih/color` | `[+]` info, `[-]` error, `[!]` warn, `[*]` default |
| TypeScript | `debugLog`, `infoLog`, `warnLog` wrappers | debug / info / warn |
| Rust | `tracing` crate | `info!`, `warn!`, `error!`, `debug!` |
| Python | stdlib `logging` or custom | DEBUG / INFO / WARNING / ERROR |

### 6. Config and Constants in Dedicated Files

No magic strings or numbers inline. Constants go in `constants.ts` / `common/vars.go` / `src/config/` / `consts.rs`. Config loading goes in `config.ts` / `lib/configparser.go` / `src/config/mod.rs`.

### 7. Never Swallow Errors

Always propagate errors upward with context. No silent catches, no empty `catch {}`, no ignored `Result`s.

### 8. Proper Comments

- Every exported item gets a doc comment
- Comment the *why*, not the *what*
- Use the language's standard doc format (see per-language sections)

### 9. Filename Conventions

- **TypeScript/JavaScript**: `kebab-case.ts`, with layer suffix — `token.service.ts`, `credential.repository.ts`, `auth.middleware.ts`, `oauth.strategy.ts`
- **Go**: `snake_case.go` or lowercase — `requests.go`, `token.go`, `cmd_handler.go`
- **Rust**: `snake_case.rs` — `error.rs`, `oauth_discovery.rs`, `config_watcher.rs`
- **Python**: `snake_case.py` — `base.py`, `payment.py`, `validation.py`

---

## TypeScript / JavaScript

### Project Structure

```
src/
├── index.ts              # barrel: re-exports everything
├── types.ts              # all shared interfaces and types
├── constants.ts          # all constants
├── config.ts             # config loading
├── errors.ts             # custom error class hierarchy
├── validation.ts         # input validation functions
├── services/
│   └── token.service.ts
├── repositories/
│   └── credential.repository.ts
├── strategies/
│   └── oauth.strategy.ts
├── middleware/
│   ├── auth.middleware.ts
│   └── rate-limit.middleware.ts
├── handlers/             # or controllers/
│   └── cmd.handler.ts
└── utils/
    ├── logger.ts
    └── mutex.ts
tests/
├── token.test.ts
└── validation.test.ts
```

### Error Classes

Always a base error class + typed subclasses with `code`, `recoverable`, and `userMessage`:

```ts
export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public recoverable: boolean = true,
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

export class ValidationError extends AppError {
  constructor(message: string, field?: string) {
    super(message, "VALIDATION_ERROR", false, field ? `Invalid ${field}: ${message}` : message);
    this.name = "ValidationError";
  }
}
```

### Type Guards and Utilities on Errors

```ts
export function isRecoverableError(error: unknown): boolean {
  return error instanceof AppError ? error.recoverable : false;
}

export function getUserMessage(error: unknown): string {
  if (error instanceof AppError && error.userMessage) return error.userMessage;
  if (error instanceof Error) return error.message;
  return "An unexpected error occurred";
}
```

### Semicolons

**Always use semicolons.** No exceptions.

### Imports

Use `import type` for type-only imports:

```ts
import type { Plugin, PluginInput } from "@opencode-ai/plugin";
import { TokenService } from "./services/token.service.js";
```

### Barrel Exports

`index.ts` re-exports everything:

```ts
export * from "./services/token.service.js";
export * from "./repositories/credential.repository.js";
export * from "./types.js";
export * from "./errors.js";
```

### Async

`async/await` everywhere. Never raw `.then()/.catch()` chains unless there is a specific reason.

### Log Prefix Convention (even without a logger utility)

The `[+] / [-] / [!]` prefix notation carries over from Go even in plain JS/TS scripts:

```ts
console.log(`[+] Waiting for new pair creation...`);
console.log(`[-] ${err.message}`);
console.log(`[+] Received signal: ${signal} Exiting...`);
```

### Graceful Shutdown in Node.js Scripts

```ts
process.on('SIGINT', (signal) => {
  console.log(`[+] Received signal: ${signal} Exiting...`);
  process.exit(0);
});

process.on('SIGHUP', (signal) => {
  console.log(`[+] Received signal: ${signal} Exiting...`);
  process.exit(0);
});
```

### Script Entry Point (IIFE)

For standalone scripts, wrap the async entry in an IIFE:

```ts
(async () => await main())();
```

### Default Object Merging

```ts
const defaults: TradeObj = { stake: "1", marketID: 17068, isKaazingFeed: true };
return request("RequestTrade", cookie, Object.assign(defaults, overrides));
```

### Naming

- Classes: `PascalCase` + suffix — `TokenService`, `CredentialRepository`, `OAuthStrategy`, `AuthMiddleware`
- Instances: `camelCase` — `tokenService`, `credentialRepository`
- Interfaces/Types: `PascalCase` — `StoredCredentials`, `TokenResponse`, `OAuthAuthDetails`
- Files: `kebab-case` + layer suffix — `token.service.ts`
- Constants: `SCREAMING_SNAKE_CASE`

### JSDoc Comments

Every exported function, class, and interface:

```ts
/**
 * Refreshes the access token if it is expired or about to expire.
 * Uses a mutex to prevent concurrent refresh races.
 */
async refreshIfNeeded(): Promise<OAuthAuthDetails> {
```

### Branded Types for Entity IDs

Use `Brand<T, 'Name'>` to prevent accidental ID type confusion. Zero runtime cost — erased at compile time.

```ts
export type Brand<T, Brand extends string> = T & { __brand: Brand };

export function asBrand<T extends Brand<any, any>>(value: any): T {
  return value as T;
}

export function assertValidId<T extends Brand<string, any>>(
  value: unknown,
  idType: string,
): T {
  if (!isValidUUID(value)) {
    throw new Error(`Invalid ${idType}: expected UUID format, got ${typeof value === 'string' ? value : typeof value}`);
  }
  return value as T;
}

// Define one branded type per entity
export type UserId = Brand<string, 'UserId'>;
export type OrganizationId = Brand<string, 'OrganizationId'>;
```

Never use plain `string` for entity IDs in function signatures — always use the specific branded type.

### Drizzle ORM Schema Pattern

Co-locate type exports and Zod schemas with the table definition:

```ts
import { pgTable, varchar, uuid, boolean } from 'drizzle-orm/pg-core';
import { createInsertSchema, createSelectSchema, createUpdateSchema } from 'drizzle-zod';
import { timestamps } from './utils';

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

### Base Repository Pattern

Abstract generic base with typed IDs, soft delete, and transaction support:

```ts
export abstract class BaseRepository<
  T extends AnyPgTable & { id: any },
  TId extends string = string,
> {
  constructor(
    protected readonly db: NodePgDatabase,
    protected readonly table: AnyPgTable & { id: any },
  ) {}

  async findById(id: TId): Promise<T['$inferSelect']> { ... }
  async create(data: Partial<T['$inferInsert']>): Promise<TId> { ... }
  async update(id: TId, values: Partial<T['$inferInsert']>): Promise<TId> { ... }

  // Soft delete — never hard delete
  async delete(id: TId, tx?: ConnectionType) {
    const db = tx ?? this.db;
    return db.update(this.table).set({ deleted: true } as any)
      .where(eq(this.table.id, id as string)).execute();
  }

  async restore(id: TId, tx?: ConnectionType) {
    const db = tx ?? this.db;
    return db.update(this.table).set({ deleted: false } as any)
      .where(eq(this.table.id, id as string)).execute();
  }

  async withTransaction<T>(fn: (tx: ConnectionType) => Promise<T>): Promise<T> {
    return this.db.transaction(fn as any);
  }
}
```

Key rules: always soft delete (set `deleted: true`), accept optional `tx?: ConnectionType` on mutating methods, use `withTransaction` for multi-step operations.

### tRPC Setup

```ts
export const t = initTRPC
  .context<Context>()
  .meta<OpenApiMeta>()
  .create({
    transformer: superjson,
    errorFormatter: ({ shape }) => ({
      ...shape,
      data: {
        ...shape.data,
        stack: process.env.NODE_ENV === 'development' ? shape.data?.stack : undefined,
      },
    }),
  });

export const router = t.router;
export const middleware = t.middleware;
export const createCallerFactory = t.createCallerFactory;
```

### Project-Prefixed Error Classes

Name error classes with the project prefix to avoid collisions:

```ts
export class PoachApiError extends Error {
  public success: boolean;
  public operational: boolean;
  constructor(message: string, success = false, operational = true, stack = '') {
    super(message);
    this.name = 'PoachApiError';
    this.success = success;
    this.operational = operational;
    if (stack) this.stack = stack;
    else Error.captureStackTrace(this, this.constructor);
  }
}

export class PTRPCError extends TRPCError {
  public timestamp: Date;
  public requestId?: string;
  constructor(params: ConstructorParameters<typeof TRPCError>[0] & { requestId?: string }) {
    super(params);
    this.timestamp = new Date();
    this.requestId = params.requestId;
  }
}
```

### Winston Logger with Custom Levels

Extend Winston with a custom level, module augmentation, and a DB transport helper:

```ts
import winston from 'winston';

declare module 'winston' {
  interface Logger {
    db(message: string | Error, ...meta: any[]): Logger;
  }
}

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

Large full-stack TypeScript projects use Turborepo + pnpm workspaces:

```
project/
├── apps/
│   ├── api/          # Express + tRPC
│   └── ui/           # Next.js App Router
├── packages/
│   ├── schema/       # Drizzle ORM tables + drizzle-zod schemas
│   ├── repository/   # BaseRepository + per-entity repos
│   ├── service/      # per-entity *.service.ts
│   ├── trpc/         # tRPC router + context + middleware
│   ├── shared/       # branded-types, errors, constants, permissions
│   ├── validator/    # Zod validators per entity
│   ├── logger/       # Winston logger
│   ├── email/        # email with provider pattern
│   └── telemetry/    # OpenTelemetry
├── cdk/              # AWS CDK infra (if cloud-deployed)
├── turbo.json
└── pnpm-workspace.yaml
```

Package naming: `@projectname/schema`, `@projectname/repository`, etc.

---

## Go

### Project Structure

**Libraries** — flat package layout:
```
project/
├── main.go               # or bin/main.go
├── go.mod / go.sum
├── Makefile
├── sample.env            # or sample_config.json — never commit secrets
├── models/
├── methods/
│   ├── interface.go
│   └── token.go
├── hooks/
├── handlers/
├── events/
├── lib/
├── utils/
├── db/
└── tests/
```

**Applications** — `internal/` layout:
```
project/
├── main.go
├── go.mod / go.sum
├── Makefile
├── .env.example
└── internal/
    ├── models/      # shared types
    ├── config/      # config loading
    ├── ai/          # service layer (generator, providers)
    ├── discord/     # handler/bot layer
    ├── google/      # external API client
    ├── store/       # repository layer
    └── worker/      # background workers
```

### Interface First

```go
// methods/interface.go
type BkashService interface {
    GetToken() (*models.TokenResponse, error)
    CreatePayment(*models.CreateRequest, *models.TokenResponse) (*models.CreatePaymentResponse, error)
}

// methods/token.go
type Bkash struct {
    AppKey      string
    AppSecret   string
    IsLiveStore bool
    debug       bool
}

func (b *Bkash) GetToken() (*models.TokenResponse, error) { ... }
```

### Constructor Returns Interface

```go
func GetBkash(username, password, appKey, appSecret string, isLive bool) methods.BkashService {
    return &methods.Bkash{ AppKey: appKey, IsLiveStore: isLive }
}
```

### Error Handling

Validate early with sentinel errors. Wrap errors with context using `%w`:

```go
if !utils.RequireNonEmpty(b.AppKey, b.AppSecret) {
    return nil, common.ErrEmptyRequiredField
}

reviews, err := p.googleClient.GetReviews(ctx)
if err != nil {
    return fmt.Errorf("fetch reviews: %w", err)
}

if err := p.discordBot.SendApprovalRequest(approval); err != nil {
    return fmt.Errorf("send discord notification: %w", err)
}
```

Use bare `return nil, err` when no context is needed; use `fmt.Errorf("context: %w", err)` when the call site adds meaningful information.

### Typed String Constants

Use typed string constants instead of plain strings for domain statuses and kinds:

```go
type ApprovalStatus string

const (
    StatusPending  ApprovalStatus = "pending"
    StatusApproved ApprovalStatus = "approved"
    StatusRejected ApprovalStatus = "rejected"
    StatusExpired  ApprovalStatus = "expired"
)
```

### Constructors That Can Fail

When initialization involves I/O or validation, return `(*Type, error)`:

```go
func NewBot(token, channelID string, allowedUsers []string) (*Bot, error) {
    session, err := discordgo.New("Bot " + token)
    if err != nil {
        return nil, fmt.Errorf("create discord session: %w", err)
    }
    return &Bot{session: session, channelID: channelID}, nil
}
```

### Concurrent-Safe Structs

Embed `sync.Mutex` or `sync.RWMutex` directly in structs that are shared across goroutines:

```go
type Bot struct {
    session        *discordgo.Session
    mu             sync.RWMutex
    pendingReviews map[string]*models.PendingApproval
}

func (b *Bot) isUserAllowed(userID string) bool {
    b.mu.RLock()
    defer b.mu.RUnlock()
    return b.allowedUsers[userID]
}
```

### Primary + Fallbacks Pattern

For pluggable providers, store a primary and an ordered fallback list:

```go
type Generator struct {
    providers map[string]Provider
    primary   string
    fallbacks []string
}

// Try primary first, then each fallback in order
providerOrder := append([]string{g.primary}, g.fallbacks...)
for _, name := range providerOrder {
    resp, err := providers[name].Generate(ctx, req)
    if err == nil {
        return resp, nil
    }
}
```

### Map-Based Command Dispatch

```go
var CommandHandlers = map[string]func(s *discordgo.Session, i *discordgo.InteractionCreate){
    "help":    Help,
    "points":  Points,
}
if fn, ok := CommandHandlers[name]; ok { fn(s, i) }
```

### Graceful Shutdown

```go
sig := make(chan os.Signal, 1)
signal.Notify(sig, os.Interrupt)
<-sig
defer dg.Close()
defer repo.Collection.Close()
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

### Doc Comments

```go
// Package hooks provides the methods for making requests to the Bkash API.
package hooks

// GetToken creates an access token using bkash credentials.
func (b *Bkash) GetToken() (*models.TokenResponse, error) {
```

---

## Rust

### Workspace Structure

```
project/
├── Cargo.toml            # workspace manifest
├── Cargo.lock
├── src/                  # or crates/
│   ├── main.rs           # #[tokio::main] async fn main
│   ├── lib.rs            # re-exports: pub use module::Type;
│   ├── error.rs          # thiserror enum + Result alias
│   ├── config/
│   │   └── mod.rs
│   └── module/
│       ├── mod.rs
│       └── submodule.rs
└── crates/
    └── crate-name/
        ├── Cargo.toml
        └── src/
            ├── lib.rs
            └── error.rs
```

### Error Types (Always `thiserror`)

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Transport error: {0}")]
    Transport(String),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Connection failed: {0}")]
    Connection(String),
}

pub type Result<T> = std::result::Result<T, AppError>;
```

`anyhow::Result` only in `main.rs` / binary entry points. Library crates use the typed `Result` alias.

### Module Docs

```rust
//! MCP Connect CLI - Bridge local MCP clients to remote MCP servers.

/// Initializes a new WebDriver session and returns the driver handle.
pub fn init() -> Driver {
```

### Error Type in Binaries

Both `anyhow::Result` and `eyre::Result` are acceptable in binary entry points — use whichever fits the project's existing dependency:

```rust
// anyhow
#[tokio::main]
async fn main() -> anyhow::Result<()> { ... }

// eyre (preferred in newer projects)
#[tokio::main]
async fn main() -> eyre::Result<()> { ... }
```

### Shared State with Arc

Always use `Arc::clone(&x)` explicitly (not `.clone()`) when sharing across tasks:

```rust
let store = Arc::new(Store::new());
let config = Arc::new(Config::from_args());

tokio::spawn(async move {
    let store = Arc::clone(&store);
    server::handle_connection(stream, store, config).await
});
```

### Concurrent Events with tokio::select!

```rust
loop {
    tokio::select! {
        Some(event) = device_events.next() => { ... }
        Some((addr, change)) = all_change_events.next() => { ... }
        _ = sleep(Duration::from_secs(30)) => { /* periodic update */ }
    }
}
```

### CLI with Clap

```rust
#[derive(Parser)]
#[command(name = "app", about = "Description", version = env!("CARGO_PKG_VERSION"))]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
    #[arg(long, global = true)]
    debug: bool,
}

#[derive(Subcommand)]
enum Commands {
    Init { #[arg(long)] force: bool },
    Serve,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    // match and dispatch
}
```

### Async State

```rust
pub struct Client {
    transport: Arc<Mutex<Option<Box<dyn Transport>>>>,
    initialized: Arc<Mutex<bool>>,
}
```

### Logging with Tracing

```rust
use tracing::{debug, error, info, warn};

info!("Server started");
warn!("Connection retry {attempt}");
error!("Fatal: {err}");
```

### lib.rs Re-exports

```rust
pub mod error;
pub mod client;
pub mod transport;

pub use error::{AppError, Result};
pub use client::Client;
```

### Constructor / Builder Pattern

```rust
impl ZK {
    pub fn new(ip: &str, port: u16) -> Self {
        Self {
            ip: ip.to_string(),
            port,
            timeout: Duration::from_secs(60),
            ..Default::default()
        }
    }
}
```

---

## Python

### Project Structure

```
package_name/
├── __init__.py
├── base.py           # base class / shared state
├── payment.py        # domain logic subclass
├── validation.py     # validation helpers
└── utils.py
Tests/
├── __init__.py
└── test_general.py
requirements.txt
pyproject.toml
```

### Shebang

```python
#!/usr/bin/env python
```

### Indentation

**2 spaces** (not 4). This is a deliberate choice.

### Type Hints Everywhere

```python
from typing import Dict, Optional
from decimal import Decimal

def set_product_integration(
  self,
  total_amount: Decimal,
  currency: str,
  product_name: str,
  num_of_item: int,
) -> None:
```

### Docstrings

Every method gets a docstring with `Args:` and `Returns:` sections:

```python
def set_sslcommerz_mode(sslc_is_sandbox: bool) -> str:
  """Set status of the api whether sandbox or live.

  Args:
    sslc_is_sandbox (bool): True for sandbox, False for live.

  Returns:
    str: 'sandbox' or 'securepay'
  """
```

### Base Class + Subclass

```python
class SSLCommerz:
  def __init__(self, is_sandbox: bool = True, store_id: str = '') -> None:
    self.integration_data: Dict[str, str] = {}

class SSLCSession(SSLCommerz):
  def __init__(self, is_sandbox: bool = True, store_id: str = '') -> None:
    super().__init__(is_sandbox, store_id)
```

### Builder / Accumulator Pattern

Accumulate state via `dict.update()`, execute at the end:

```python
def set_customer_info(self, name: str, email: str, ...) -> None:
  self.integration_data.update({
    'cus_name': name,
    'cus_email': email,
  })

def init_payment(self) -> Dict:
  response = requests.post(self.session_api, self.integration_data)
  ...
```

### `@staticmethod` for Pure Utilities

```python
@staticmethod
def set_mode(is_sandbox: bool) -> str:
  return 'sandbox' if is_sandbox else 'securepay'
```

---

## PHP

### WordPress Plugins

#### Plugin File Header

Every WP plugin starts with the standard header block + security guard:

```php
<?php
/**
 * Plugin Name:    MyPlugin
 * Plugin URI:     https://github.com/user/myplugin
 * Description:    One-line description.
 * Version:        1.0.0
 * Author:         Name
 * Author URI:     https://github.com/user
 * License:        GPLv2 or later
 * Text Domain:    myplugin
 * Domain Path:    /languages
 */

defined('ABSPATH') || exit;
```

`defined('ABSPATH') || exit` — top of **every** PHP file in a plugin.

#### Main Plugin Class (Singleton)

Main class is `final`, uses a `get_instance()` singleton, private constructor, and splits `init()` into private methods:

```php
final class MyPlugin {
    private static $instance = null;

    public static function get_instance(): self {
        if (null === self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function __construct() {
        $this->init();
    }

    private function init(): void {
        $this->load_dependencies();
        $this->define_constants();
        $this->init_hooks();
    }

    private function load_dependencies(): void {
        require_once __DIR__ . '/vendor/autoload.php';
    }

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

#### Separate Init Class Per Feature

`final class Init` for each feature — registers all hooks/filters in its constructor:

```php
final class Init {
    public function __construct() {
        add_filter('plugin_gateways', [self::class, 'add_gateways']);
        add_filter('plugin_payment_methods', [$this, 'add_payment_method'], 100);
        add_action('init', [$this, 'process_form_submission']);
    }
}
```

#### Constants for Config and Status Maps

Use `private const` arrays for config groups and status mappings — never inline strings:

```php
private const GATEWAY_CONFIG = [
    'sslcommerz' => [
        'gateway_class' => SslcommerzGateway::class,
        'config_class'  => SslcommerzConfig::class,
    ],
];

private const STATUS_MAP = [
    'VALID'     => 'paid',
    'VALIDATED' => 'paid',
    'FAILED'    => 'failed',
    'CANCELLED' => 'cancelled',
    'PENDING'   => 'pending',
];

private function mapStatus(string $status): string {
    return self::STATUS_MAP[$status] ?? 'failed';
}
```

#### WordPress HTTP API (not curl/Guzzle)

Always `wp_remote_post()` / `wp_remote_get()` for HTTP in plugins. Check `is_wp_error()` first:

```php
$response = wp_remote_post($url, [
    'timeout'     => 60,
    'httpversion' => '1.1',
    'sslverify'   => !$isSandbox,
    'body'        => $data,
]);

if (is_wp_error($response)) {
    return ['status' => 'FAILED', 'reason' => $response->get_error_message()];
}

$code = wp_remote_retrieve_response_code($response);
$body = wp_remote_retrieve_body($response);
```

#### Input Sanitization

Always `sanitize_text_field(wp_unslash($value))` on incoming POST data — never use raw `$_POST`:

```php
$sanitized = [];
foreach ($_POST as $key => $value) {
    $sanitized[$key] = is_array($value)
        ? array_map('sanitize_text_field', array_map('wp_unslash', $value))
        : sanitize_text_field(wp_unslash($value));
}
```

#### i18n — All User-Facing Strings

Every user-facing string through `__('String', 'text-domain')`. Never raw string literals in output:

```php
throw new \InvalidArgumentException(__('Order ID is required', 'myplugin'));
$label = __('Store Password', 'myplugin');
```

#### Debug Logging Gated on WP_DEBUG

```php
if (defined('WP_DEBUG') && WP_DEBUG) {
    error_log('MyPlugin error: ' . $error->getMessage());
}
```

#### Catch Throwable, Not Exception

PHP 7+ — always `catch (Throwable $error)` to catch both errors and exceptions:

```php
try {
    $this->processPayment($data);
} catch (Throwable $error) {
    if (defined('WP_DEBUG') && WP_DEBUG) {
        error_log('Payment error: ' . $error->getMessage());
    }
    $result->status = 'failed';
    $result->reason = $error->getMessage();
    return $result;
}
```

#### Validate Early, Throw InvalidArgumentException

```php
if (!isset($data->order_id) || empty($data->order_id)) {
    throw new \InvalidArgumentException(__('Order ID is required', 'myplugin'));
}
if ($amount <= 0) {
    throw new \InvalidArgumentException(__('Amount must be greater than zero', 'myplugin'));
}
```

#### Plugin Structure

```
plugin-name/
├── plugin-name.php       # plugin header + singleton main class
├── integration/
│   ├── Init.php          # hook registration
│   ├── Gateway.php       # extends GatewayBase
│   └── Config.php        # gateway config class
├── payments/
│   └── Provider/
│       └── Provider.php  # extends BasePayment
├── assets/
├── vendor/               # Composer autoload
└── composer.json
```

#### Minimal Plugins — No Singleton Required

Simple, single-responsibility plugins skip the singleton and use direct `new ClassName()`:

```php
<?php
/**
 * Plugin Name: Single Session
 * ...
 */

if (!defined('ABSPATH')) { exit; }

class SingleSession {
    public function __construct() {
        add_action('wp_login', [$this, 'force_single_session_on_login'], 10, 2);
    }

    public function force_single_session_on_login($user_login, $user) {
        if (is_a($user, 'WP_User')) {
            $sessions = get_user_meta($user->ID, 'session_tokens', true);
            if ($sessions && is_array($sessions)) {
                update_user_meta($user->ID, 'session_tokens', array_slice($sessions, -1));
            }
        }
    }
}

new SingleSession();
```

Use singleton only when the plugin has multiple subsystems or needs instance reuse. Single-action plugins: just `new ClassName()`.

#### WordPress Admin UI with Vue 3 + Vite

For admin pages with interactive UI, use Vue 3 + Vite. The admin page PHP outputs a single mount div; Vue owns everything inside.

**PHP side:**
```php
class WPVue {
    function __construct() {
        add_action('admin_enqueue_scripts', [$this, 'loadAssets']);
        add_action('admin_menu', [$this, 'adminMenu']);
        // Filter to inject type="module" on the script tag
        add_filter('script_loader_tag', [$this, 'loadScriptAsModule'], 10, 3);
    }

    function loadScriptAsModule($tag, $handle, $src) {
        if ('wp-vue-core' !== $handle) return $tag;
        return '<script type="module" src="' . esc_url($src) . '"></script>';
    }

    function adminMenu() {
        add_menu_page('MyPlugin', 'MyPlugin', 'manage_options', 'myplugin/admin.php', [$this, 'loadAdminPage'], 'dashicons-admin-generic', 6);
    }

    function loadAdminPage() {
        include_once plugin_dir_path(__FILE__) . '/wp-src/admin/admin.php';
    }

    function loadAssets() {
        // Dev: Vite HMR server. Prod: point to built dist/assets/main.js
        wp_enqueue_script('wp-vue-core', '//localhost:5173/src/main.js', [], time(), true);
        // Pass PHP data to Vue via global object
        wp_localize_script('wp-vue-core', 'myplugin', [
            'url'   => plugin_dir_url(__FILE__),
            'nonce' => wp_create_nonce('wp_rest'),
            'api'   => get_rest_url(),
        ]);
    }
}
new WPVue();
```

**Admin page template** — just the mount point:
```html
<div class="wrap">
    <div id="app"></div>
</div>
```

**Vue entry (`src/main.js`):**
```js
import { createApp } from 'vue';
import App from './App.vue';
import './style.css';

createApp(App).mount('#app');
```

**Access localized data in Vue:**
```vue
<script setup>
// window.myplugin is set by wp_localize_script
const pluginUrl = window.myplugin.url;
const apiUrl = window.myplugin.api;
</script>
```

**`vite.config.js`:**
```js
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
});
```

**`package.json`** uses `"type": "module"` and minimal deps:
```json
{
  "name": "wp-plugin",
  "private": true,
  "type": "module",
  "scripts": { "dev": "vite", "build": "vite build" },
  "dependencies": { "vue": "^3.x" },
  "devDependencies": { "@vitejs/plugin-vue": "^4.x", "vite": "^4.x" }
}
```

**Key rules:**
- Use `script_loader_tag` filter to add `type="module"` — WP doesn't do this natively
- Always `wp_localize_script` to pass PHP data; never hardcode URLs/nonces in JS
- `<script setup>` syntax in all SFCs
- Dev uses Vite HMR server URL; prod points to built dist file

---

### PHP CLI Tools (Symfony Console)

#### Project Structure

```
tool-name/
├── bin/
│   └── toolname          # CLI entry point (#!/usr/bin/env php)
├── src/
│   ├── Commands/
│   │   ├── InstallCommand.php
│   │   └── StartCommand.php
│   └── Extensions/
│       └── ToolApplication.php   # extends Application
├── composer.json
└── box.json              # box/phar config if distributing as phar
```

#### CLI Entry Point (`bin/`)

Shebang + autoload path fallback array (works standalone and as Composer dep) + `set_time_limit(0)`:

```php
#!/usr/bin/env php
<?php

set_time_limit(0);

use Vendor\Tool\Commands\InstallCommand;
use Vendor\Tool\Extensions\ToolApplication;

$files = [
    __DIR__ . '/../../vendor/autoload.php',
    __DIR__ . '/../../../../autoload.php',
    __DIR__ . '/../../../autoload.php',
    '../vendor/autoload.php',
    'vendor/autoload.php',
];

foreach ($files as $file) {
    if (file_exists($file)) {
        require $file;
        define('COMPOSER_INSTALLED', 1);
        break;
    }
}

$app = new ToolApplication('My CLI Tool', 'v1.0.0');
$app->add(new InstallCommand);
$app->run();
```

Register as binary in `composer.json`:
```json
{
  "bin": ["bin/toolname"],
  "require": { "symfony/console": "^5.2" },
  "autoload": { "psr-4": { "Vendor\\Tool\\": "src/" } }
}
```

#### Custom Application — Strip Unused Options

Extend `Application` and override `getDefaultInputDefinition()` to remove `--quiet`, `--version`, `--ansi`, etc. — keep only what the tool actually uses:

```php
class ToolApplication extends Application {
    protected function getDefaultInputDefinition(): InputDefinition {
        return new InputDefinition([
            new InputArgument('command', InputArgument::REQUIRED, 'Command to execute'),
            new InputOption('--help', '-h', InputOption::VALUE_NONE, 'Display help'),
        ]);
    }
}
```

#### Command Structure

One class per command in `src/Commands/`. Store `$input`/`$output` as instance properties when private helpers need them:

```php
class InstallCommand extends Command {
    // Typed question type constants on the command class
    const QUESTION_CONFIRMATION = 1;
    const QUESTION_INPUT        = 2;
    const QUESTION_CHOICE       = 3;

    private $input;
    private $output;

    protected function configure(): void {
        $this->setName('install')
             ->setDescription('Install the project')
             ->addArgument('name', InputArgument::REQUIRED, 'Project name');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int {
        $this->input  = $input;
        $this->output = $output;

        $name = $this->ask('Enter project name:', self::QUESTION_INPUT, 'myproject');
        $confirm = $this->ask('Proceed with installation?', self::QUESTION_CONFIRMATION, 'yes');

        if ($confirm === 'yes') {
            $output->writeln('Installing...');
            // ...
        }
        return Command::SUCCESS;
    }

    private function ask(string $question, int $type, string $default = '', array $options = []): string {
        $helper = $this->getHelper('question');
        $q = match($type) {
            self::QUESTION_INPUT        => new Question($question, $default),
            self::QUESTION_CONFIRMATION => new ChoiceQuestion($question, ['yes', 'no'], $default),
            self::QUESTION_CHOICE       => new ChoiceQuestion($question, $options, $default),
        };
        return $helper->ask($this->input, $this->output, $q);
    }
}
```

Use `$output->writeln()` — never `echo`. Return `Command::SUCCESS` (0) or `Command::FAILURE` (1).

#### Cross-Platform OS Detection

```php
$isWindows = in_array(PHP_OS, ['WIN32', 'Windows', 'WINNT']);
if ($isWindows) {
    passthru("php -S {$domain}:80 -t {$domain}/");
} else {
    passthru("sudo php -S {$domain}:80 -t {$domain}/");
}
```

Use `passthru()` for long-running subprocesses that need live stdout/stderr output.

#### State Persistence as JSON

Store per-site or per-project state in a JSON file alongside the data:

```php
file_put_contents("{$name}.json", json_encode([
    'domain' => $domain,
    'created_at' => date('c'),
], JSON_PRETTY_PRINT));
```

Check existence before overwriting: `if (file_exists("{$name}.json")) { ... }`.

---

### Laravel Packages

#### Package Structure

```
package-name/
├── src/
│   ├── Http/
│   │   ├── Controllers/      # BaseController + per-resource controllers
│   │   └── Middleware/       # per-concern middleware classes
│   ├── Providers/
│   │   └── PackageServiceProvider.php
│   ├── Concerns/             # Eloquent model traits (HasCrud, etc.)
│   ├── Traits/               # other PHP traits
│   ├── Services/             # service classes
│   └── Support/              # helpers, route helpers, value objects
├── config/
│   └── package-name.php      # all config with defaults
├── database/
│   └── migrations/
├── resources/
│   └── views/
├── routes/
│   └── web.php
└── composer.json
```

#### ServiceProvider Pattern

Split `boot()` into protected methods — one per concern. Never write business logic directly in `register()`/`boot()`:

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

    protected function registerRoutes(): void { ... }
    protected function registerViews(): void { ... }
    protected function registerViewComposers(): void { ... }
    protected function registerMiddleware(): void { ... }
    protected function registerCommands(): void { ... }
    protected function registerPublishing(): void { ... }
    protected function registerEventListeners(): void { ... }
}
```

#### Config-Driven Design

**Every configurable value uses `config('package.key', 'default')`** — never hardcode. This makes the package usable without touching the source:

```php
$userModel = config('tyro-dashboard.user_model', config('tyro.models.user', 'App\\Models\\User'));
$adminRoles = config('tyro-dashboard.admin_roles', ['admin', 'super-admin']);
$disk = config('tyro-dashboard.uploads.disk', 'public');
```

#### Abstract BaseController

Always an abstract base in packages with `protected` helpers for shared logic:

```php
abstract class BaseController extends Controller {
    protected function getUserModel(): string {
        return config('package.user_model', 'App\\Models\\User');
    }

    protected function isAdmin(): bool {
        $user = auth()->user();
        if (!$user || !method_exists($user, 'roleSlugs')) return false;
        $adminRoles = config('package.admin_roles', ['admin', 'super-admin']);
        return !empty(array_intersect($adminRoles, $user->roleSlugs()));
    }

    protected function getViewData(array $data = []): array {
        return array_merge([
            'branding' => config('package.branding'),
            'isAdmin' => $this->isAdmin(),
            'user' => auth()->user(),
        ], $data);
    }
}
```

#### Concerns vs Traits

- `Concerns/` — Eloquent-related traits that add model behaviour (CRUD config, resource introspection)
- `Traits/` — general PHP traits (profile photo, file handling)

#### HasCrud Concern

Models include a `HasCrud` trait to expose resource configuration for admin interfaces. The trait auto-detects fields from `$fillable` + DB schema, detects relationships via Reflection:

```php
trait HasCrud {
    public static function getResourceConfig(): array {
        $instance = new static;
        return [
            'model'    => static::class,
            'title'    => $instance->resourceTitle ?? ...,
            'fields'   => $instance->resourceFields ?? static::getCachedFieldsOrGenerate($instance),
            'roles'    => $instance->resourceRoles ?? [],
            'readonly' => $instance->resourceReadonly ?? [],
        ];
    }

    public static function getResourceKey(): string {
        $instance = new static;
        return $instance->resourceKey ??
            Str::plural(Str::snake(class_basename(static::class)));
    }
}
```

#### Caching Pattern

Use `Cache::get/put` with a content-hash key to avoid stale cache on schema changes. Always clear old hash on update:

```php
$cacheKey = 'pkg_fields_'.md5($modelClass).'_'.md5(serialize($fillable));
$cached = Cache::get($cacheKey);
if ($cached !== null) return $cached;
$fields = static::generateFields($instance);
Cache::put($cacheKey, $fields, 21600); // 6 hours
```

#### Route Groups

Routes go in `routes/web.php`, loaded via ServiceProvider with config-driven prefix and middleware:

```php
Route::group([
    'prefix' => config('package.routes.prefix', 'dashboard'),
    'middleware' => config('package.routes.middleware', ['web', 'auth']),
    'as' => 'dashboard.',
], function () {
    $this->loadRoutesFrom(__DIR__.'/../../routes/web.php');
});
```

Dev/example routes gated on environment:

```php
if (!config('package.disable_examples', false) && !app()->environment('production')) {
    Route::get('/components', [ComponentsController::class, 'components'])->name('components');
}
```

#### Granular Publishing

Never one giant publish group. Separate groups for each concern so users only publish what they need:

```php
$this->publishes([__DIR__.'/../../config/package.php' => config_path('package.php')], 'package-config');
$this->publishes([$viewsPath => resource_path('views/vendor/package')], 'package-views');
$this->publishes([$viewsPath.'/partials/styles.blade.php' => ...], 'package-styles');
$this->publishes([$viewsPath.'/partials/scripts.blade.php' => ...], 'package-scripts');
// Combined group for convenience
$this->publishes([...config + views...], 'package');
```

#### Middleware Registration

Alias middleware in ServiceProvider, don't rely on kernel registration:

```php
protected function registerMiddleware(): void {
    $router = $this->app['router'];
    $router->aliasMiddleware('package.admin', EnsureIsAdmin::class);
    $router->pushMiddlewareToGroup('web', HandleImpersonation::class);
}
```

#### View Composers

Share common data with all package views via composers — never pass it from every controller:

```php
View::composer(['package::*', 'dashboard.*'], function ($view) {
    $view->with('user', auth()->user());
    $view->with('dashboardRoute', DashboardRoute::class);
});
```

#### Console Commands

One class per Artisan command. All registered in ServiceProvider, guarded by `runningInConsole()`:

```php
protected function registerCommands(): void {
    if (!$this->app->runningInConsole()) return;
    $this->commands([
        InstallCommand::class,
        MakeResourceCommand::class,
        PublishCommand::class,
        // ...
    ]);
}
```

#### PHPDoc Comments

Every public method gets a PHPDoc with `@param` and `@return`:

```php
/**
 * Update the user's profile photo.
 *
 * @param  \Illuminate\Http\UploadedFile  $photo
 * @return void
 */
public function updateProfilePhoto($photo): void {
```

#### Naming Conventions

- Classes: `PascalCase` with role suffix — `ResourceController`, `EnsureIsAdmin`, `HasCrud`, `HasProfilePhoto`
- Methods: `camelCase` — `getResourceConfig()`, `registerViewComposers()`
- Files: `PascalCase.php` matching class name
- Config keys: `kebab-case.dot.notation` — `tyro-dashboard.admin_roles`
- Blade views: `kebab-case.blade.php` in namespaced directory — `tyro-dashboard::partials.flash-messages`

---

## Reviewing Existing Code

When reviewing code against this style, flag:
- Missing type definitions or interfaces
- Business logic outside its proper layer (e.g., DB calls in a handler)
- Raw error strings instead of typed errors
- Magic values not in constants/config files
- Swallowed errors (empty catch, ignored Result, bare `except: pass`)
- Missing doc comments on exported items
- Wrong filename casing for the language
- Missing semicolons in TS/JS
- 4-space indentation in Python
- Direct `console.log` / `print` / `println!` in non-CLI library code
- Singleton services instantiated on every call instead of exported once

## Additional Resources

- **`references/patterns.md`** — Extended patterns, anti-patterns, and per-language edge cases
