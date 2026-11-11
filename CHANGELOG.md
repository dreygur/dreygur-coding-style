# Changelog

## 2.15.0
Add Kysely client, schema, repository and migration patterns, and the rule for choosing between Drizzle and Kysely. Merge the duplicate Drizzle schema and logger sections in `references/typescript.md`.

## 2.14.1
Merge the two branded ID sections in `references/typescript.md`.

## 2.14.0
- Rename the repo to `dreygur/skills`, the plugin to `dreygur` and the skill to `skill`: `/dreygur:skill` as a plugin, `/dreygur-skill` through npx.
- Move each language's rules and patterns into its own reference file.
- State rules as targets instead of bans; keep bans for attribution, dashes, type checker casts and secrets. Allow shell on files when it costs fewer tokens.
- Add `references/testing.md`: seams, mocking at boundaries, test anti-patterns.
- Add the deletion test for layers that only forward, and require a second implementation (or boundary mock) for an interface.
- Add `references/review.md`: two axis review (Standards, Spec) and Fowler smell baseline.
- Add domain glossary rule, PR body format and secret redaction guardrail.
- Add plugin marketplace, Codex manifest, changelog and out of scope log. Author is Rakibul Yeasin, https://dreygur.me; email dropped.

## 2.13.2
Fix flagged shell snippet in PHP CLI pattern.

## 2.13.1
Quote skill description so npx install parses it.

## 2.13.0
Add native file tools rule.

## 2.12.0
Add EGM plan review behavior.

## 2.11.0
Add structured thinking behavior.

## 2.10.0
Add Karpathy behavior guidelines.

## 2.9.0
Add AGENTS.md rules: terseness, layering, failing test first for bug fixes.

## 2.8.0
Ban em dashes, en dashes, hyphenated compounds and machine sounding prose.

## 2.7.0
Add file ordering, testing and cast rules.

## 2.6.0
Cut skill size 42% for token efficiency.

## 2.5.0
Add PHP Symfony Console CLI patterns.

## 2.4.0
Add minimal WordPress plugin and Vue 3 with Vite patterns.

## 2.3.0
Add WordPress plugin patterns.

## 2.2.0
Add Laravel package patterns.

## 2.1.0
Add TypeScript monorepo, tRPC and Drizzle patterns.
