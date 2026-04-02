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

Read [plan-template.md](plan-template.md) for the complete plan structure and
requirements. Follow that template exactly.

Key constraints:
- Every task has complete code - no pseudocode, no placeholders
- Every file path is exact - absolute within the project
- Dependencies are explicit - blocks/blocked-by on every task
- Task granularity matches the execution style chosen in Stage 2

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
