---
name: commit-workflow
description: >
  Commit discipline with graph linking. MERGE GitCommit nodes and link to
  active milestones, findings, and decisions. Verify before committing,
  never push unless asked.
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

## Verification

- [ ] Each commit represents one logical change
- [ ] Tests pass before every commit
- [ ] No push to remote without explicit user request
- [ ] Commit message follows conventional format

## Red Flags

Stop and reassess if you observe:
- Pushing to remote without explicit user instruction
- Committing without running the test suite first
- Batching unrelated changes into a single commit
- Using `--no-verify` to skip pre-commit hooks

## Graph Integration

### Graph write: commit linking

After every commit, MERGE a GitCommit node and link it to active reasoning.
This runs within the calling skill's session (no separate session needed).

```gql
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET
  c.project = $project,
  c.short_sha = $short_sha,
  c.message = $commit_message,
  c.author = $author,
  c.date = date(),
  c.branch = $branch
```

Query for active milestone and link if found:

```gql
MATCH (m:Milestone {status: 'in_progress'})
WHERE m.project = $project
RETURN m.name, id(m) AS milestone_id
```

If a milestone is active, create `:part_of` edge from commit to milestone.

If the commit implements a Decision or fixes a Finding from the current
session, create `:implemented_by` or `:fixed_by` edges per the patterns
in [selene-patterns.md](../_selene/selene-patterns.md).

### Context bridge: announce commit to peers

After the graph write, share the commit with other active agents via the
context bridge. This lets concurrent agents know what changed:

```
share_context(
  author: "<my agent id>",
  context_type: "decision",
  scope: "<project>",
  targets: ["<files changed>"],
  content: "<commit message> (sha: <short_sha>)",
  visibility: "project",
  ttl_ms: 86400000
)
```

Also release any intents that covered the committed files:

```
release_intent(agent_id: "<my agent id>")
```

This is automatic — no user action needed. The commit itself is the
natural release point for file-level intents.

## Supporting files

- [selene-patterns.md](../_selene/selene-patterns.md) — commit linking patterns

## Guidance

The commit-at-milestones rule serves two purposes: it creates clean rollback
points during implementation, and it produces a readable history that maps to
logical changes rather than "WIP" or "fix everything" commits.

The no-push rule exists because pushing affects shared state. The user
maintains full control over what reaches the remote.
