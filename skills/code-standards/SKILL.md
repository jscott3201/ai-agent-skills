---
name: code-standards
description: >
  Language-specific standards plus graph-sourced conventions. Reads Convention
  nodes from SeleneDB, enforces project rules alongside built-in standards.
  Promotes recurring violations to new conventions.
---

## Purpose

Enforce language-specific coding standards, catch anti-patterns early, and
guide idiomatic code. Operates as background knowledge during development.
When invoked manually, audits a file or scope against the full checklist.

**When NOT to use:** Reviewing completed features for correctness (use
`deep-review`). Security concerns (use `safety-checks`). The user is
writing throwaway prototyping code they explicitly said is temporary.

## Quick reference

### Universal anti-patterns

These apply across all three languages:

| Anti-pattern | Signal | Fix |
|:--|:--|:--|
| **God class/struct** | 20+ methods, 10+ fields, mixed concerns | Extract collaborator classes |
| **Utility dumping ground** | `utils.py`, `helpers.ts`, catch-all modules | Move utilities next to consuming feature |
| **Deep nesting** | 4+ levels of if/match/for | Early returns, extract functions |
| **Primitive obsession** | Strings/ints where domain types belong | Introduce newtype/branded type/dataclass |
| **Over-abstraction** | Wrapper that adds no behavior, single-use generic | Inline it; wait for 3rd occurrence |
| **Dead code** | Unused functions, commented-out blocks | Delete it (git has history) |
| **Long parameter lists** | 5+ function parameters | Config/options struct or builder |

### Language-specific standards

Detect the project language. Load ONLY the single standards file for
that language:

- [rust-standards.md](rust-standards.md) - Naming, visibility, error handling,
  clippy configuration, idiomatic patterns
- [python-standards.md](python-standards.md) - Naming, typing, imports, ruff
  configuration, idiomatic patterns
- [javascript-standards.md](javascript-standards.md) - Naming, TypeScript
  patterns, ESLint configuration, framework conventions

## Instructions

### As background knowledge (default)

When writing or reviewing code, apply the relevant language standards
automatically:

1. Follow naming conventions for the detected language
2. Keep functions under the complexity thresholds
3. Use idiomatic patterns (not transliterated patterns from other languages)
4. Flag anti-patterns from the checklist above
5. Suggest linter rules when complexity violations are detected

### Manual audit mode

When invoked with `$ARGUMENTS`:

1. Identify the target scope (file, directory, or full codebase)
2. Detect the primary language
3. Load the relevant language standards file
4. **Load project conventions from graph.** Query active conventions
   scoped to the detected language, prose, or all:

   ```gql
   MATCH (c:Convention {active: true})
   WHERE c.project = $project
     AND (c.scope = $language OR c.scope = 'all' OR c.scope = 'prose')
   RETURN c.rule, c.severity, c.rationale, c.scope
   ORDER BY c.severity
   ```

   Check these conventions alongside the built-in standards. Convention
   violations use the severity recorded in the convention node.

5. Check every item in the standards against the target code
5. Triage findings with the user **one at a time**, starting with the
   highest-severity issues. For each finding:

   > **[Category]:** [brief description]
   > `file:line` — [what the code does now]
   >
   > **Suggested fix:** [what to change and why]
   >
   > Options:
   > 1. **Fix** — apply the change now
   > 2. **Skip** — not worth changing
   > 3. **Defer** — track for later
   >
   > I recommend [option] because [reason].

   Wait for the user's decision before presenting the next finding.
   Apply accepted fixes immediately so subsequent findings reflect the
   current state of the code.

6. After all findings are triaged, summarize: N fixed, N skipped,
   N deferred

## Complexity thresholds

| Metric | Rust | Python | JS/TS |
|:--|:--|:--|:--|
| Function length | 60 lines | 40 statements | 50 lines |
| Cyclomatic complexity | 15 cognitive | 8 McCabe | 10 cyclomatic |
| Parameters | 5 | 4 | 3 |
| Nesting depth | 4 | 4 | 3 |
| Class/struct fields | 7 | 7 attributes | 8 props |
| Public methods | - | 12 | - |
| Return statements | - | 6 | - |
| Branches | - | 12 | - |

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Code works, style issues can wait" | Style debt compounds faster than feature debt. Inconsistent code slows every future change. |
| "Almost at threshold, no need to refactor" | Thresholds exist because code just over them degrades fast. Respect the line. |
| "Linter passed, standards are satisfied" | Linters check syntax. Standards check design, naming, and patterns that linters can't see. |
| "Load all language files for completeness" | Irrelevant standards create noise and waste context. Load only what applies. |

## Red Flags

Stop and reassess if you observe:
- Applying fixes to code you didn't change (stay in scope)
- Overriding project-specific conventions with generic rules
- Flagging style issues that linters already catch
- Adding type annotations or comments to unchanged code

## Verification

- [ ] Correct language-specific standards file loaded (only one)
- [ ] Every item in the checklist checked (not sampled)
- [ ] Findings triaged one at a time with user
- [ ] Accepted fixes applied immediately before continuing

## Guidance

**Idiomatic code reads naturally to practitioners of that language.**
A Python function should not look like translated Java. A Rust function
should not fight the borrow checker with excessive `.clone()`. A TypeScript
function should not use `any` to avoid writing types.

**Linters are guardrails, not goals.** Passing all lint rules does not
mean the code is good. Failing a lint rule does not mean the code is bad.
Use the thresholds as conversation starters, not hard rules.

**Fix the pattern, not the instance.** When a complexity violation appears,
the function is likely doing too much. Extracting a helper and suppressing
the lint misses the point. Understand *why* the function is complex and
address the root cause.

## Graph Integration

### 0. Context recall

Create a session per [selene-integration.md](../_selene/selene-integration.md).
Query active conventions (Step 4 above) and check for recurring violations:

```gql
MATCH (f:Finding {category: 'code-standards'})
WHERE f.project = $project AND f.triage = 'fix_now'
WITH f.summary AS summary, count(*) AS occurrences
WHERE occurrences >= 3
RETURN summary, occurrences
ORDER BY occurrences DESC
```

If recurring violations are found, suggest convention promotion.

### Graph write: convention promotion

When the same violation pattern appears 3+ times, prompt user to promote
to a Convention node per the graduation pattern in
[selene-patterns.md](../_selene/selene-patterns.md).

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) — SeleneDB detection, sessions, auto-recall
- [rust-standards.md](rust-standards.md) - Rust naming, visibility, error
  handling, clippy config, idioms
- [python-standards.md](python-standards.md) - Python naming, typing, imports,
  ruff config, idioms
- [javascript-standards.md](javascript-standards.md) - JS/TS naming, types,
  ESLint config, framework conventions

Load ONLY the file matching the detected project language. Never load
all three. For polyglot projects, load one file per analysis pass.
