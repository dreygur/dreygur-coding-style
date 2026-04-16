# dreygur-coding-style

A [Claude Code](https://claude.ai/code) skill that encodes dreygur's personal coding style across Go, TypeScript, JavaScript, Rust, and Python.

Once installed, Claude automatically follows these patterns when writing or reviewing code — no prompting needed.

## Install

```bash
npx skills add dreygur/dreygur-coding-style
```

Works with Claude Code, Cursor, GitHub Copilot, Windsurf, and [many more agents](https://skills.sh).

## What it covers

- **Architecture**: Service / Repository / Handler / Strategy / Middleware layers in every language
- **Types first**: Interfaces and types defined before implementations, in dedicated files
- **Custom error hierarchy**: Named error types with codes and context — not raw strings
- **Singleton exports**: Services and repositories exported as initialized instances
- **Leveled logging**: `debugLog`/`infoLog`/`warnLog` in TS, `PrintLog` in Go, `tracing` in Rust
- **Constants/config in dedicated files**: No magic values inline
- **Proper doc comments**: JSDoc in TS/JS, `///` in Rust, package-level comments in Go
- **Filename conventions**: `kebab-case` in TS/JS, `snake_case` in Go/Rust/Python
- **Always semicolons** in TypeScript/JavaScript
- **2-space indentation** in Python
- **Never swallow errors**

## Update

```bash
npx skills update dreygur/dreygur-coding-style
```

## Remove

```bash
npx skills remove dreygur/dreygur-coding-style
```

## Alternative: shell install (no Node.js required)

```bash
curl -fsSL https://raw.githubusercontent.com/dreygur/dreygur-coding-style/main/install.sh | bash
```

## Structure

```
skills/
  dreygur-coding-style/
    SKILL.md            # core skill — triggers and all style rules
    references/
      patterns.md       # extended patterns and anti-patterns per language
install.sh              # shell install / update (alternative to npx)
uninstall.sh            # shell uninstall
```
