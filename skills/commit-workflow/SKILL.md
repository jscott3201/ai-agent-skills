---
name: commit-workflow
description: >
  Commit discipline: milestone commits, verify before committing, never push
  unless asked. Background rules for all implementation work.
user-invocable: false
---

## Purpose

Enforce consistent commit practices during implementation work. Commits should
be frequent, verified, and well-scoped. Pushing is the user's responsibility
unless they explicitly ask otherwise.

## Instructions

Apply these rules during all implementation work:

### Commit cadence

- Commit at each logical milestone, not batched at the end
- A milestone is a discrete, working change: a new function with tests passing,
  a refactored module that compiles, a bug fix with its regression test
- If in doubt, commit more often. Small commits are easier to review, revert,
  and bisect.

### Before every commit

Run CI verification for the project's language:

**Rust:**
```bash
cargo fmt --all
cargo clippy --workspace --all-features --all-targets -- -D warnings
cargo test --workspace --all-features
```

**Python:**
```bash
ruff format .
ruff check . --fix
pytest
```

**JavaScript/TypeScript:**
```bash
npx prettier --write .
npx eslint .
npm test
```

Do not commit if verification fails. Fix the issue first.

### Commit messages

Use conventional commit format:

```
feat(scope): add session timeout handling
fix(parser): handle unterminated string literals
refactor(graph): split NodeStore into read and write paths
```

- First line: imperative mood, under 72 characters
- Body (if needed): explain why, not what
- Scope matches the crate, module, or component changed

### Never commit _agentskills/

Do not stage or commit files in `_agentskills/`. This directory contains
working documents (plans, design docs, research, debates) that are not
part of the source code. Only commit them if the user explicitly asks.

### Never push

Do not push to the remote repository. The user pushes when ready.

The only exception: if the user explicitly asks to push in the current
conversation. A prior push approval does not carry forward - each push
needs explicit approval.

### Branch strategy

Work directly on main unless the user specifies a branch. If the user says
to create a branch, do so and work there.

## Red Flags

Stop and reassess if you observe:
- Committing without running the CI verification sequence
- Multiple features or fixes in a single commit
- Pushing to remote without explicit user approval in this conversation
- Staging `_agentskills/` files

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Small change, CI verification unnecessary" | Small changes cause big outages. A 1-line typo can break the build. |
| "Batch related features into one commit" | Atomic commits are revertible. Batched commits force all-or-nothing rollbacks. |
| "Reviewed carefully, skip tests" | You catch logic errors. Tests catch integration, regression, and edge-case errors you didn't consider. |
| "User asked to commit, probably wants a push too" | Commit is local and reversible. Push is shared and permanent. Never conflate the two. |
| "Just docs, skip the full suite" | Doc changes can break doc-tests, links, and build steps. Run the suite. |

## Guidance

The commit-at-milestones rule serves two purposes: it creates clean rollback
points during implementation, and it produces a readable history that maps to
logical changes rather than "WIP" or "fix everything" commits.

The no-push rule exists because pushing affects shared state. The user
maintains full control over what reaches the remote.
