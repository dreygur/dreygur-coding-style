# Out of Scope

Ideas considered and declined, with the reason, so they are not proposed again.

## Workflow skills from mattpocock/skills
Grilling, to-spec, to-tickets, wayfinder, triage, teach, wizard, handoff, retro. This repo is a style guide. Planning, debugging and TDD workflows come from superpowers, EGM and trail, which are installed alongside it.

## ADRs
Decisions are recorded as trail learnings. A `docs/adr/` folder would hold the same thing twice. `GLOSSARY.md` is in scope because it holds meaning, not decisions.

## Confirming test seams on every task
Only new modules and new public interfaces get a seam checkpoint. Asking on every small addition costs more than it catches.

## Skipping a layer that only forwards
The neighbor rule stays so layers remain swappable. A forwarding layer gets logic moved into it or is flagged, via the deletion test.

## One subagent per review axis
Standards and Spec run inline in one thread. Separate subagents cost more tokens per review than the bias they remove.
