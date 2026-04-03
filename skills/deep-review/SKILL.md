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

## Instructions

### Phase 1: Research

Spawn an Explore subagent using the Agent tool for the research phase. This
keeps heavy codebase scanning out of the main conversation context.

If `$ARGUMENTS` was provided, use it to focus the review scope. Otherwise,
identify scope from recent commits or ask the user.

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

When the Explore subagent returns, structure the report:

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

### Phase 3: Fix

Work through fixes in the main context:

1. Start with S1 Critical, then S2 High, S3 Medium, S4 Low
2. Run verification after each fix to confirm it resolves the issue
   and does not introduce new problems
3. After all fixes applied, do a final scan to confirm no remaining issues

## Supporting files

- [review-patterns.md](review-patterns.md) - detailed patterns and examples for each review category

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

**Navigate before scanning.** Understanding intent and reviewing main files
first catches design-level issues before you spend tokens on detail checks.
If the architecture is wrong, flag it immediately.

This review is language-agnostic. Substitute equivalent concepts for
your language (match arms for Rust, switch exhaustiveness for TypeScript,
pattern matching for Python, etc).
