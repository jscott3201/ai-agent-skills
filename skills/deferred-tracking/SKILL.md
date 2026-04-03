---
name: deferred-tracking
description: >
  Track deferred work items in a structured DEFERRED.md. Auto-triggers when
  work is deferred during planning or implementation. Invoke manually to
  review and triage the deferred list.
argument-hint: "[review]"
---

## Purpose

Prevent deferred work from being forgotten. When a decision is made to defer
something ("out of scope", "do that later", "Phase N"), capture it in a
structured format so it can be revisited. When invoked manually, review the
list and identify items ready to tackle.

## Instructions

### Adding deferred items (auto-triggered)

When work is explicitly deferred during planning or implementation, capture
it immediately.

1. Look for `DEFERRED.md` in the project root. If it does not exist, create
   it with this structure:

```markdown
# Deferred Work

**Last updated:** YYYY-MM-DD

---

## [Category Name]

| # | Item | Gate | Description | Source |
|---|------|------|-------------|--------|

---

## Summary

| Category | Count |
|----------|-------|
| **Total** | **0** |
```

2. Add the item to the appropriate category table (create the category if new):

   - **Item:** short name for the deferred work
   - **Gate:** what must be true before this is worth doing (effort level,
     dependency resolved, user demand, benchmark threshold)
   - **Description:** 1-2 sentences on what the work involves
   - **Source:** where this came from (plan name, phase, conversation)

3. Update the **Last updated** date and the **Summary** counts.

4. Do not commit DEFERRED.md if it is in `.gitignore` (check first).

### Reviewing deferred items (manual invocation)

When invoked manually (e.g., `/justin-tools:deferred-tracking review`):

1. Read the current `DEFERRED.md`
2. For each item, evaluate whether the gate has been met:
   - Dependencies resolved? Check if the blocking work is complete.
   - Effort feasible now? Consider current project state and priorities.
   - Demand materialized? Check if users/requirements now call for it.
3. Report in three groups:
   - **Ready** - gate is met, item can be tackled now
   - **Still deferred** - gate not yet met, explain what remains
   - **Stale** - item is no longer relevant (superseded, scope changed)
4. Suggest removing stale items and highlight ready items for prioritization.

## Guidance

The gate field is what makes deferred tracking useful. "Later" is not a gate.
Good gates are specific and verifiable:
- "After Phase 3 (alarms) is complete"
- "When query latency exceeds 10ms at 100K nodes"
- "If a second protocol driver is needed"
- "High effort - requires vectorized execution engine first"

Categories should match the project's natural grouping (phases, subsystems,
or concern areas like "Query Engine", "ML/AI", "Infrastructure").
