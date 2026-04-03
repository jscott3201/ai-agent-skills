---
name: team-coordination
description: >
  Coordination patterns for agent teams. Defines when to use teams vs
  subagents, team structures, and how to assign work. Use when parallel
  work across multiple independent tasks is needed.
user-invocable: false
---

## Purpose

Guide the use of agent teams for genuinely parallel work. Define when teams
add value over sequential subagents, how to structure teams using existing
agent definitions, and how to coordinate work to avoid conflicts.

Agent teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Check
whether this is available before recommending team-based execution.

## When to use teams vs subagents

### Use teams when:

- **Work is genuinely parallel** - multiple independent tasks that benefit
  from simultaneous execution (different files, modules, or concerns)
- **Perspectives need to interact** - teammates should challenge each
  other's findings (multi-perspective analysis, competing hypotheses)
- **Cross-layer coordination** - changes spanning frontend, backend, and
  tests, each owned by a different specialist
- **Research benefits from breadth** - investigating multiple aspects of
  a question simultaneously

### Use subagents when:

- **Tasks are sequential** - each task depends on the previous one's output
- **Results just need to flow back** - no inter-agent discussion needed
- **Work touches the same files** - parallel edits to shared files cause
  conflicts
- **Token budget matters** - teams use significantly more tokens than
  subagents

### Never use teams for:

- Tasks that a single session handles in minutes
- Editing the same file from multiple agents
- Work with many inter-task dependencies (sequential is safer)

## Team patterns

### Parallel review

Spawn specialized reviewers that examine the same codebase from different
angles. Each reviewer uses a different agent type.

**Available agent types for review:**
- `code-reviewer` - structural completeness, error handling, API consumers
- `security-auditor` - STRIDE analysis, auth, input validation, secrets

**Example prompt to lead:**
> "Create a team to review the changes in this phase. Spawn a code-reviewer
> teammate and a security-auditor teammate. Have them review independently,
> then synthesize findings."

**Coordination:** reviewers work independently on the same codebase. No
file conflict risk since both are read-only.

### Parallel research

Spawn multiple researchers investigating different aspects of a question
simultaneously.

**Example prompt to lead:**
> "Create a team to research graph query optimization. Spawn 3 researcher
> teammates: one investigating query planning algorithms, one researching
> index strategies, one analyzing competing implementations."

**Coordination:** researchers work independently. Lead synthesizes findings
into a unified research document.

### Multi-perspective debate

The researcher's Mode 2 (multi-perspective analysis) maps directly to
agent teams. Instead of simulating perspectives in one context, each
perspective becomes a real teammate that can challenge others.

**Example prompt to lead:**
> "Create a team to evaluate whether we should build HNSW in-house or use
> a library. Spawn 4 teammates as perspectives: Performance Advocate,
> Maintenance Advocate, DX Advocate, and Devil's Advocate. Have them
> debate and share findings with each other."

**Coordination:** teammates message each other to challenge arguments.
Lead synthesizes into scoring matrix and rulings.

### Parallel implementation (wave-based)

For implementation plans with independent waves, each wave's tasks can
be assigned to teammates. Only use this for tasks that touch different
files.

**Example prompt to lead:**
> "We have an implementation plan with 3 independent tasks in Wave 1.
> Create a team with 3 teammates. Assign Task 1 to teammate A, Task 2
> to teammate B, Task 3 to teammate C. Each task modifies different files.
> Wait for all to complete before starting Wave 2."

**Coordination rules:**
- Verify no two teammates modify the same file before spawning
- Use task dependencies to enforce wave ordering
- Review each teammate's output before starting the next wave
- Each teammate should run CI verification before committing

## Team sizing

- **3-5 teammates** for most workflows. Coordination overhead increases
  rapidly beyond 5.
- **5-6 tasks per teammate** keeps everyone productive without excessive
  context switching.
- Three focused teammates outperform five scattered ones.

## Available agent types

These plugin agents are available as teammate types:

| Agent | Role | Tools | Memory |
|:--|:--|:--|:--|
| `code-reviewer` | Post-phase code review | Read-only | Persistent |
| `security-auditor` | STRIDE security audit | Read-only | Persistent |
| `researcher` | Technical research | Full access | Persistent |
| `feature-architect` | Feature design and planning | Full access | Persistent |

Reference by name when spawning teammates:
> "Spawn a teammate using the code-reviewer agent type."

## Guidance

**Start with review and research.** These are the safest team patterns -
no file conflicts, clear boundaries, high value from parallel perspectives.
Move to parallel implementation only after the team workflow is familiar.

**Monitor and steer.** Check teammate progress, redirect approaches that
are not working, and synthesize findings as they arrive. Unattended teams
risk wasted effort.

**Avoid file conflicts.** This is the most common team failure mode. Before
spawning implementation teammates, verify that each teammate's tasks touch
different files. If any overlap exists, keep those tasks sequential.

**Teams are expensive.** Each teammate is a separate Claude session with
its own token costs. Use teams when the parallel value justifies the cost,
not as a default execution mode.
