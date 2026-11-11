# Extended Patterns & Anti-Patterns

## Universal: File Ordering

Dependencies live above the function that uses them; the composite is last.

```ts
// wrong: caller first, helpers trailing
export async function syncPlaylist(id: PlaylistId) {
  const tracks = await fetchTracks(id);
  return dedupe(tracks);
}
function fetchTracks(id: PlaylistId) { ... }
function dedupe(tracks: Track[]) { ... }
```

```ts
// right: constants, then leaves, then the composite
const SYNC_TIMEOUT_MS = 30_000;

function dedupe(tracks: Track[]) { ... }
function fetchTracks(id: PlaylistId) { ... }

export async function syncPlaylist(id: PlaylistId) {
  const tracks = await fetchTracks(id);
  return dedupe(tracks);
}
```

Same in Rust and Go. Do **not** follow the local habit of parking helpers at the bottom of the module.

### Anti-Patterns to Avoid (Universal)

| Avoid | Do instead |
|---|---|
| Helper below its caller | Helper above; composite last |
| Constants declared where first used | All constants at file top |
| `// ---------- Helpers ----------` | No label; let the ordering say it |
| `// Scene:` / `// The composite` | Nothing; the shape is felt, not announced |
| One catch-all module | New file per distinct concern |
| `as any` to clear a type error | Runtime guard, or fix the declaration |
| `fake_server`, `FakeStore` | `mock_server`, `MockStore` |
| "Compiles cleanly, shipping it" | Test that executes the function and asserts behavior |


## Prose: Rewriting Machine-Sounding Text

The rules live in SKILL.md under "Writing Like a Human". This is the drill.

### Doc Comment

```ts
// wrong
/**
 * A robust and comprehensive utility that seamlessly handles token refresh —
 * it's worth noting that this ensures concurrent callers are properly serialized.
 */

// right
/**
 * Refreshes the access token. Concurrent callers share one refresh; the rest
 * wait on the mutex and read the new token.
 */
```

What changed: no em dash, no `robust`/`comprehensive`/`seamlessly`/`ensures`, no `it's worth noting`. The second version says what the reader needs and stops.

### README Opening

````md
<!-- wrong -->
# TokenKit

In today's fast-paced development landscape, managing authentication tokens
can be a crucial challenge. TokenKit is a powerful, lightweight library that
empowers developers to seamlessly handle token lifecycles — unlocking a
frictionless auth experience.

<!-- right -->
# TokenKit

Refreshes OAuth tokens and keeps concurrent callers from racing on it.

```bash
pnpm add tokenkit
```
````

### Commit

```
# wrong
feat: Added comprehensive error handling improvements

This commit implements a robust solution that ensures errors are properly
handled throughout the codebase. Key changes:
- Added error handling
- Improved reliability

# right
fix: wrap store errors with the failing key

Callers got a bare "not found" with no way to tell which lookup failed.
```

### Chat and PR Bodies

Same rules. State the change, the reason, and anything the reviewer would otherwise have to discover. No opening restatement of the ticket, no closing summary of the diff they can read.

### Anti-Patterns to Avoid (Prose)

| Avoid | Do instead |
|---|---|
| Em dash, en dash, or hyphenated compound word | Comma, colon, semicolon, parentheses, a new sentence, or say the compound as two words / one closed word |
| `...` character, curly quotes | ASCII, or restructure |
| `not just X, but Y` | Say Y |
| `delve`, `leverage`, `robust`, `seamless`, `comprehensive` | Concrete verbs and nouns |
| `it's worth noting that P` | `P` |
| `In order to X` | `To X` |
| Comment restating the next line | Comment the why, or delete it |
| Every list exactly three items | However many there are |
| Every bullet with a **bold lead-in:** | Bold only where it earns attention |
| Closing "In summary" paragraph | End at the last real sentence |
| Emoji in code, commits, docs, CLI output | `[+]` `[-]` `[!]` `[*]` and nothing else |
| `Oops! Something went wrong.` | `invalid order id: %q` |
