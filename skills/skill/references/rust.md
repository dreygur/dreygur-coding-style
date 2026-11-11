# Rust

## Structure
```
project/
├── Cargo.toml  ├── src/main.rs  ├── src/lib.rs  ├── src/error.rs
├── src/config/mod.rs  └── crates/*/src/{lib.rs,error.rs}
```

## Error Types (`thiserror` always)
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

## Binaries
```rust
#[tokio::main]
async fn main() -> eyre::Result<()> { ... }  // preferred in newer projects
// or anyhow::Result<()>
```

## Shared State
```rust
let store = Arc::new(Store::new());
tokio::spawn(async move {
    let store = Arc::clone(&store);  // explicit Arc::clone, not .clone()
    handle(stream, store).await
});
```

## tokio::select!
```rust
loop {
    tokio::select! {
        Some(event) = events.next() => { ... }
        _ = sleep(Duration::from_secs(30)) => { /* tick */ }
    }
}
```

## CLI (clap)
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

## lib.rs Re-exports
```rust
pub mod error; pub mod client;
pub use error::{AppError, Result};
pub use client::Client;
```

## Logging
```rust
use tracing::{debug, error, info, warn};
info!("started"); warn!("retry {attempt}"); error!("{err}");
```

## Error Enum with From Derives

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

## Conditional Debug Writer

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

## Workspace Crate Naming

Crates are named by function: `mcp-client`, `mcp-server`, `mcp-types`, `mcp-proxy`, `mcp-config`. The main binary crate is the project name.

## Anti-Patterns to Avoid (Rust)

- `.unwrap()` in library code: use `?` or explicit error handling
- `println!()` in library crates: use `tracing`
- Putting all code in `main.rs`: split into modules
- Skipping `thiserror` and using `Box<dyn Error>` in library code
