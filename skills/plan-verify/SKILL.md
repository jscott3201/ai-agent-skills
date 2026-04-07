---
name: plan-verify
description: >
  Verify an implementation plan against the actual codebase before starting
  implementation. Use when about to execute tasks from a plan document.
---

## Purpose

This is Stage 5a of the `feature-design` workflow, but can also be invoked
standalone on any implementation plan.

Catch factual errors in implementation plans before they become implementation
bugs. Plans make claims about what exists, how APIs work, and where code lives.
These claims go stale or were wrong to begin with. The most common plan errors
are naming hallucinations (referencing renamed functions), mapping hallucinations
(wrong data flow assumptions), and resource hallucinations (files or APIs that
do not exist).

## Instructions

For each task in the plan, verify the following against the actual codebase.
Use grep and read. Do not trust the plan's claims. See
[verification-checklist.md](verification-checklist.md) for the complete
mechanical checklist.

### 1. Staleness check

If the plan references a creation date or commit, check whether the
codebase has changed since then:

```bash
git log --oneline <plan-date>..HEAD -- <referenced-files>
```

If referenced files have changed, the plan's claims about those files are
suspect. Verify each claim against the current state, not the state when
the plan was written.

### 2. File existence

Every file path mentioned in the plan (create, modify, test):

- Files listed as "modify" actually exist at the stated path
- Files listed as "create" do not already exist (avoid overwrites)
- Parent directories exist or are created in an earlier task

### 3. API signatures

Every function, method, struct, trait, or type referenced in the plan:

- Grep for the actual definition
- Compare the signature (parameters, return type, generics) against what
  the plan claims
- Check for renames: if a symbol is not found, search for symbols with
  similar names in the same file where the plan expected it
- Check for deprecation markers (`#[deprecated]`, `@deprecated`)

This is the highest-value check. A wrong signature cascades through every
task that depends on it.

### 4. Data flow accuracy

For claims about how data moves through the system:

- Trace the actual call chain from entry point to the code being modified
- Verify intermediate types match what the plan expects
- Check that the plan's assumptions about ownership, mutability, and
  lifetimes are correct

### 5. Dependency ordering

For task dependencies (blocks/blocked-by):

- Verify that earlier tasks actually produce what later tasks consume
- Check that no circular dependencies exist (topological sort the graph)
- Confirm dependency edges are symmetric (if A blocks B, B's blocked-by
  includes A)
- Verify every task ID referenced in a dependency actually exists in the plan

### 6. Parallel task safety

For tasks assigned to the same execution wave:

- No two parallel tasks modify the same file
- Parallel tasks have no dependency edges between them
- Parallel tasks do not create conflicting state (e.g., both registering
  the same route or type)

### 7. Placeholder scan

Search the plan for incomplete content:

- "TBD", "TODO", "implement later", "fill in details"
- "similar to Task N" (each task must be self-contained)
- Vague instructions without code ("add appropriate error handling")
- References to types, functions, or methods not defined in any task

### 8. Present findings

Present inaccuracies and missing context **one at a time**, starting with
the highest blast-radius items:

1. For each inaccuracy, present:
   - The plan claim vs the actual codebase state
   - Your proposed correction
   - Your recommendation and why: "I recommend [accept/investigate]
     because [reason — e.g., straightforward rename vs uncertain behavior change]"
   - Ask: **accept correction**, **adjust correction**, or **investigate
     further**
2. Wait for the user's decision before presenting the next finding
3. After all inaccuracies are resolved, summarize confirmed items and stale
   items as a group (these require no immediate decision)

Summarize: "N confirmed, N inaccurate (N corrected), N missing context,
N stale."

### 9. Quality gate

Based on findings, recommend one of:

| Decision | Criteria |
|----------|----------|
| **Go** | Zero inaccuracies, all mechanical checks pass |
| **Fix and go** | 1-3 inaccuracies, all correctable by patching specific claims |
| **Rewrite** | More than 3 inaccuracies, OR any inaccuracy in the core architecture or data model |
| **Kill** | Fundamental assumption is invalid (the API the plan builds on does not exist, the approach is architecturally wrong) |

Get alignment on the decision before any implementation begins.

## Supporting files

- [verification-checklist.md](verification-checklist.md) - complete mechanical verification checklist

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Plan was reviewed already, assume correct" | Plans decay the moment code changes. Verification catches drift that review cannot. |
| "A few API references checked, that's enough" | Partial checking gives false confidence. One wrong signature wastes hours of implementation. |
| "No obvious path errors, skip file checks" | Obvious errors are caught during planning. Verification catches the non-obvious ones — renamed files, moved modules. |
| "Plan is 2 days old, skip staleness check" | Two days of active development can change dozens of files. Age alone doesn't predict staleness. |
| "Inaccuracies can be fixed during implementation" | Fixing during implementation costs 10x more than fixing during verification. |

## Guidance

**API signatures are the highest-value check.** Research shows naming and
resource hallucinations (referencing things that do not exist or exist
under different names) are the most common LLM plan errors. One wrong
signature cascades through every downstream task.

**Location of inaccuracies matters more than count.** One wrong core API
signature is worse than three wrong comment references. The quality gate
should weight inaccuracies by their blast radius: how many tasks depend
on the incorrect claim?

**The cost of verification is minutes. The cost of a stale plan is hours.**
Always err on the side of re-verification, especially after days have
passed since the plan was written or after other work has merged.
