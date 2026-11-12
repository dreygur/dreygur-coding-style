# dreygur skills

A [Claude Code](https://claude.ai/code) skill that encodes dreygur's personal coding style across Go, TypeScript, JavaScript, Rust, and Python.

Once installed, Claude automatically follows these patterns when writing or reviewing code, with no prompting needed.

## Install

```bash
npx skills add dreygur/skills
```

Installs as `/dreygur-skill`. Works with Claude Code, Cursor, GitHub Copilot, Windsurf, and [many more agents](https://skills.sh).

As a Claude Code plugin, which updates itself. The `/` menu lists it as `/dreygur:dreygur-skill`, since Claude Code prefixes plugin skills with the plugin name, and typing `/dreygur-skill` still runs it:

```bash
claude plugin marketplace add dreygur/skills
claude plugin install dreygur@dreygur
```

## What it covers

- **The shape of a file**: dependencies defined *above* their caller, composite last, constants at the top, so the file reads in order, and never announces its own structure with banner comments
- **Architecture**: Service / Repository / Handler / Strategy / Middleware layers in every language;
  each layer must hold logic or it fails the deletion test
- **Types first**: Interfaces and types defined before implementations, in dedicated files; an
  interface needs a second implementation or a boundary mock
- **Domain words**: names come from the repo's `GLOSSARY.md`, and settled terms get added to it
- **Custom error hierarchy**: Named error types with codes and context, not raw strings
- **Singleton exports**: Services and repositories exported as initialized instances
- **Leveled logging**: `debugLog`/`infoLog`/`warnLog` in TS, `PrintLog` in Go, `tracing` in Rust
- **Constants/config in dedicated files**: No magic values inline
- **Proper doc comments**: JSDoc in TS/JS, `///` in Rust, package-level comments in Go
- **Filename conventions**: `kebab-case` in TS/JS, `snake_case` in Go/Rust/Python
- **Always semicolons** in TypeScript/JavaScript
- **2-space indentation** in Python
- **Never swallow errors**
- **No casts to silence the type checker**: no `as any`, no inline `/** @type {X} */`; narrow at runtime or fix the declaration
- **Tests prove behavior**: a clean compile is not evidence; every function gets a test that runs it
- **Testing**: tests at agreed seams, red then green one slice at a time, mocks only at boundaries
  the code does not own, test doubles named `mock`
- **Two axis review**: Standards and Spec reported separately, with a Fowler smell baseline
- **Per language references**: each stack's layout, idioms and anti-patterns load only when that
  language is in play
- **Writing like a human**: no dashes anywhere (em dash, en dash, or hyphenated compound words),
  no stock model vocabulary, no `not just X, but Y`, no padding or summary paragraphs, no emoji.
  Applies to comments, docs, commits, and PR bodies
- **Commit and PR format**: imperative subjects under 50 characters; PR bodies open with what and
  why, then the issue link
- **Structured thinking** for judgment calls: restate, three interpretations, strongest case
  against, then the final answer
- **Plan review with EGM**: plans and design docs go to fresh EGM reviewers before building.
  The skill tells the agent how to install or update EGM, and falls back to the
  workflow's own review when EGM cannot run
- **Native file tools**: read, search and edit files with the agent's own tools; shell on files
  only as a fallback or when it costs fewer tokens
- **Secrets redacted** in commands, logs, commits and chat
- **No AI attribution** in commits, PRs, comments, or docs

## Update

```bash
npx skills update dreygur-skill
```

## Remove

```bash
npx skills remove dreygur-skill
```

## Alternative: shell install (no Node.js required)

```bash
curl -fsSL https://raw.githubusercontent.com/dreygur/skills/main/install.sh | bash
```

## Structure

```
.claude-plugin/
  plugin.json           # plugin manifest
  marketplace.json      # lets `claude plugin marketplace add` find the plugin
skills/
  skill/
    SKILL.md            # core skill: triggers and universal rules
    agents/openai.yaml  # Codex display metadata
    references/
      typescript.md     # one file per language: layout, idioms, anti-patterns
      go.md
      rust.md
      python.md
      wordpress.md
      php-cli.md
      laravel.md
      testing.md        # seams, mocking at boundaries, test anti-patterns
      review.md         # two axis review procedure and smell baseline
      patterns.md       # file ordering drill and prose rewrites
      behavior-examples.md  # wrong/right examples for each Karpathy principle
docs/out-of-scope.md    # ideas declined, with reasons
CHANGELOG.md
install.sh              # shell install / update (alternative to npx)
uninstall.sh            # shell uninstall
```
