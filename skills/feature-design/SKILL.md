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

Drive a feature from idea to implementation-ready plan through guided
conversation. This is an interactive skill: the user drives decisions while
you provide analysis, options, and recommendations. Every stage involves
the user directly.

Covers the full arc: explore the codebase, understand the problem, capture
workflow preferences, research and design (at a depth the user chooses),
produce a phased implementation plan with complete code, verify against the
codebase, iterate with the user, and hand off to execution.

## Instructions

Work through these stages in order. Each stage builds on the previous one.
Do not skip stages, but scale the depth of each stage to the feature's
complexity. Present one topic at a time and wait for the user before
proceeding.

### Stage 1: Explore and understand

#### 1a. Codebase exploration

Before asking any questions, build context. Follow the
[exploration-checklist.md](exploration-checklist.md) to systematically
understand the project state. Key areas:

- Read CLAUDE.md and any decision logs or architectural docs
- Identify existing patterns relevant to the feature (how similar things are done)
- Check recent git history for ongoing work that might interact
- Find the code areas that will be affected
- Note test patterns, CI requirements, and project conventions

Use an Explore subagent for large codebases to keep the main context clean.

#### 1b. Understand the feature

1. If `$ARGUMENTS` was provided, use it as the starting point
2. Ask clarifying questions **one at a time**. For each question:
   - Present 2-4 options when meaningful choices exist
   - State your recommendation and explain why you favor that path
   - Let the user pick, adjust, or override before moving to the next question
   - If the answer is obvious from the codebase exploration, state your
     assumption and ask the user to confirm rather than posing it as open-ended
3. Cover these areas through your questions:
   - **Problem:** What problem does this solve? Who experiences it?
   - **Success criteria:** What does "done" look like? How will we know it works?
   - **Constraints:** Performance targets, compatibility requirements, scope limits
   - **Non-goals:** What are we explicitly NOT building? What adjacent problems
     are out of scope? (This prevents scope creep and over-engineering)
4. Assess scope: if the feature spans multiple independent subsystems, flag it
   immediately and help decompose into sub-features. Each sub-feature gets
   its own pass through this skill.

### Stage 2: Capture workflow preferences

Ask these questions before any planning work. The answers shape the plan
format and task granularity.

**Approach:**
- **Greenfield** - building something new with freedom to choose patterns,
  structure, and conventions from scratch. Major new features, new modules,
  new services.
- **Brownfield** - working within existing code. Surgical changes that
  respect established patterns, minimize disruption, and integrate with
  what exists. Bug fixes, incremental features, refactors.

This choice shapes the entire plan: greenfield designs the architecture;
brownfield follows the existing architecture and focuses on integration points.

**Execution style:**
- **Primary agent** - all code written by main Claude in this session
- **Subagent-driven** - sequential subagent dispatch, review between tasks
- **Mixed** - research/review via subagent, implementation by primary agent
- **Team-based** - parallel teammates per wave, each owning different files
  (requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`; check availability
  before offering this option)

If agent teams are available and the feature has multiple independent waves
with tasks touching different files, recommend team-based execution. The
plan's wave structure maps directly to team coordination: tasks within a
wave run in parallel, wave boundaries are synchronization points.

**Commit strategy:**
- Work on a branch, or directly on main?
- Commit at each task, each sub-phase, or each phase?

**Output location:**
- Default: `_agentskills/` (gitignored, not committed)
  - Design documents: `_agentskills/design/`
  - Implementation plans: `_agentskills/plans/`
- Or specify an alternative path

**Complexity check:**
After gathering requirements, provide a brief complexity estimate:
- **Small** (1 phase, 3-5 tasks, hours of work) - skip formal research
- **Medium** (2-3 phases, 10-20 tasks, days of work) - conversational or formal
- **Large** (4+ phases with sub-phases, weeks of work) - formal research recommended

Get the user's agreement on scope before proceeding.

### Stage 3: Research and design

Present the user with a choice:

> "Two depth options for the design phase:
> 1. **Conversational** - we discuss the design here, confirm the approach, move to planning
> 2. **Formal** - I produce a research/design document with decision records before planning
>
> Which depth?"

#### If conversational:

1. Propose 2-3 approaches with concrete tradeoffs:
   - Lead with your recommendation and explain why you favor it
   - For each alternative, state what it does better AND what it does worse
   - Include a "do nothing / minimal" option when relevant
2. Let the user pick an approach before continuing
3. For the chosen approach, walk through design decisions one at a time:
   - Present each decision as a question with options
   - State your recommendation and reasoning for each
   - Wait for the user's input before moving to the next decision
4. Explicitly state non-goals and what was rejected
5. Identify risks: what could go wrong with the chosen approach?
6. Summarize the confirmed design and get final approval before Stage 4

#### If formal:

Produce a structured document using the
[research-template.md](research-template.md) format. Key sections:

- Goals and non-goals
- System context (how this fits the existing architecture)
- Design decisions with alternatives rejected and rationale
- Technical analysis (data structures, APIs, performance estimates)
- Risks and mitigations
- What was explicitly not recommended and why

Save to `_agentskills/design/`. Get user approval before proceeding.

### Stage 4: Write implementation plan

Read [plan-template.md](plan-template.md) for the complete plan structure and
requirements. Follow that template exactly.

Key constraints:
- Every task has complete code - no pseudocode, no placeholders
- Every file path is exact - absolute within the project
- Dependencies are explicit - blocks/blocked-by on every task
- Each phase has exit criteria and a test strategy
- Task granularity matches the execution style chosen in Stage 2
- Risks and rollback strategy are documented

**Task sizing rule:** Keep each task to a single logical unit (one function,
one component, one API endpoint). Multi-file tasks that touch 4+ files with
100+ lines of changes have significantly lower accuracy. When a change is
inherently cross-cutting, structure it as a sequence of focused tasks rather
than one large task.

Save the plan to `_agentskills/plans/`.

#### Plan self-review

After writing the plan, review it with fresh eyes before involving the user:

1. **Placeholder scan:** Search for "TBD", "TODO", "implement later",
   "similar to Task N", or any vague instructions. Fix them.
2. **Internal consistency:** Do types, function names, and property names
   used in later tasks match what was defined in earlier tasks?
3. **Dependency check:** Does each task's "blocked-by" list actually
   produce what the task needs? Are there circular dependencies?
4. **Scope check:** Does every task trace back to a requirement from
   Stage 1? Are there tasks that implement things nobody asked for?

Fix any issues inline. No need to re-review - fix and move on.

### Stage 5: Verify, review, and hand off

#### 5a. Plan verification

Invoke the `plan-verify` skill to check the plan against the codebase.
Present findings to the user and fix any inaccuracies.

#### 5b. User review cycle

Present the plan to the user for review:

> "Plan written and verified. Please review and let me know:
> - Any sections that need changes
> - Anything missing or out of scope
> - Any concerns about the approach
>
> I'll incorporate your feedback and re-present."

Iterate until the user approves. Each iteration:
1. Incorporate the user's feedback
2. Re-run the self-review checks
3. Re-present the updated plan

This review cycle is the highest-leverage step. A plan reviewed 2-3 times
produces significantly better implementation results than a plan executed
immediately.

#### 5c. Execution handoff

After the user approves:

1. Ask: "Ready to start execution?"
2. If yes, begin implementing per the chosen execution style from Stage 2

## Supporting files

- [exploration-checklist.md](exploration-checklist.md) - structured codebase exploration for Stage 1
- [research-template.md](research-template.md) - formal research/design document format for Stage 3
- [plan-template.md](plan-template.md) - implementation plan structure for Stage 4

## Guidance

**Context first, questions second.** Read the codebase before asking the user
anything. Half the clarifying questions answer themselves when you understand
the existing code, patterns, and conventions.

**Non-goals are as important as goals.** Explicitly stating what the feature
does NOT do prevents scope creep during implementation and sets clear
boundaries for the plan.

**The review cycle is not optional ceremony.** Research shows that plans
reviewed 2-3 times before implementation produce significantly better results
than plans executed immediately. The cost of an extra review round is minutes;
the cost of implementing a flawed plan is hours.

**Scale to complexity.** A focused feature (small) might skip formal research
and have one phase with 3 tasks. A major initiative (large) might need formal
research with decision records and 5 phases with sub-phases. Let the scope
dictate the structure.

**YAGNI ruthlessly.** When presenting approaches in Stage 3, remove features
that solve hypothetical future problems. The right amount of complexity is
what the feature actually requires.
