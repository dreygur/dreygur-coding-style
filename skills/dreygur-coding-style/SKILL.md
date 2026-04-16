---
name: dreygur-coding-style
description: This skill should be used when writing any code for dreygur — Go, TypeScript, JavaScript, Rust, or Python. Use when the user asks to "write code in my style", "follow my coding patterns", "use my architecture", "create a new project", "add a service", "add a repository", "write a handler", or whenever generating code that should match dreygur's established patterns. Also use when reviewing existing code for style violations.
version: 2.0.0
---

# dreygur Coding Style Guide

Derived empirically from dreygur's open-source projects across Go, TypeScript, Rust, and Python. Apply these rules silently when writing code, call out style decisions when they're non-obvious, and flag violations when reviewing code.

## Universal Rules (All Languages)

These apply regardless of language or stack. Never break them.

### 1. Types / Interfaces First

Define contracts before implementations. Types live in a dedicated file:
- TypeScript/JS: `types.ts`
- Go: `models/requests.go`, `models/responses.go`
- Rust: `crates/*/src/lib.rs` or a `types.rs`
- Python: base class or dataclasses before subclasses

### 2. Service Provider / Clean Architecture

Always layer code into:

| Layer | TS/JS | Go | Rust | Python |
|---|---|---|---|---|
| Types/Models | `types.ts`, `models/` | `models/` | `types.rs`, structs | base class / dataclasses |
| Services | `*.service.ts` | `methods/`, `api/` | `src/*/manager.rs` | class methods |
| Repositories | `*.repository.ts` | `db/`, `repo/` | `src/*/store.rs` | class with DB methods |
| Handlers/Controllers | `*.handler.ts` | `handlers/`, `cmds/` | `src/cli/` | route functions |
| Middleware/Hooks | `*.middleware.ts` | `hooks/` | `src/*/middleware.rs` | decorators / wrappers |
| Strategies | `*.strategy.ts` | (pattern in methods/) | `src/*/strategy.rs` | — |
| Utils | `utils/` | `utils/`, `lib/` | `src/util/` | helpers |
| Config/Constants | `config.ts`, `constants.ts` | `common/vars.go`, `lib/settings.go` | `src/config/` | `constants.py` |

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
