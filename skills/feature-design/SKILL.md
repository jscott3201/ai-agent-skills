---
name: feature-design
description: >
  Guide feature development from idea through research, design, and
  implementation planning. Produces phased plans with dependency graphs
  and complete code. Use when starting a new feature or major initiative.
disable-model-invocation: true
argument-hint: "[feature description]"
---

## Purpose

Drive a feature from idea to implementation-ready plan. Covers the full arc:
understand the problem, capture workflow preferences, research and design
(at a depth the user chooses), produce a phased implementation plan with
complete code, verify the plan against the codebase, and hand off to execution.

## Instructions

Work through these stages in order. Each stage builds on the previous one.

### Stage 1: Understand the feature

1. Explore the current project context - files, docs, recent commits, CLAUDE.md
2. If `$ARGUMENTS` was provided, use it as the starting point
3. Ask clarifying questions one at a time to understand:
   - What problem this solves
   - What constraints exist (performance, compatibility, scope)
   - What success looks like
4. Assess scope: if the feature spans multiple independent subsystems, flag it
   immediately and help decompose into sub-features before continuing. Each
   sub-feature gets its own pass through this skill.

### Stage 2: Capture workflow preferences

Ask these questions before any planning work. The answers shape the plan format.

**Execution style:**
- **Primary agent** - all code written by main Claude in this session
- **Subagent-driven** - sequential subagent dispatch, review between tasks
- **Mixed** - research/review via subagent, implementation by primary agent

**Commit strategy:**
- Work on a branch, or directly on main?
- Commit at each task, each sub-phase, or each phase?

**Plan location:**
- Default: `_plans/` (gitignored, not committed)
- Or specify an alternative path

### Stage 3: Research and design

Present the user with a choice:

> "This feature needs some design work. Two options:
> 1. **Conversational** - we discuss the design here, I confirm the approach, and move to planning
> 2. **Formal** - I produce a research/findings document and decision log entries before planning
>
> Which depth?"

#### If conversational:

- Propose 2-3 approaches with tradeoffs
- Lead with your recommendation and explain why
- Discuss until the user confirms an approach
- Move to Stage 4

#### If formal:

Produce a structured findings document:

```markdown
# [Feature] Research Findings

**Date:** YYYY-MM-DD
**Method:** [How the analysis was conducted]

## Design Decisions

| ID | Decision | Alternatives Rejected | Rationale | Impact |
|----|----------|-----------------------|-----------|--------|
| D-XX | [What was decided] | [What was not chosen] | [Why] | [What changes] |

## Technical Analysis

[Sections as needed - architecture, data structures, performance estimates,
integration points, security considerations]

## Not Recommended

[What was explicitly considered and rejected, with rationale]
```

Save to the configured plan location. Get user approval before proceeding.

### Stage 4: Write implementation plan

Produce a plan in this structure:

```markdown
# [Feature] Implementation Plan

**Goal:** [One sentence - what this builds]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies/dependencies]

---

## Dependency Graph

[ASCII graph showing task dependencies and execution waves]

---

## Phase N: [Phase Name]

### Sub-phase NA: [Name]

**Depends on:** [What must be complete first]
**Produces:** [What this delivers]

#### Task N: [Task Name]

**Blocks:** [Tasks that depend on this]
**Blocked by:** [Tasks that must finish first]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing/file`

- [ ] **Step 1: [Action]**

[Complete code block - actual implementation, not pseudocode]

- [ ] **Step 2: [Action]**

[More complete code]

- [ ] **Step 3: Verify**

[Exact commands with expected output]

- [ ] **Step 4: Commit**

[Exact commit message in conventional format]
```

#### Plan requirements

- **Every task has complete code** - no pseudocode, no placeholders, no "implement similar to Task N"
- **Every file path is exact** - absolute within the project, not relative
- **Dependencies are explicit** - blocks/blocked-by on every task
- **Waves indicate parallelization** - tasks in the same wave have no shared state
- **Commit messages use conventional format** - `feat(scope): description`
- **Task granularity matches execution style:**
  - Primary agent: tasks can be larger, grouped by logical unit
  - Subagent-driven: tasks must be fully self-contained with all context
    a fresh agent needs to execute them independently

Save the plan to the configured location (default `_plans/`).

### Stage 5: Verify and hand off

After the plan is written:

1. Run the `plan-verify` process against the codebase:
   - Verify all referenced files, functions, and APIs exist
   - Check that signatures and data flow match reality
   - Confirm dependency ordering is correct
2. Present findings to the user
3. Fix any inaccuracies in the plan
4. Ask: "Plan verified and ready. Start execution?"
5. If yes, begin implementing per the chosen execution style from Stage 2

## Guidance

The most important stage is 4. A good plan prevents wasted implementation
time. Invest the effort here - verify every API you reference, trace every
data flow, and write complete code. A plan with complete, verified code blocks
is essentially a guided implementation that executes reliably whether run by
the primary agent or delegated to subagents.

Scale the number of phases to the feature's complexity. A focused feature
might be one phase with 3-5 tasks. A major initiative might be 5 phases
with sub-phases. Let the scope dictate the structure, not a template.

When presenting approaches in Stage 3, YAGNI ruthlessly. Remove features
that solve hypothetical future problems. The right amount of complexity is
what the feature actually requires.
