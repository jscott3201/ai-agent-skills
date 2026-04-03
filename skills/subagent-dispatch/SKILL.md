---
name: subagent-dispatch
description: >
  Rules for dispatching implementation subagents: sequential only, review
  between tasks, include CI verification in prompts. Project CLAUDE.md
  may restrict or forbid implementation agents.
user-invocable: false
---

## Purpose

Prevent common subagent pitfalls: parallel dispatch causing merge conflicts,
missing formatting in committed code, and tasks that lack sufficient context
for independent execution. Project-level rules may further restrict or forbid
implementation subagents entirely.

## Instructions

Apply these rules whenever dispatching subagents for implementation work.
Research and review subagents (Explore, Plan) are not subject to these rules.

### Check project restrictions first

Before dispatching an implementation subagent, check the project's CLAUDE.md
for any restrictions on agent usage. Some projects forbid implementation
subagents entirely (research/review only). Respect those rules.

### Sequential dispatch only

Dispatch one implementation subagent at a time. Never run multiple
implementation agents in parallel.

**Why:** Parallel implementation agents modify overlapping files, creating
merge conflicts and inconsistent state. Sequential dispatch with review
between tasks avoids this entirely.

### Review between tasks

After each subagent completes:

1. Review the subagent's output and changes
2. Verify the changes are correct and complete
3. Confirm tests pass in the current state
4. Only then dispatch the next subagent

Do not batch-dispatch multiple tasks without review between them.

### CI verification in every prompt

Every implementation subagent prompt must include the full CI verification
sequence for the project's language:

**Rust:**
```
Before committing: cargo fmt --all && cargo clippy --workspace --all-features
--all-targets -- -D warnings && cargo test --workspace --all-features
```

**Python:**
```
Before committing: ruff format . && ruff check . && pytest
```

**JavaScript/TypeScript:**
```
Before committing: npx prettier --write . && npx eslint . && npm test
```

Subagents reliably run tests but frequently skip formatting. The explicit
format step prevents follow-up formatting commits.

### Self-contained tasks

Each subagent task must include all context needed for independent execution:

- Exact file paths to create or modify
- Complete code to write (not references to other tasks)
- Specific verification commands with expected results
- Commit message in conventional format

A subagent starts with zero context about prior tasks. Everything it needs
must be in its prompt.

## Consider agent teams for parallel work

If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is available (check settings or
environment), agent teams may be a better fit than sequential subagents for
genuinely parallel work.

**Recommend teams when:**
- The implementation plan has independent waves with tasks touching
  different files
- Multiple review perspectives are needed simultaneously
  (deep-reviewer + security-auditor)
- Research benefits from parallel investigation

**Keep using sequential subagents when:**
- Tasks are sequential (each depends on the previous)
- Tasks touch the same files
- Token budget is a concern (teams use significantly more tokens)

See the `team-coordination` skill for team patterns and guidance.

## Guidance

The sequential-with-review pattern is slower than parallel dispatch but
produces consistently correct results. The time saved by parallel execution
is lost to conflict resolution and debugging inconsistencies.

Formatting is the most commonly skipped step in subagent work. If the project
has a non-default formatter config (like a `rustfmt.toml` with stricter rules),
mention it explicitly in the subagent prompt.
