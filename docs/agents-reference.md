# Agents Reference

Complete reference for all 10 agents in the justin-tools plugin.

## How Agents Work

Agents are specialized subagents with:
- **Preloaded skills** - full skill content injected at startup (not just
  available for invocation)
- **Persistent memory** - knowledge accumulated across sessions, stored
  at `~/.claude/agent-memory/<agent-name>/`
- **Tool restrictions** - some agents are read-only for safety
- **High effort** - configured for thorough analysis

Claude delegates to agents automatically based on the task, or you can
invoke them directly with `@agent-name` in your prompt.

## Agent Catalog

### feature-architect

| Field | Value |
|:--|:--|
| Skills | feature-design, plan-verify, technical-writing |
| Tools | Full access |
| Memory | Persistent (user scope) |
| Color | Blue |

The most comprehensive agent. Drives features from idea through research,
design, and implementation planning. Preloads three skills so it can
design, verify, and write with consistent style in a single context.

Remembers across sessions: design preferences, past decisions, project
conventions, workflow choices (execution style, commit strategy).

Runs plan-verify inline (cannot delegate to subagents).

### researcher

| Field | Value |
|:--|:--|
| Skills | research, technical-writing |
| Tools | Full access (web search, Consensus, Context7) |
| Memory | Persistent (user scope) |
| Color | Cyan |

Investigates questions using 4 research modes: technical deep-dive,
multi-perspective analysis, competitive landscape, and documentation
lookup. Uses web search, academic papers (Consensus), and library docs
(Context7).

Saves findings to `_agentskills/research/`. Caches competitive landscapes
and technology evaluations in persistent memory.

### debate-lead

| Field | Value |
|:--|:--|
| Skills | debate, technical-writing |
| Tools | Full access |
| Memory | Persistent (user scope) |
| Color | Orange |

Orchestrates structured multi-perspective debates. When agent teams are
available, spawns real teammates per perspective for genuine inter-agent
debate. Falls back to single-agent simulation when teams are unavailable.

3-phase methodology: independent generation (Toulmin structure),
adversarial exchange (decreasing contentiousness), synthesis (scoring +
bias check).

Saves findings to `_agentskills/debates/`.

### deep-reviewer

| Field | Value |
|:--|:--|
| Skills | deep-review |
| Tools | Read-only (Write, Edit, NotebookEdit disallowed) |
| Memory | Persistent (user scope) |
| Color | Purple |

Post-implementation code review using 13 categories across 4 groups:
structural completeness, correctness, concurrency/performance, integration.
Follows Google's review navigation order.

Read-only by design. Finds and reports issues; the main conversation
handles fixes. Updates memory with patterns discovered during reviews.

### security-auditor

| Field | Value |
|:--|:--|
| Skills | safety-checks |
| Tools | Read-only (Write, Edit, NotebookEdit disallowed) |
| Memory | Persistent (user scope) |
| Color | Red |

STRIDE-based security audit. Checks all 9 categories: resource bounds,
input validation, auth/authz, secret handling, cryptography, supply chain,
memory safety, container/infra, error handling. Loads language-specific
patterns (Python, Rust, JavaScript) and secret detection regex.

Read-only by design. Reports findings to main conversation for fixes.

### code-analyzer

| Field | Value |
|:--|:--|
| Skills | modularize, code-standards |
| Tools | Read-only (Write, Edit, NotebookEdit disallowed) |
| Memory | Persistent (user scope) |
| Color | Cyan |

Structural analysis of codebases for modularization opportunities. Scans
for oversized files, complexity hotspots, circular dependencies, god
classes/structs, visibility over-exposure, and coupling issues. Produces
a prioritized report gated by aggressiveness level (conservative, moderate,
aggressive).

Read-only by design. Reports findings to main conversation for execution.
Persistent memory tracks structural patterns across sessions.

### debugger

| Field | Value |
|:--|:--|
| Skills | debug, safety-checks |
| Tools | Full access |
| Memory | Persistent (user scope) |
| Color | Red |

Systematic debugging using the scientific method. Reproduces, forms
hypotheses with tracking table, isolates via git bisect and targeted
tests, applies 5 Whys for root cause, writes regression test, implements
fix, verifies.

Safety-checks preloaded to catch security-related root causes. Persistent
memory tracks recurring failure patterns and effective debugging approaches.

### test-engineer

| Field | Value |
|:--|:--|
| Skills | test-strategy, technical-writing |
| Tools | Full access |
| Memory | Persistent (user scope) |
| Color | Yellow |

Test planning and generation. Analyzes code, identifies coverage gaps,
generates test cases with boundary analysis, suggests property-based tests,
and writes complete runnable test code.

Persistent memory remembers project test patterns, common edge cases,
and effective property strategies.

### release-manager

| Field | Value |
|:--|:--|
| Skills | release-prep, docs-sync, technical-writing |
| Tools | Full access |
| Memory | Persistent (user scope) |
| Color | Green |

End-to-end release preparation. Generates changelogs, runs semver-checks,
suggests version bumps, verifies documentation, handles multi-crate
ordering, runs pre-release checklist.

Does not push tags or publish. The user handles that. Persistent memory
tracks release conventions and multi-crate ordering per workspace.

### onboarder

| Field | Value |
|:--|:--|
| Skills | project-onboard, technical-writing |
| Tools | Full access |
| Memory | Persistent (user scope) |
| Color | Green |

Guides users through setting up an existing project to work with
justin-tools. Explores the project first, then walks through gaps one
step at a time: gitignore setup, CLAUDE.md creation, relevant skills
introduction, CI alignment.

Persistent memory tracks which projects have been onboarded, user
preferences from other projects, and common patterns that speed up
future onboarding.

Conversational approach: explore first, summarize, one step at a time,
respect existing conventions, target 5-10 minutes.

## Agent Teams

When `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is available, agents can be
used as teammate types for parallel work:

```
Create a team to review this phase. Spawn a deep-reviewer teammate
and a security-auditor teammate. Have them review independently.
```

See the `team-coordination` skill for patterns: parallel review,
parallel research, multi-perspective debate, wave-based implementation.
