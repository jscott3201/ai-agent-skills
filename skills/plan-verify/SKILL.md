---
name: plan-verify
description: >
  Verify an implementation plan against the actual codebase before starting work.
  Use when about to implement from a plan document or when a plan references
  specific files, functions, or APIs.
---

## Purpose

Catch factual errors in implementation plans before they become implementation
bugs. Plans make claims about what exists, how APIs work, and where code lives.
These claims go stale or were wrong to begin with. Verify them.

## Instructions

For each task in the plan, verify the following against the actual codebase.
Use grep and read - do not trust the plan's claims.

### 1. File existence

Every file path mentioned in the plan (create, modify, test) - check that:

- Files listed as "modify" actually exist at the stated path
- Files listed as "create" do not already exist (avoid overwrites)
- Parent directories exist or are created in an earlier task

### 2. API signatures

Every function, method, struct, trait, or type referenced in the plan:

- Grep for the actual definition
- Compare the signature (parameters, return type, generics) against what the plan claims
- Check for renames - the function may exist under a different name

### 3. Data flow accuracy

For claims about how data moves through the system:

- Trace the actual call chain from entry point to the code being modified
- Verify intermediate types match what the plan expects
- Check that the plan's assumptions about ownership, mutability, and lifetimes are correct

### 4. Dependency ordering

For task dependencies (blocks/blocked-by):

- Verify that earlier tasks actually produce what later tasks consume
- Check that no circular dependencies exist
- Confirm wave/parallel groupings are safe (no shared state between parallel tasks)

### 5. Present findings

Report in three categories:

- **Confirmed** - plan claims that match the codebase
- **Inaccurate** - claims that are wrong, with the actual state and a proposed correction
- **Missing context** - things the plan does not mention but should (new dependencies, side effects, migration needs)

Get alignment on all inaccuracies before any implementation begins.

## Guidance

The most common plan errors are: renamed functions, changed return types,
incorrect assumptions about what data is available at a given call site, and
line number drift from recent changes. API signatures are the highest-value
check - a wrong signature cascades through every task that depends on it.

If a plan has more than 3 inaccuracies, consider whether it needs a rewrite
rather than patching individual claims.
