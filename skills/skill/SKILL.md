---
name: dreygur-skill
description: 'Use when writing any code for dreygur in Go, TypeScript, JavaScript, Rust, Python, or PHP/Laravel/WordPress. Trigger on "write code in my style", "follow my patterns", "use my architecture", "create a new project", "add a service/repository/handler", when ordering functions within a file, when writing tests or a commit message, when writing a README, doc, comment, or PR body that should not read as machine-written, or when reviewing code for style violations. Also applies the Karpathy behavior guidelines: think before coding, simplicity first, surgical changes, goal driven execution. Applies structured thinking (restate, three interpretations, strongest counter case, final answer) to judgment and design questions. Reviews plans and design docs with EGM before building, falling back to the workflow''s own review when EGM cannot run.'
version: 2.14.1
---

# dreygur Coding Style

## The Shape of a File

Poetry and a story at the same time. Poetry: nothing wasted, the shape on the page carries meaning. Story: it reads in order, each part following from the last. Ordering is the argument, not an accident.

### 1. Dependencies Above, Composite Last
A function's dependencies are defined **above** it. Write the composite, then place everything it calls above it. Reading top to bottom, every name arrives after its parts.

```
constants -> leaf helpers -> mid-level helpers -> public entry point
```

Every name is defined before its first use. New helper + new caller means the helper goes first. In Rust and Go too, helpers sit on top, whatever the local habit.

Exception: when inserting into an existing section that already reads caller-first, keep the local convention rather than reordering existing code.

### 2. Constants Are the Rules of the Play
Timeouts, ports, limits, fixed strings sit at the very top of the file, before any behavior.

### 3. One File, One Purpose
Prefer a new file over growing an existing one when the concern is distinct.

### 4. Small Parts, Small Cast
Each part sets up only what it needs, with a cast small enough to hold in mind at once.

### 5. Let the Ordering Speak
Structure lives in how the code reads: ordering, file boundaries, blank lines between steps. The shape is **felt, not announced**.

A comment earns its place only by explaining **why** something is the way it is, or a non-obvious constraint. Doc comments on exported items still apply (Universal Rule 8); those describe contract and intent, not layout.

---

## Universal Rules

### 1. Types First
Contracts before implementations.
- TS/JS: `types.ts` | Go: `models/` | Rust: `types.rs` | Python: base class | PHP: `src/Contracts/`

An interface (TS `interface`, Go interface, Rust trait, PHP contract) earns its place with a second implementation. A mock at a boundary the code does not own counts as the second one (see `references/testing.md`). Inside code the project owns, one implementation means a concrete type.

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

### 3. Typed Errors
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

### 5. Leveled Logging in Library Code
Library code logs through its language's leveled tool:

| Language | Tool |
|---|---|
| Go | custom `PrintLog` + `fatih/color` (`[+]`/`[-]`/`[!]`/`[*]`) |
| TypeScript | `debugLog`/`infoLog`/`warnLog` wrappers or Winston |
| Rust | `tracing` (`info!()`, `warn!()`, `error!()`, `debug!()`) |
| Python | stdlib `logging` |

### 6. Named Values: literals live in constants/config files
### 7. Propagate Errors With Context
### 8. Doc Comments on every exported item: comment the *why*
### 9. Filenames
- TS/JS: `kebab-case` + layer suffix, as in `token.service.ts`, `auth.middleware.ts`
- Go: `snake_case.go`, as in `token.go`, `cmd_handler.go`
- Rust: `snake_case.rs`, as in `error.rs`, `config_watcher.rs`
- Python: `snake_case.py`
- PHP: `PascalCase.php` matching class name

### 10. No Casts to Silence the Type Checker
Never wrap an expression to make an error go away: `/** @type {X} */ (expr)` in JS, `as any`/`as unknown as X` in TS. Every such cast is masking a real defect: a missing runtime guard, dead config, or a dynamic dispatch that should be explicit branches.

Fix it by narrowing at runtime or fixing the declaration. Annotating a `const` on its own line is fine. Types belong in `types.ts` / `types/*.d.ts`, not inline at the call site.

Only tolerated at a generic base-class boundary the type system genuinely cannot express (see `BaseRepository` in `references/typescript.md`).

### 11. Tests Prove Behavior, Not Signatures
Evidence of correctness is a test that runs the code. A clean `cargo build`, `tsc --noEmit`, `go vet`, or a `no_run` doctest only checks signatures.

- Every new function gets a test that **executes** it and asserts on real behavior, including error paths.
- Prefer hermetic tests that run in the default runner (`cargo test`, `pnpm test`, `go test ./...`) over ones needing live services; add a gated/`#[ignore]` integration test when the real contract matters.
- Report work done once those tests pass.

### 12. Test Doubles Are Named `mock`
`mock_cdp`, `MockTokenStore`, `mock_server.go`.

### 13. Bug Fixes Start With a Failing Test
When the task is fixing a bug: write the test that reproduces it first, run it, watch it fail, then write the fix, then watch it pass. This is the one case where test-first is mandatory rather than a preference.

Before writing tests, read `references/testing.md`: where tests go, what to mock, and the test anti-patterns.

---

## AGENTS.md Rules

General conventions dreygur runs across every language. These sit alongside Universal Rules above; where the two overlap, this section is the more specific instruction.

### Say Less
For anything a human reads (comment, commit message, reply to a prompt), use as few words as possible. Pick every word on purpose. Down to the point. Less is more.

### Cold Hard Truth
Answer dreygur with the plain state of things: what's wrong, what's missing, what breaks. Agreement, when earned, is one word.

### Constants Over Magic Values
Extract a recurring or meaningful literal into a named `const` or enum. Leave a self-explanatory one-off value inline, that's not clutter, it's a value used once. A value that comes from a spec (HTTP `200`, a protocol magic byte, a fixed header size) always gets a constant, even if it's used once, because the spec is the reason it can't change.

### Flatten Nesting
Keep the main path at the left margin. Reach for early return and early continue before adding another level of `if`.

```go
// wrong
func process(item *Item) error {
    if item != nil {
        if item.Valid() {
            if item.Ready() {
                return commit(item)
            }
        }
    }
    return nil
}

// right
func process(item *Item) error {
    if item == nil || !item.Valid() || !item.Ready() {
        return nil
    }
    return commit(item)
}
```

### Short Function Names
Keep a function name under 30 characters. If it doesn't fit, the function is probably doing too much or the name is carrying detail that belongs in a doc comment instead.

### Domain Words From the Glossary
When the repo has a `GLOSSARY.md`, read it before naming anything. Types, functions, tests and docs use its terms exactly. When dreygur uses a term that conflicts with it, or a vague one ("account": Customer or User?), ask which is meant. Once a term is settled, add it right away; create the file on the first term.

```md
**Order**: a customer's request to buy one or more products, paid or not.
_Avoid_: purchase, cart
```

The glossary holds meaning only. Implementation detail goes in code and decisions go in trail learnings.

### Enums Over Boolean Parameters
A bare `true`/`false` at a call site tells the reader nothing. Use an enum:

```ts
// wrong
scheduleJob(job, true);

// right
scheduleJob(job, Priority.High);
```

### Let the Code Breathe
Blank line between logical blocks: setup, then the operation, then the return. Statements within one step stay together.

### Comment the Block, Not the Line
A block-level comment states what the block does and why, with an example or a small ASCII drawing when a system's shape is the point. It summarizes the block's purpose; inside the block, Writing Like a Human rule 7 still holds.

```go
// Coalesces concurrent refreshes into one outbound request.
//
//   caller A ─┐
//   caller B ─┼─> mutex.Lock() -> single refresh -> broadcast to all
//   caller C ─┘
func refreshToken() (*Token, error) { ... }
```

### Private by Default, Public by Approval
Every field and function starts private. Widening a private member to internal or public is a design decision, not a formatting one, ask dreygur before making that change. Treat it as a breaking shift to the type's contract even if the compiler stays quiet.

### Encapsulate the Low Level
Raw hardware I/O, sector parsing, direct socket streams: these live behind a dedicated driver or abstraction layer. The rest of the application calls a clean, high-level API that speaks in domain concepts (`ReadSector(lba)`, not `ioctl(fd, ...)` scattered through business logic).

### Layers Talk Only to Their Neighbor
A controller or UI component reaches databases, hardware drivers and network clients through the service layer immediately below it. That hop is the boundary that makes the layer swappable.

Each layer earns its place by holding logic. Deletion test: imagine removing the layer. If its callers would just call the next layer with the same arguments, it only forwards. Move the logic that belongs there into it (validation, mapping, authorization, transactions), or flag it.

### Touch Only What the Task Requires
Edit only the blocks this feature needs. Minimize the diff. Code outside the task stays as found, its comments and formatting included.

### Native Tools for Files, Shell for Commands
Read, search and change files with the agent's own file tools (Read, Edit,
Write, Grep, Glob). A file tool shows the change as a diff and fails loudly
when the target text is missing. Bash runs commands: git, pnpm, cargo, go,
gh, docker, podman, psql.

Shell or a script touches files only as a fallback: when the native tools
cannot do the job (binary formats such as `.xlsx`, parsing or counting
across many files), or when the shell route costs fewer tokens (hundreds of
identical edits, moving large blocks verbatim, a large generated file). Say
why in one line before running it.

Put the same rule in every subagent brief. If Grep or Glob is missing from
the session, say so; `git grep` and `git ls-files` through Bash are the
search fallback.

### Redact Secrets
Never show a secret. In commands, logs, captured requests, env dumps, commits, and chat, write `<REDACTED>` in place of keys, tokens, passwords, auth headers, and personal data. Commands read credentials from env vars (`curl -H "Authorization: Bearer $API_TOKEN"`), so the value never lands in what is shown. Quote only the lines that carry the signal. If the redacted output is not enough to work from, say so and ask.

### Braces Always
Every `if` gets `{}`, one liners included.

```go
// wrong
if err != nil
    return err

// right
if err != nil {
    return err
}
```

### Commit Message Format

1. Blank line between subject and body, always.
2. Subject line under 50 characters, 72 is the hard ceiling.
3. Capitalize the first letter of the subject.
4. End the subject line without a period.
5. Imperative mood in the subject: `Fix bug`, `Add feature`. Test: the subject must complete "If applied, this commit will ___."
6. Wrap the body by hand at 72 characters.
7. The body explains what and why; the diff already shows how. State the context and reasoning that isn't visible in the code.

### PR Body Format

The title follows commit subject rules 2 to 5. The body opens with a short paragraph: what changed and why. Then the issue link. Then, only where they apply, one line each for how to test, risk or rollback, and follow ups. Headings only when a PR is large enough to need them.

```
Two requests racing on an expired token each refreshed; the second
overwrote the first. Refresh now runs under the shared mutex.

Closes #42

Test: pnpm test token.service
Risk: refresh latency for waiting callers
```

---

## Behavior: Karpathy Guidelines

Behavioral guidelines against the common LLM coding mistakes, from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) (MIT, adapted from `multica-ai/andrej-karpathy-skills`). Full wrong/right examples for every principle: `references/behavior-examples.md`.

The mistakes they target, in Karpathy's words:

> The models make wrong assumptions on your behalf and just run along with them without checking. They don't manage their confusion, don't seek clarifications, don't surface inconsistencies, don't present tradeoffs, don't push back when they should.

> They really like to overcomplicate code and APIs, bloat abstractions, don't clean up dead code... implement a bloated construction over 1000 lines when 100 would do.

> They still sometimes change/remove comments and code they don't sufficiently understand as side effects, even if orthogonal to the task.

**Tradeoff:** these bias toward caution over speed. For trivial tasks (a typo fix, an obvious one liner) use judgment; not every change needs the full rigor. The goal is fewer costly mistakes on non trivial work, not slower simple work.

| Principle | Addresses |
|---|---|
| Think Before Coding | Wrong assumptions, hidden confusion, missing tradeoffs |
| Simplicity First | Overcomplication, bloated abstractions |
| Surgical Changes | Orthogonal edits, touching code you shouldn't |
| Goal Driven Execution | Leverage through tests first, verifiable success criteria |

### 1. Think Before Coding
**State assumptions. Name confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask rather than guess.
- If multiple interpretations exist, present them and let dreygur pick.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**

- Build exactly the features that were asked for.
- An abstraction waits for its second user.
- Options and config wait for a request.
- Error handling covers scenarios that can actually happen.
- If you write 200 lines and it could be 50, rewrite it.

The test: would a senior engineer say this is overcomplicated? If yes, simplify. The overbuilt version is usually not wrong, it follows real patterns. The problem is timing: it adds complexity before it is needed, which makes the code harder to read, test, and get right. Solve today's problem simply, refactor when the second requirement actually arrives.

### 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Leave adjacent code, comments, and formatting as found.
- Refactor only what is broken.
- Match existing style, even if you'd do it differently (quote style, type hints, spacing, return shape).
- If you notice unrelated dead code, mention it and leave it in place.

When your changes create orphans:
- Remove imports, variables, and functions that YOUR changes made unused.
- Pre-existing dead code stays until dreygur asks for it gone.

The test: every changed line traces directly to the user's request. Pairs with Touch Only What the Task Requires above.

### 4. Goal Driven Execution
**Define success criteria. Loop until verified.**

Turn imperative tasks into verifiable goals:

| Instead of | Transform to |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") force constant clarification. Karpathy: "LLMs are exceptionally good at looping until they meet specific goals... Don't tell it what to do, give it success criteria and watch it go." Pairs with Universal Rule 13 (bug fixes start with a failing test).

### Signs It Works
- Fewer unnecessary changes in diffs; only requested changes appear.
- Fewer rewrites from overcomplication; the code is simple the first time.
- Clarifying questions come before implementation, not after mistakes.
- Clean, minimal PRs holding only the requested change.

### Project Specific Additions
These guidelines merge with project instructions. A project may add its own on top (strict mode, tests on every endpoint, follow the error pattern in `src/utils/errors.ts`). Project rules win where they conflict.

---

## Behavior: Structured Thinking

Use for questions involving judgment, design choices, advice, recommendations, or any answer that depends on premises being correct. Skip it for mechanical retrieval: file searches, grep, fetches, lookups.

Answer by completing these numbered sections in order. The final answer comes last.

1. **Restate** the question in your own words.
2. **Interpretations.** List three plausible interpretations of the question, naming the critical assumption of each. If the user's framing is one of them, name it as such and weigh it equally with the others.
3. **Strongest case against.** List the strongest case against the answer you are about to give. Construct a real counter case, not a strawman. If the strongest objection invalidates your prospective answer, revise the answer in section 4. State the objection at full strength.
4. **Final answer.**

The conclusion in section 4 must be consistent with what you wrote in sections 1 to 3. If they conflict, revise section 4. The earlier sections are committed claims; the final answer accommodates them.

Pairs with Think Before Coding above: section 2 is where competing interpretations get surfaced instead of picked silently.

---

## Behavior: Plan Review

Before building from a plan, spec, or design document, have it reviewed by reviewers that never saw the conversation. Use EGM (the Elephant Goldfish Model plugin, `egm@egm`) for this. This skill does not ship EGM; install or update it from its own marketplace.

1. **Check.** Run `claude plugin list` and look for `egm@egm`, enabled.
2. **Install if missing.**
   ```bash
   claude plugin marketplace add google/elephant-goldfish-model
   claude plugin install egm@egm
   ```
3. **Update if present.**
   ```bash
   claude plugin marketplace update egm
   claude plugin update egm@egm
   ```
   A fresh install or an update loads only after a restart. Tell dreygur to restart the session, and use the fallback for the plan in hand.
4. **Run the review.** EGM skills set `disable-model-invocation: true`, so the `Skill` tool refuses them. Read `skills/egm-review/SKILL.md` from the installed plugin (`claude plugin details egm@egm` shows the path) and follow it in the same thread, passing the plan's path. Its reviewers are the `egm:egm-*` subagent types.

Fall back to the review the current workflow already has when EGM cannot run: it is not installed and the install fails, it needs a restart, it is disabled, or the harness has no subagent tool. Fallback order:

- The workflow's own review step (for example the superpowers builder check on a design, or the plan reviewer in writing plans).
- No such step: one fresh general purpose subagent reads the plan cold and reports the questions it would need answered before building, ranked by impact.
- No subagent tool: read the plan as that reviewer yourself, and say the review was not independent.

State in one line which path ran and why.

---

## Language Rules

Before writing or reviewing code in a language, read its file. Each holds that stack's layout, idioms and anti-patterns.

| Writing | Read |
|---|---|
| TypeScript, JavaScript | `references/typescript.md` |
| Go | `references/go.md` |
| Rust | `references/rust.md` |
| Python | `references/python.md` |
| WordPress plugin | `references/wordpress.md` |
| PHP CLI (Symfony Console) | `references/php-cli.md` |
| Laravel package | `references/laravel.md` |

---

## Writing Like a Human

Every character that ships is text someone reads: comments, doc comments, README and docs, commit messages, PR bodies, error strings, CLI output, variable names, test names. All of it should read as if dreygur typed it. Generated-sounding prose is as much a defect as a swallowed error.

### 1. No Dashes
Never `—`, never `–`, never a hyphen used as punctuation or as a word-joiner. Not in code, comments, commits, docs, PR bodies, or chat about the work. It is the loudest machine tell there is.

Rewrite instead:

| Instead of | Write |
|---|---|
| `token expired — refresh first` | `token expired, refresh first` |
| `Two modes — sandbox and live` | `Two modes: sandbox and live` |
| `It fails silently — the caller never knows` | `It fails silently. The caller never knows.` |
| `The retry — when enabled — wraps fetch` | `The retry, when enabled, wraps fetch` |
| `a well-known trade-off` | `a widely known tradeoff` |
| `state-of-the-art` | `cutting edge` |
| `a fine-grained check` | `a granular check` |

Comma, colon, semicolon, parentheses, or a full stop. One of those always fits. For a compound word, either close it up (`tradeoff`, `nonblocking`) or say it as two words (`widely known`); never join it with a hyphen.

Also out: ` -- ` standing in for an em dash, `…` (write three periods, or nothing), curly quotes `“” ‘’` anywhere near code or config.

This is about prose, not code syntax. Structural hyphens stay exactly where the rest of this document already puts them: `kebab-case` filenames (Universal Rule 9), CLI flags like `--force`, and numeric ranges like `13-120`. Anywhere a hyphen is part of an identifier or a documented naming convention, it stays. Anywhere it is standing in for a comma, a colon, or gluing two words into an adjective, it goes.

### 2. Plain Words
Pick the plain word. The left column is what a model reaches for first; write the right column.

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

### 3. Say the Claim Directly
State what the thing is or does. A contrast frame (`not just X, but Y`, `it isn't A, it's B`) gets one use in a long document at most.

```
// wrong
// This isn't a cache, it's a coalescer.
// right
// Coalesces concurrent refreshes so only one request goes out.
```

### 4. Start at the Point, Stop at the End
- Open with the answer or the change.
- End at the last sentence that carries information.
- A document gets wrapper headings only past two pages.
- Pick a position, or say plainly what it depends on.
- Commits, comments, and docs state facts about the work, nothing about how the author feels.

### 5. Vary the Shape
Uniform output reads generated even when every word is fine.

- A list holds as many items as there are.
- Bold a lead-in only where it earns attention.
- Open consecutive sentences in different ways.
- Mix sentence lengths. A short one lands harder after a long one.
- Write prose where reasoning flows; use a table or list where items are parallel.

### 6. Plain Text Only
Code, comments, commit messages, docs, and CLI output are plain text. The log prefixes `[+]` `[-]` `[!]` `[*]` are the whole visual vocabulary.

### 7. Comments Are Notes, Not Narration
A comment records why, or a constraint the code cannot show. What the next line does, the next line already says; structure is carried by ordering (see The Shape of a File, rule 5).

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
- Imperative mood, present tense: `fix token refresh race`.
- Say what changed and, when it is not obvious, why. A one line change gets a subject and nothing else.
- Body length matches the diff: a short paragraph in plain sentences for a real change.
- The dash rule (rule 1) covers subject and body.
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
Open with what the thing does and the first command that runs it. Examples use real values. Every section answers a question a reader actually has.

### 10. Identifiers and Strings Carry the Same Rule
Name a thing for what it does: `syncPlaylist`. Error messages state the failure and the input, flat: `invalid order id: %q`.

---

## Reviewing Code: Flag These

To review a diff or branch, follow `references/review.md`. This list is its Standards checklist.

- Missing types/interfaces for exported items
- DB calls in handlers (wrong layer)
- Raw error strings instead of typed errors
- Magic values not in constants
- Swallowed errors (`catch {}`, ignored `Result`, `except: pass`)
- Missing doc comments on exports
- Wrong filename casing
- Raw `console.log`, `print`, `println!()` in library code
- Services instantiated per-call instead of singleton export
- Anything on the "Anti-Patterns to Avoid" list in the language's reference file or `references/testing.md`
- Helper defined *below* its caller
- Constants buried mid-file instead of at the top
- Section-divider or block-label comments (`// ---- Helpers ----`)
- Casts that silence the type checker (`as any`, `/** @type {X} */ (expr)`)
- New function with no test that actually runs it
- Test doubles named `fake_*` instead of `mock_*`
- Any AI/agent attribution in commits, comments, or docs
- A secret or personal data in code, logs, commits, or fixtures
- Dashes anywhere in prose: em dash, en dash, or a hyphen joining two words into a compound (code, comment, doc, commit, PR body)
- Curly quotes or `...` characters in text
- Stock model vocabulary (delve, leverage, robust, seamless, ensure that, it's worth noting)
- `not just X, but Y` phrasing, or any repeated antithesis frame
- Comment that restates the line below it
- Commit subject in past tense, or a bulleted essay on a two-line diff
- Emoji in code, commits, docs, or CLI output
- Preamble or a summary paragraph on a doc that does not need one
- Nested `if` three or more levels deep where early return would flatten it
- Boolean parameter at a call site instead of an enum
- Function name at or over 30 characters
- A field or method made `public`/`internal` without being asked
- A controller, handler, or UI component calling a DB query, driver, or raw socket directly, skipping the service layer
- A layer that only forwards to the next one (fails the deletion test)
- An interface with one implementation and no boundary mock
- Missing `{}` on a single-line `if`
- Comment or edit touching code unrelated to the current task
- Bug-fix diff with no failing test that preceded it
- Silent assumption or silently chosen interpretation of an ambiguous request
- Abstraction, option, or feature beyond what was asked (single use strategy classes, unrequested config, error handling for impossible cases)
- Drive by edit: reformatted lines, changed quote style, added type hints or docstrings, rewritten comments outside the task
- Pre-existing dead code deleted, or orphans from the change left behind
- Task with no verifiable success criteria or no plan with verify steps
- A file read, searched or edited through the shell or a script where a native file tool would do it at the same or lower cost

## Commits & Attribution

- **Never** add agent attribution anywhere. No `Co-Authored-By: Claude`, no "Generated with Claude Code", no robot footers. Not in commit messages, PR bodies, code comments, or docs. The history reads as dreygur's own work. Where the repo supports it, set `attribution.commit` and `attribution.pr` to `""` in `.claude/settings.json` rather than relying on memory.
- Finish every outstanding request **before** committing. A commit is a checkpoint; reaching it with an open ask captures the wrong state.
- Edit `README` files only on request. Requested prose goes in chat unless a file is named.

## Additional Resources
- **`references/patterns.md`**: file ordering drill and before/after rewrites for machine-sounding prose
- **`references/testing.md`**: seams, mocking at boundaries, test anti-patterns
- **`references/review.md`**: two axis review procedure (Standards, Spec) and the smell baseline
- **`references/behavior-examples.md`**: wrong/right examples for each Karpathy principle
