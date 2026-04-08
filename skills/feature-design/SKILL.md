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

### Stage 0: Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior design context:

1. **Create session** with `skill: 'feature-design'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior design work on related code:
   - Prior `:Decision` nodes affecting `:CodeLocation` nodes in the feature's area
   - Prior `:Document {doc_type: 'plan'}` or `{doc_type: 'design'}` on related topics
   - Any `:DeferredItem` nodes that this feature might address
   - Prior `:PlanClaim` inaccuracies from plan-verify on same modules (indicates
     which areas drift most and need extra verification)
   - **Prior research on related topics** — query `:Document` nodes linked to
     matching `:Topic` nodes:

   ```gql
   MATCH (doc:Document)-[:about]->(t:Topic)
   WHERE t.name CONTAINS $keyword OR t.description CONTAINS $keyword
   MATCH (doc)<-[:produced]-(s:Session)
   WHERE s.project = $project AND doc.doc_type IN ['deep_dive', 'multi_perspective', 'landscape']
   RETURN doc.title, t.name AS topic, s.date
   ORDER BY s.date DESC
   LIMIT 5
   ```

   Capture the IDs of research documents that are relevant — they will be
   linked to the plan via `:informs` in Stage 4.

3. If relevant prior context exists, present it:

> "Prior design context for this area:
> - [Prior design decisions affecting these modules]
> - [Any deferred items this feature might address]
> - [Plan verification history: which modules drift most]
>
> This may inform the design. Proceeding with exploration."

If SeleneDB is not available or no prior context exists, skip silently.

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

#### Graph write: non-goals (SeleneDB)

After non-goals are confirmed with the user, write each as a `:Decision`
node with rejection rationale:

```gql
INSERT (d:Decision {
  summary: $non_goal,
  rationale: $why_excluded,
  alternatives: 'Explicitly scoped out',
  confidence: 'high'
})
RETURN id(d) AS decision_id
```

Link to session and the plan document (when created) via `:non_goal`:

```gql
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (d:Decision) WHERE id(d) = $decision_id
INSERT (s)-[:produced]->(d)
```

Non-goals stored in the graph surface in future feature-design sessions
when similar scope is explored, preventing scope re-expansion.

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
6. For key decisions where the rationale isn't obvious from the choice
   itself, offer: "Want to capture why this approach? (optional)"
   If yes, create a `:Note {kind: 'rationale', author: 'user'}` linked
   to the `:Decision` via `:annotates`. This preserves context that
   "alternatives" and "rationale" fields may not fully capture.
7. Summarize the confirmed design and get final approval before Stage 4

#### Graph write: design decisions (SeleneDB)

After each design decision is confirmed by the user:

```gql
INSERT (d:Decision {
  summary: $decision_summary,
  rationale: $why_chosen,
  alternatives: $rejected_approaches,
  confidence: $confidence
})
RETURN id(d) AS decision_id
```

Link to session and affected code:

```gql
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (d:Decision) WHERE id(d) = $decision_id
INSERT (s)-[:produced]->(d)

MERGE (loc:CodeLocation {file: $file, module: $module})
INSERT (d)-[:affects]->(loc)
```

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

#### Graph write: formal design document (SeleneDB)

If the formal path was chosen, write the design document to the graph:

```gql
INSERT (doc:Document {
  title: $feature_name,
  doc_type: 'design',
  content: $document_content,
  mode: 'formal'
})
RETURN id(doc) AS doc_id
```

Link design decisions from Stage 3 to this document via `:contains`.

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

#### Graph write: implementation plan (SeleneDB)

Write the plan as a `:Document` node and link design decisions to it:

```gql
INSERT (doc:Document {
  title: $feature_name,
  doc_type: 'plan',
  content: $plan_content
})
RETURN id(doc) AS plan_id

// Link all design decisions from Stage 3 as contained
MATCH (d:Decision)<-[:produced]-(s:Session)
WHERE id(s) = $session_id
INSERT (doc)-[:contains]->(d)

// Link to session
MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(doc)
```

This creates the upstream node that plan-verify will later validate.
The `:contains` edges connect the plan to the decisions that shaped it.

**Link research provenance.** If prior research documents (from Stage 0
auto-recall or from a research session earlier in this conversation)
informed this plan, create `:informs` edges:

```gql
MATCH (research:Document) WHERE id(research) = $research_doc_id
MATCH (plan:Document) WHERE id(plan) = $plan_id
INSERT (research)-[:informs]->(plan)
```

This makes the provenance chain queryable: given a plan, you can find
what research informed it. Given a research document, you can find what
plans it fed into.

**Create a milestone.** For medium and large features (2+ phases), create
a `:Milestone` node to track the initiative across sessions:

```gql
INSERT (m:Milestone {
  name: $feature_name,
  description: $feature_description,
  status: 'planned',
  target_date: $target_date
})
RETURN id(m) AS milestone_id

// Link plan to milestone
MATCH (doc:Document) WHERE id(doc) = $plan_id
MATCH (m:Milestone) WHERE id(m) = $milestone_id
INSERT (doc)-[:part_of]->(m)

// Tag with topics
MERGE (t:Topic {name: $topic_name})
MATCH (m:Milestone) WHERE id(m) = $milestone_id
MATCH (t:Topic {name: $topic_name})
INSERT (m)-[:about]->(t)
```

The milestone-tracking skill will handle commit linking and lifecycle
from here. When execution begins, transition the milestone to
`in_progress`.

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
- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Combine exploration and design to move faster" | Exploration informs design. Skipping it means designing against assumptions, not facts. |
| "Simple feature, skip formal design" | Complexity hides in integration. The design phase catches what "simple" missed. |
| "User knows what they want, skip to planning" | Users know the goal, not the constraints. Exploration reveals what the codebase actually supports. |
| "Pseudocode first, fill in exact code later" | Pseudocode hides the hard parts. Complete code forces confrontation with reality. |
| "First review passes, skip iteration" | First reviews catch obvious issues. Second reviews catch subtle ones. |

## Red Flags

Stop and reassess if you observe:
- Jumping to implementation planning without exploring the codebase
- Pseudocode or "TODO" placeholders in the implementation plan
- Skipping the plan verification stage
- No non-goals defined (scope will creep)
- Presenting all design decisions at once instead of one at a time

## Verification

- [ ] Codebase explored before asking clarifying questions
- [ ] Approach selected with user from presented options
- [ ] Implementation plan written with complete code (no pseudocode)
- [ ] Plan self-reviewed for placeholders and internal consistency
- [ ] Plan verified via plan-verify and approved by user

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

**SeleneDB connects the full design pipeline.** Design decisions stored here
flow into plan-verify (which validates them against code), deep-review (which
checks the implementation), and deferred-tracking (which captures what was
scoped out). Non-goals are especially valuable — they surface when future
features attempt to expand into explicitly excluded territory.
