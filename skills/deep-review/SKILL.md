---
name: deep-review
description: >
  Deep code review after completing a feature or implementation phase.
  Cross-references all changes against the codebase and fixes all findings.
  Use after finishing a phase, feature, or significant implementation chunk.
argument-hint: "[scope description]"
---

## Purpose

Catch issues that tests alone miss. After completing a feature or phase,
cross-reference every change against the actual codebase to find incomplete
implementations, stale references, missed consumers, concurrency hazards,
performance anti-patterns, and inconsistencies.

This is a post-implementation review, not a PR review. It examines the entire
body of work: cross-module consistency, integration completeness, and
system-level impact.

**When NOT to use:** The user is still actively building (review after the
feature is complete). A quick style check is needed (use `code-standards`).
The user wants a PR-style review of someone else's code (this reviews your
own completed work).

## Instructions

### Phase 0: Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior review context:

1. **Create session** with `skill: 'deep-review'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior reviews touching this scope:
   - Prior `:Finding` nodes linked to `:CodeLocation` nodes in the review scope
   - Severity and category distribution from past reviews
   - Any recurring patterns (same category appearing across reviews)

3. **Query active conventions** for the project scope:

```gql
MATCH (c:Convention {active: true})
MATCH (c)<-[:produced]-(s:Session)
WHERE s.project = $project
RETURN c.rule, c.scope, c.severity
ORDER BY c.severity
```

4. If relevant prior findings or conventions exist, present a brief summary:

> "Prior review context for this scope:
> - [N] findings from [N] previous reviews in this area
> - Most common categories: [top 2-3 categories]
> - [Any unresolved S1/S2 findings still open]
> - [N] active project conventions to check against
>
> I'll pay extra attention to [recurring category] and project conventions."

Active conventions supplement the 13 built-in review categories. Check
them alongside the standard categories — a convention violation is at
the severity recorded in the convention node.

This focuses the review on historically problematic areas.
If SeleneDB is not available or no prior context exists, skip silently.

### Phase 1: Research

If `$ARGUMENTS` was provided, use it to focus the review scope. Otherwise,
identify scope from recent commits or ask the user.

**For large scope** (10+ files, full feature, or multi-module changes):
delegate to the `deep-reviewer` agent using the Agent tool. This keeps
heavy scanning out of the main context. Include the scope and review
navigation order below in the delegation prompt.

**For focused scope** (a few files, single module, or targeted review):
perform the analysis directly in the main conversation. Delegation adds
overhead without context benefit for small scopes.

#### Review navigation order

Follow this order for effective coverage (from Google's engineering practices):

1. **Understand intent** - read commit messages or scope description to
   understand what was built and why
2. **Review main files first** - find the files with the largest logical
   changes and review for design issues. If the design is fundamentally
   wrong, flag immediately before reviewing details.
3. **Trace data flow** - follow data from entry points through processing
   to output across the entire feature, not just within individual files
4. **Review remaining files** following the dependency graph
5. **Read tests** - verify they test the right things and would actually
   fail if the code broke

#### Review categories

For every changed or added component, check each category. See
[review-patterns.md](review-patterns.md) for detailed patterns and examples.

**Structural completeness:**

1. **Routing/dispatch completeness**
   - Every new code path is reachable from its entry point
   - No dead code or unreachable branches introduced
   - All match arms and conditional branches are exhaustive

2. **Mutation path coverage**
   - Every function that creates or modifies data handles all relevant cases
   - No partial implementations (3 of 5 variants handled, 2 silently ignored)

3. **API consumer updates**
   - Every caller of a changed function signature has been updated
   - Return type changes propagated through the full call chain
   - No callers still using an old API shape

4. **Stale references**
   - No references to removed or renamed functions, types, or modules
   - No imports of deleted items
   - No documentation pointing to code that no longer exists

**Correctness:**

5. **Error handling**
   - New error variants handled at every catch site
   - No swallowed errors (bare `except: pass`, empty catch blocks)
   - Missing rollback on partial failure in multi-step operations
   - Error propagation follows existing project patterns

6. **Boundary conditions**
   - Off-by-one errors at 0, 1, max, max+1
   - Empty collection handling (what happens with zero items?)
   - Inclusive vs exclusive range confusion
   - Integer overflow on arithmetic with external values

7. **State management**
   - Cache invalidation when underlying data mutates
   - No stale state read after a mutation in the same flow
   - Consistent state across related data structures after updates

**Concurrency and performance:**

8. **Concurrency hazards**
   - Lock ordering consistent across all code paths (prevents deadlocks)
   - No lock held across `.await` points
   - TOCTOU: no gap between check and use of a shared resource
   - Shared mutable state properly synchronized

9. **Performance patterns**
   - N+1 queries (loop making one query per iteration)
   - Allocation in hot paths (object/string creation in tight loops)
   - Synchronous I/O in async context
   - Unbounded iteration or result sets from external input
   - Unnecessary cloning of large data structures

10. **Resource lifecycle**
    - Every opened resource (file, connection, handle) is closed
    - Connection pools returned after use, not leaked on error paths
    - No resource acquisition without corresponding release in all code
      paths (including error paths)

**Integration:**

11. **Cross-module consistency**
    - All parts of the feature use consistent patterns, naming, error handling
    - No orphaned code that is not wired into the system
    - New modules do not create circular dependencies

12. **Feature gate consistency** (if applicable)
    - Feature-gated code compiles and tests under all relevant flag combinations
    - No accidental dependencies between feature-gated modules

13. **Documentation alignment**
    - Documentation reflects the actual implementation, not the original plan
    - New public APIs have doc comments
    - Changed behavior is reflected in user-facing docs

### Phase 2: Report

When the analysis is complete (whether delegated or direct), structure
the report:

#### Finding format

Each finding must include:
- **Location** - exact file, line, function
- **Category** - which review category (1-13 above)
- **Severity** - from the table below
- **What** - the specific issue (not "this looks wrong")
- **Why it matters** - impact if left unfixed
- **Suggested fix** - concrete code change or clear direction

| Severity | Label | Definition |
|----------|-------|------------|
| S1 | **Critical** | Incorrect behavior, data loss, security vulnerability, race condition |
| S2 | **High** | Logic error, missing error handling, broken consumer, resource leak |
| S3 | **Medium** | Inconsistency, incomplete implementation, stale reference, missing test |
| S4 | **Low** | Suboptimal pattern, unnecessary allocation, minor cleanup |

Report every finding. Do not skip any severity level.

#### What NOT to report

Avoid noise. Do not report:
- Style issues that linters and formatters catch
- Theoretical performance concerns without evidence of hot-path usage
- Architectural redesign suggestions (flag for human judgment, don't assert)
- Business logic correctness where you lack domain context (flag uncertainty)

### Phase 3: Triage with user

Present findings to the user **one at a time**, starting with S1 Critical:

1. For each finding, present:
   - The finding summary (location, category, what, why it matters)
   - Your recommended fix
   - Options: **fix now**, **skip** (with noted risk), or **defer** (add to
     deferred tracking)
2. Wait for the user's decision before presenting the next finding
3. If the user's decision involves a judgment call (e.g., skipping an S2,
   deferring despite risk), offer: "Want to add a note on why? (optional)"
   If yes, create a `:Note {kind: 'rationale', author: 'user'}` linked
   to the `:Finding` via `:annotates`. If no, move on immediately.
4. After all S1 findings are triaged, ask: "Move to S2 High findings, or
   stop here?" Repeat at each severity boundary.

This prevents fixing low-value items when the user wants to focus on critical
issues only.

#### Graph write: triage decision (SeleneDB)

After each user triage decision, write the finding to the graph:

```gql
INSERT (f:Finding {
  summary: $what,
  severity: $severity,
  category: $category,
  why_it_matters: $impact,
  suggested_fix: $fix,
  triage: $user_decision
})
RETURN id(f) AS finding_id
```

Link to session, code location, and parent document (if delegated
review produced a report):

```gql
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (f:Finding) WHERE id(f) = $finding_id
INSERT (s)-[:produced]->(f)

MERGE (loc:CodeLocation {file: $file, function: $function})
INSERT (f)-[:affects]->(loc)
```

If the user chooses **defer**, also create a `:DeferredItem` linked
to the finding via `:resolved_by` (pending). This bridges to
deferred-tracking without requiring manual re-entry.

### Phase 4: Fix

Work through approved fixes in the main context:

1. Fix in the order the user approved (S1 first, then S2, etc.)
2. Run verification after each fix to confirm it resolves the issue
   and does not introduce new problems
3. After all approved fixes are applied, do a final scan to confirm no
   remaining issues from the approved set

### Phase 5: Convention graduation (SeleneDB)

After all fixes are applied, check for recurring patterns that should
become project conventions. This only runs when SeleneDB is available
and has findings from prior sessions.

#### 1. Detect recurring patterns

Query for findings that recur across 3+ sessions with the same category
and similar content:

```gql
MATCH (f:Finding)<-[:produced]-(s:Session)
WHERE s.project = $project AND f.triage = 'fix_now'
WITH f.category AS cat, count(DISTINCT s) AS sessions,
  collect({summary: f.summary, id: id(f)}) AS findings
WHERE sessions >= 3
RETURN cat, sessions, findings
ORDER BY sessions DESC
```

Also check that the pattern is not already covered by an existing
convention:

```gql
MATCH (c:Convention {active: true})
MATCH (c)<-[:produced]-(s:Session)
WHERE s.project = $project
RETURN c.rule, c.scope
```

#### 2. Suggest graduation

For each recurring pattern not already covered by a convention, present
to the user:

> "**Recurring pattern detected:** [category] findings have appeared in
> [N] separate reviews:
> - [Finding 1 summary] ([date])
> - [Finding 2 summary] ([date])
> - [Finding 3 summary] ([date])
>
> This looks like a project convention. Proposed rule:
> **[drafted convention rule]**
> Scope: [scope] | Severity: [severity]
>
> Options:
> 1. **Promote** — create this as a project convention
> 2. **Adjust** — change the rule wording, scope, or severity
> 3. **Skip** — not a convention, just coincidence"

Wait for the user's decision before presenting the next candidate.

#### Graph write: convention promotion (SeleneDB)

When the user approves promotion:

```gql
INSERT (c:Convention {
  rule: $rule,
  scope: $scope,
  severity: $severity,
  rationale: $rationale,
  source: 'Promoted from ' + $session_count + ' deep-review findings',
  active: true
})
RETURN id(c) AS convention_id

MATCH (s:Session) WHERE id(s) = $session_id
MATCH (c:Convention) WHERE id(c) = $convention_id
INSERT (s)-[:produced]->(c)
```

Link to the findings that triggered the promotion:

```gql
MATCH (f:Finding) WHERE id(f) IN $finding_ids
MATCH (c:Convention) WHERE id(c) = $convention_id
INSERT (c)-[:promoted_from]->(f)
```

Future reviews will see this convention in Phase 0 auto-recall and check
new code against it.

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Good test coverage means structural issues are unlikely" | Tests verify behavior, not architecture. Cross-module consistency, concurrency, and resource lifecycle hide behind passing tests. |
| "API changes are caught by tests, skip consumer tracing" | Tests cover known consumers. Forgotten or external callers break silently. |
| "Small change, boundary/concurrency checks not relevant" | Small changes cause big outages. Size ≠ risk. |
| "I'll batch findings for efficiency" | Batching overwhelms. One finding at a time lets the user make informed decisions. |
| "Documentation is outdated anyway, skip alignment check" | That's exactly why it needs checking. Stale docs mislead the next person. |

## Red Flags

Stop and reassess if you observe:
- Reviewing only the largest files and skipping small ones
- No findings from concurrency or resource lifecycle categories
- Presenting all findings at once instead of one at a time
- Fixing issues without verifying each fix individually

## Verification

- [ ] All 13 review categories checked against every changed component
- [ ] Every finding has location, category, severity, and suggested fix
- [ ] Findings triaged one at a time with user starting at S1
- [ ] All approved fixes applied and verified individually
- [ ] Final scan confirms no remaining issues from approved set

## Supporting files

- [review-patterns.md](review-patterns.md) - detailed patterns and examples for each review category
- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Guidance

**The highest-value checks** are API consumer updates, error handling gaps,
and concurrency hazards. These produce real bugs that tests often miss:
a changed return type that one caller still destructures the old way,
a swallowed error that silently corrupts data, a lock held across an
await that deadlocks under load.

**Post-implementation context matters.** Unlike a PR review, you are reviewing
a complete feature. Check that all pieces are actually wired together, that
cross-module patterns are consistent, and that documentation reflects what
was built (not what was planned).

**Chesterton's Fence applies to reviews.** Before flagging code for
removal or simplification, verify you understand why it exists. What
looks like dead code may be handling a rare edge case, a rollback path,
or a dependency workaround. Check git blame if the purpose is unclear.

**Navigate before scanning.** Understanding intent and reviewing main files
first catches design-level issues before you spend tokens on detail checks.
If the architecture is wrong, flag it immediately.

**SeleneDB enables review pattern detection.** Over multiple reviews, the
graph reveals which categories and severities recur in specific modules.
This turns reviews from isolated events into a continuous quality signal.

This review is language-agnostic. Substitute equivalent concepts for
your language (match arms for Rust, switch exhaustiveness for TypeScript,
pattern matching for Python, etc).
