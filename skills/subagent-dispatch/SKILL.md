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

### Classify task complexity before dispatch

Before writing the subagent prompt, classify the task to set appropriate
effort and model parameters on the Agent tool:

| Complexity | Effort | Model | Examples |
|:--|:--|:--|:--|
| **Simple** | low | haiku | Formatting, linting, single-file mechanical changes, file moves/renames, import updates, scaffolding from templates |
| **Standard** | default | inherit | Feature implementation within existing patterns, test generation, documentation, bug fixes with known root cause |
| **Complex** | high | opus | Cross-module changes, race conditions, security-sensitive code (auth, crypto, validation), performance optimization, unexpected behavior spanning multiple components |

Default to standard. Only escalate to complex when the task involves
ambiguity, multi-component interaction, or security implications. Only
drop to simple for purely mechanical work with no judgment calls.

**Factor in error cost, not just complexity.** A simple classification task
that gates a critical decision should use a stronger model than a complex
but low-stakes generation task.

### Sequential dispatch only

Dispatch one implementation subagent at a time. Never run multiple
implementation agents in parallel.

**Why:** Multi-agent error amplification is 17x in unstructured topologies,
not linear (NeurIPS 2025). Parallel implementation agents modify overlapping
files, creating merge conflicts and inconsistent state. Sequential dispatch
with review between tasks catches errors before they cascade.

**Constraint:** Subagents cannot spawn other subagents. Chain tasks from
the main conversation or use agent teams for parallel work.

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

### Budget controls

Set `maxTurns` on every implementation subagent to prevent unbounded
token burn. Guidelines:

- **Simple tasks:** 15-25 turns
- **Standard tasks:** 30-50 turns
- **Complex tasks:** 50-80 turns

If a subagent hits its turn limit without completing, do not retry it
with the same prompt. Instead, spawn a fresh replacement with additional
context about what the previous attempt accomplished and where it stalled.
A new agent gets a clean context window without error accumulation.

### Use worktree isolation for risky changes

Set `isolation: worktree` on the Agent tool when:
- The task modifies core infrastructure files
- You want free rollback (delete the worktree to discard changes)
- Multiple subagents need to work on the same repo without conflicts

Worktrees create a temporary git branch with a full checkout. If the
subagent makes no changes, the worktree is auto-cleaned. Be mindful of
disk usage on large repos.

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

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Run tasks in parallel for speed" | Error amplification is 17x (NeurIPS 2025). Parallel agents multiply mistakes. Sequential with review catches them. |
| "Skip review between tasks, they're independent" | Independence is assumed, not proven. Reviews catch unexpected interactions and scope drift. |
| "Subagent can infer CI requirements" | Inference fails silently. Explicit CI verification in the prompt is one line that prevents broken commits. |
| "Retry stalled agent instead of spawning fresh" | Stalled agents carry corrupted context. Fresh spawns start clean. |
| "Formatting is optional, focus on logic" | Formatting is the most commonly skipped step and creates the most cleanup work. Include it. |

## Guidance

**Review between tasks is not optional ceremony.** Automated failure
attribution is only 53.5% accurate (NeurIPS 2025). You cannot rely on
detecting which agent failed after the fact. Catching errors between tasks
is cheaper than debugging cascading failures.

**Prefer the main conversation.** Before dispatching a subagent, ask
whether the primary agent could do the work directly. Subagents are best
for: isolating verbose output (test runs, log processing), preserving
main context (large codebase exploration), and parallel read-only review.
If the task involves decisions the user should weigh in on, keep it in
the main conversation.

**Formatting is the most commonly skipped step.** If the project has a
non-default formatter config (like a `rustfmt.toml` with stricter rules),
mention it explicitly in the subagent prompt.

**Spawn replacements, don't retry.** When a subagent fails or stalls,
a fresh agent with additional context outperforms asking the stuck agent
to recover. Context reset prevents hallucination accumulation.
