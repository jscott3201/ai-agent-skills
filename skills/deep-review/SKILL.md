---
name: deep-review
description: >
  Deep code review after completing a feature or implementation phase.
  Cross-references all changes against the codebase and fixes all findings.
  Use after finishing a phase, feature, or significant implementation chunk.
context: fork
agent: Explore
---

## Purpose

Catch issues that tests alone miss. After completing a feature or phase,
cross-reference every change against the actual codebase to find incomplete
implementations, stale references, missed consumers, and inconsistencies.

## Instructions

### Phase 1: Research (runs in Explore subagent)

Identify the scope of changes to review. Use recent commits, diff, or
user-specified scope.

For every changed or added component, verify:

1. **Routing/dispatch completeness**
   - Every new code path is reachable from its entry point
   - No dead code or unreachable branches introduced
   - All match arms and conditional branches are exhaustive

2. **Mutation path coverage**
   - Every function that creates or modifies data handles all relevant cases
   - No partial implementations (3 of 5 variants handled, 2 silently ignored)

3. **API consumer updates**
   - Every caller of a changed function signature has been updated
   - Return type changes are propagated through the full call chain
   - No callers still using an old API shape

4. **Stale references**
   - No references to removed or renamed functions, types, or modules
   - No imports of deleted items
   - No documentation pointing to code that no longer exists

5. **Error handling consistency**
   - New error variants are handled at every catch site
   - Error propagation follows existing project patterns
   - No swallowed errors or silent failures

6. **Feature gate consistency** (if applicable)
   - Feature-gated code compiles and tests under all relevant flag combinations
   - No accidental dependencies between feature-gated modules

### Phase 2: Report

Categorize all findings by severity:

- **Critical** - incorrect behavior, data loss, security issue
- **High** - logic error, missing error handling, broken consumer
- **Medium** - inconsistency, incomplete implementation, stale reference
- **Low** - style issue, suboptimal pattern, minor cleanup

Report every finding. Do not skip any severity level.

### Phase 3: Fix (runs in main context)

After findings are reported to the main context:

1. Work through fixes one at a time, starting with Critical
2. Run verification after each fix to confirm it resolves the issue
   and does not introduce new problems
3. After all fixes applied, do a final scan to confirm no remaining issues

## Guidance

The most valuable checks are API consumer updates and mutation path coverage.
These are where real bugs hide - a changed return type that one caller still
destructures the old way, or a new enum variant that five match statements
handle but the sixth uses a wildcard arm.

This review is language-agnostic. The specific checks (match arms, feature
gates) apply where relevant. For non-Rust codebases, substitute equivalent
concepts (switch exhaustiveness, conditional compilation, etc).
