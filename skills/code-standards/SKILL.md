---
name: code-standards
description: >
  Language-specific best practices, anti-patterns, and linting rules for
  Rust, Python, and JS/TS. Auto-applies during development to catch
  complexity, naming, and structural issues before they accumulate.
---

## Purpose

Enforce language-specific coding standards, catch anti-patterns early, and
guide idiomatic code. Operates as background knowledge during development.
When invoked manually, audits a file or scope against the full checklist.

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
4. Check every item in the standards against the target code
5. Report findings grouped by category:
   - **Naming**: convention violations, stuttering, misleading names
   - **Complexity**: functions/classes exceeding thresholds
   - **Structure**: anti-patterns, coupling, missing abstractions
   - **Idioms**: non-idiomatic patterns with idiomatic alternatives
   - **Linting**: missing or misconfigured lint rules
6. For each finding: file, line, category, what to change, why

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

## Supporting files

- [rust-standards.md](rust-standards.md) - Rust naming, visibility, error
  handling, clippy config, idioms
- [python-standards.md](python-standards.md) - Python naming, typing, imports,
  ruff config, idioms
- [javascript-standards.md](javascript-standards.md) - JS/TS naming, types,
  ESLint config, framework conventions

Load ONLY the file matching the detected project language. Never load
all three. For polyglot projects, load one file per analysis pass.
