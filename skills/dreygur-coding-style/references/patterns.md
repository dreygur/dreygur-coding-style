# Extended Patterns & Anti-Patterns

## TypeScript / JavaScript

### Mutex for Concurrent Operations

Use a `Mutex` utility to prevent race conditions in async flows (e.g., token refresh):

```ts
// utils/mutex.ts
export class Mutex {
  private queue: Array<() => void> = [];
  private locked = false;

  isLocked(): boolean { return this.locked; }

  async runExclusive<T>(fn: () => Promise<T>): Promise<T> {
    await this.acquire();
    try { return await fn(); }
    finally { this.release(); }
  }
}
```

### Retry Middleware

Wrap fetch with retry logic in a dedicated middleware file, not inline:

```ts
// middleware/retry.middleware.ts
export async function fetchWithRetry(
  url: string,
  init: RequestInit,
  options: { maxRetries: number; baseDelay: number; timeout: number },
): Promise<Response> { ... }
```

### Logger Wrapper (not raw console)

```ts
// utils/logger.ts
export const debugLog = (message: string, data?: Record<string, unknown>) =>
  client.app.log({ body: { level: "debug", message, extra: data } }).catch(() => {});
export const infoLog  = (message: string, data?: Record<string, unknown>) => ...;
export const warnLog  = (message: string, data?: Record<string, unknown>) => ...;
```

### Anti-Patterns to Avoid (TS/JS)

- `catch (e) {}` — never swallow
- `any` type without a comment explaining why
- Default exports except for plugin entry points
- Mixing `require()` and `import`
- Missing semicolons
- Hardcoded URLs, tokens, or secrets
- Business logic inside `index.ts` — it's only a barrel

---

## Go

### Variadic Field Validator

```go
func RequireNonEmpty(fields ...string) bool {
    for _, f := range fields {
        if f == "" { return false }
    }
    return true
}
```

### URL Construction

Use `url.ParseRequestURI` + path append — never raw string interpolation:

```go
u, _ := url.ParseRequestURI(baseURL)
u.Path += endpoint
return u.String()
```

### Request Abstraction

Centralize all outbound HTTP in a `hooks.Request` struct to avoid scattered HTTP boilerplate:

```go
payload := &hooks.Request{
    Debug:   b.debug,
    Payload: data,
    Url:     hooks.GenerateURI(b.IsLiveStore, common.GRANT_TOKEN_URI),
}
body, err := hooks.DoRequest(payload)
```

### Panic Recovery in main

```go
defer func() {
    if r := recover(); r != nil {
        fmt.Println("Error: ", r)
    }
}()
```

### Anti-Patterns to Avoid (Go)

- `log.Fatal` outside of `main` or `cmd/`
- Business logic directly in `main.go`
- Switch statements for command dispatch — use `map[string]func`
- Prefix-based Discord commands — always slash commands
- Hard-coded credentials — use `os.Getenv` + `sample.env`

---

## Rust

### Error Enum with From Derives

```rust
#[derive(Error, Debug)]
pub enum AppError {
    #[error("IO: {0}")]
    Io(#[from] std::io::Error),        // automatic From<io::Error>
    #[error("JSON: {0}")]
    Json(#[from] serde_json::Error),   // automatic From<serde_json::Error>
    #[error("Custom: {0}")]
    Custom(String),                    // manual construction
}
pub type Result<T> = std::result::Result<T, AppError>;
```

### Conditional Debug Writer

Only write logs when debug mode is on:

```rust
struct ConditionalWriter { debug: bool }
impl Write for ConditionalWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        if self.debug { io::stderr().write(buf) } else { Ok(buf.len()) }
    }
    fn flush(&mut self) -> io::Result<()> {
        if self.debug { io::stderr().flush() } else { Ok(()) }
    }
}
```

### Workspace Crate Naming

Crates are named by function: `mcp-client`, `mcp-server`, `mcp-types`, `mcp-proxy`, `mcp-config`. The main binary crate is the project name.

### Anti-Patterns to Avoid (Rust)

- `.unwrap()` in library code — use `?` or explicit error handling
- `println!` in library crates — use `tracing`
- Putting all code in `main.rs` — split into modules
- Skipping `thiserror` and using `Box<dyn Error>` in library code

---

## Python

### 2-Space Indentation

This is intentional. All Python files use 2 spaces, not 4:

```python
class SSLCSession(SSLCommerz):
  def __init__(self, is_sandbox: bool = True) -> None:
    super().__init__(is_sandbox)

  def set_urls(self, success_url: str, fail_url: str) -> None:
    self.integration_data.update({
      'success_url': success_url,
      'fail_url': fail_url,
    })
```

### Type Hint Imports

```python
from typing import Dict, Optional, List
from decimal import Decimal
from uuid import uuid4
```

### Anti-Patterns to Avoid (Python)

- 4-space indentation
- Missing type hints on method signatures
- Missing docstrings on public methods
- `except Exception: pass` — never swallow
- Mutable default arguments (`def f(x=[])`)
- Raw `print()` in library code — use `logging`
