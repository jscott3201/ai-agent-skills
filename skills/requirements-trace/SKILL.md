---
name: requirements-trace
description: >
  Verify that every requirement has corresponding code and tests. Maps
  requirements to implementation, identifies untested or unimplemented
  requirements, and flags code without a traced requirement.
disable-model-invocation: true
argument-hint: "[plan or requirements path]"
---

## Purpose

After implementation, verify that what was built matches what was intended.
Produces a bidirectional trace matrix: requirements to code to tests.
Identifies gaps in both directions — requirements without implementation
and implementation without requirements.

This is an interactive skill. Present each gap one at a time with options
to address, accept, or defer.

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior traceability context:

1. **Create session** with `skill: 'requirements-trace'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior trace work:
   - Prior `:Document {doc_type: 'plan'}` or `{doc_type: 'design'}` linked
     to the feature being traced (from feature-design)
   - Prior requirements-trace sessions that found gaps in this area
   - `:Decision` nodes (including non-goals) from the design phase

3. If prior context exists:

> "Prior traceability context:
> - [Feature-design produced a plan on date with N requirements]
> - [Prior trace found N gaps, N were addressed, N deferred]
> - [Design non-goals that should NOT appear in implementation]
>
> I'll use the design decisions as the requirements source."

Design non-goals are especially valuable — code implementing a non-goal
is scope creep that the trace should catch.
If SeleneDB is not available or no prior context exists, skip silently.

### 1. Locate the requirements source

Check for requirements in this order:

1. If `$ARGUMENTS` points to a file, use it
2. Check `_agentskills/plans/` for the most recent implementation plan
3. Check `_agentskills/design/` for a design document
4. Ask the user to specify the requirements source

Extract the requirement list. Requirements come from:
- **Implementation plans:** task descriptions, exit criteria, non-goals
- **Design documents:** goals, non-goals, decision records
- **Feature-design Stage 1:** problem statement, success criteria, constraints

Number each requirement for reference (R1, R2, R3...).

Present the extracted requirements to the user:

> "Found N requirements from [source]. Here are the top-level items:
>
> - R1: [requirement summary]
> - R2: [requirement summary]
> - ...
>
> Does this capture the full scope? Add, remove, or adjust before I trace."

Wait for confirmation before proceeding.

### 2. Trace requirements to implementation

For each requirement, search the codebase for its implementation:

- Grep for types, functions, modules, and endpoints mentioned in the
  requirement or its associated plan tasks
- Check that the code exists and is reachable (not dead code)
- Note which files and functions implement each requirement

Build the forward trace:

| Requirement | Status | Implementation |
|:--|:--|:--|
| R1: [summary] | Implemented | `src/auth/session.rs:create_session()` |
| R2: [summary] | Partial | `src/api/routes.rs:handle_login()` (missing error path) |
| R3: [summary] | Missing | No implementation found |

### 3. Trace requirements to tests

For each requirement, search for tests that verify it:

- Check test files for functions that exercise the requirement's behavior
- Look for test names that reference the requirement's domain concepts
- Verify the tests actually assert the requirement's success criteria,
  not just that code runs without panicking

Extend the trace:

| Requirement | Implementation | Tests |
|:--|:--|:--|
| R1 | `session.rs:create_session()` | `tests/auth.rs:test_create_session` |
| R2 | `routes.rs:handle_login()` | None found |
| R3 | Missing | N/A |

### 4. Check for untraced code

Scan the files touched by the implementation (from the plan or recent
commits) for code that does not map to any requirement:

- New public functions or types not referenced by any requirement
- Features or behaviors not in the requirements list
- Configuration or infrastructure that was not planned

This catches scope creep and accidental additions.

### 5. Present gaps one at a time

Categorize findings by severity:

| Category | Severity | Meaning |
|:--|:--|:--|
| Requirement without code | High | Something intended was not built |
| Requirement without tests | Medium | Something built is not verified |
| Partial implementation | Medium | Requirement partially addressed |
| Code without requirement | Low | Scope creep or missing requirement |

Present each gap **one at a time**, starting with high severity:

> **[Category]:** R[N] — [requirement summary]
> **Status:** [what's missing]
> **Location:** [file:line if applicable]
>
> Options:
> 1. **Address now** — implement/test the missing piece
> 2. **Accept** �� this gap is intentional (document why)
> 3. **Defer** — add to DEFERRED.md for later
>
> I recommend [option] because [reason].

Wait for the user's decision before presenting the next gap.

#### Graph write: gap triage (SeleneDB)

After each gap triage decision:

For **address now** gaps, write a `:Finding` with the resolution:
```gql
INSERT (f:Finding {
  summary: $requirement_summary,
  severity: $gap_severity,
  category: 'requirements_gap',
  triage: 'fix_now'
})
RETURN id(f) AS finding_id
```

For **defer** gaps, create a `:DeferredItem` bridging to deferred-tracking.

For **accept** gaps, write a `:Decision` documenting why the gap is
intentional.

Link all to session and code locations.

### 6. Produce trace matrix

After all gaps are triaged, save the full trace matrix to
`_agentskills/reviews/YYYY-MM-DD-requirements-trace.md`:

```markdown
# Requirements Trace: [Feature Name]

**Date:** YYYY-MM-DD
**Source:** [plan/design doc path]
**Status:** N/N requirements traced, N gaps identified

## Trace Matrix

| ID | Requirement | Implementation | Tests | Status |
|----|-------------|----------------|-------|--------|
| R1 | [summary] | [file:function] | [test name] | Complete |
| R2 | [summary] | [file:function] | None | Gap: no tests |
| R3 | [summary] | None | N/A | Gap: not implemented |

## Gaps Addressed

- R2: [what was done]
- R5: [accepted as intentional — reason]

## Gaps Deferred

- R3: [gate condition for when to revisit]

## Untraced Code

- [file:function] — [not mapped to any requirement]
```

Summarize: "N requirements fully traced, N gaps addressed, N deferred,
N untraced code items flagged."

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Tests exist, requirements must be covered" | Tests verify behavior, not intent. A passing test suite can miss entire requirements. |
| "Small feature, skip formal tracing" | Small features have small scope — tracing takes minutes, not hours. Gaps compound regardless of feature size. |
| "Code without requirements is fine if it works" | Untraced code is scope creep or a missing requirement. Either way, it needs acknowledgment. |
| "Non-goals don't need verification" | Non-goals that appear in implementation are the most important trace finding — they indicate scope creep. |

## Red Flags

Stop and reassess if you observe:
- Accepting requirements without user confirmation
- Skipping the untraced code check (step 4)
- Presenting all gaps at once instead of by severity
- Not producing a trace matrix at the end

## Verification

- [ ] Requirements source located and confirmed with user
- [ ] Each requirement traced to implementation code
- [ ] Each requirement traced to test coverage
- [ ] Gaps presented to user one at a time
- [ ] Trace matrix produced

## Guidance

**Run this after implementation, before release.** The trace matrix is
most valuable when there is still time to address gaps. Running it after
release is an audit; running it before release is quality assurance.

**Requirements are not just features.** Non-goals, constraints, and
error handling requirements are equally important to trace. "The system
must NOT do X" is a requirement that needs a test proving X does not
happen.

**Partial traces are still valuable.** Even if the requirements source is
informal (a conversation, not a design doc), extracting and numbering
requirements creates accountability that was not there before.

**Pair with deep-review.** This skill checks "did we build what we
intended?" while deep-review checks "is what we built correct?" They
complement each other — run both before considering a feature complete.

**SeleneDB connects requirements to the full design pipeline.** When
feature-design stores non-goals in the graph, requirements-trace can
check that no implementation addresses a non-goal (scope creep detection).
When gaps are deferred, they surface in deferred-tracking. When gaps are
fixed, the `:fixed_by` commit link closes the traceability loop.
