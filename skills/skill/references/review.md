# Reviewing Code

A review runs on two axes and reports them separately. Standards: does the code follow dreygur's rules? Spec: does it do what the issue asked? A change can pass one and fail the other, and a merged list lets one hide the other. Procedure and smell baseline adapted from `mattpocock/skills` (code-review).

## 1. Pin the Diff

Review against the ref dreygur names: a commit, branch, tag, or `main`. None named: ask.

```bash
git rev-parse <ref>
git diff <ref>...HEAD
git log <ref>..HEAD --oneline
```

Stop here if the ref does not resolve or the diff is empty.

## 2. Find the Spec

Take the first that exists:

1. Issue references in the commit messages (`#123`, `Closes #45`, `!67`), read with `gh issue view` or `glab issue view`.
2. A path dreygur passed.
3. A spec under `docs/`, `specs/` or `.scratch/` matching the branch or feature.
4. Ask. If there is no spec, the Spec section says so and stays empty.

## 3. Standards

Check the diff against:

- "Reviewing Code: Flag These" in SKILL.md
- the "Anti-Patterns to Avoid" list in each touched language's reference file, and in `references/testing.md`
- any standards file the repo has (`CONTRIBUTING.md`, `CODING_STANDARDS.md`, `AGENTS.md`)

Cite the rule behind each finding. Skip what a linter or formatter in the repo already enforces.

Then run the smell baseline over the diff.

### Smell Baseline

From Fowler, _Refactoring_, chapter 3. Each one is a judgement call, written as "possible Feature Envy", never as a hard violation. A documented rule wins: where dreygur's style endorses what a smell would flag (the layer stack, singleton exports, map dispatch), skip the smell.

- **Duplicated Code**: the same logic shape in more than one hunk or file. Extract it and call it from both.
- **Feature Envy**: a function that reads another object's data more than its own. Move it onto that data.
- **Data Clumps**: the same few fields or params travelling together. Bundle them into one type.
- **Primitive Obsession**: a string or number standing in for a domain concept. Give the concept its own type, as branded IDs do for entity IDs.
- **Repeated Switches**: the same `switch` or `if` cascade on the same value at several sites. Replace with one shared map or polymorphism.
- **Shotgun Surgery**: one logical change forces scattered edits across many files. Gather what changes together into one module.
- **Divergent Change**: one file edited for several unrelated reasons. Split it so each part changes for one reason.
- **Message Chains**: `a.b().c().d()` walks the caller depends on. Hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly delegates onward. Same check as the deletion test in "Layers Talk Only to Their Neighbor".
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. Use composition.

## 4. Spec

Quote the spec line behind each finding. Report:

- requirements missing or partly done
- behavior in the diff nobody asked for
- requirements that look done but are implemented wrong

## 5. Report

Two headings, `## Standards` and `## Spec`. Under Standards, rule violations come before smells. Keep each finding to a line: file and line, the problem, the fix.

Close with one line: the count per axis and the worst finding in each. Rank inside an axis only.
