---
name: docs-sync
description: >
  Full scan of all documentation against the current codebase to find and fix
  stale references. Use after major code changes, refactors, or feature removals.
argument-hint: "[focus area]"
---

## Purpose

Documentation drifts from code. After major changes, scan every documentation
surface against the current codebase to find stale references, removed features,
renamed types, and outdated examples. Report what needs fixing, then fix it.

**When NOT to use:** The user is in the middle of building a feature (docs
sync after the code stabilizes). Only a single doc file needs updating
(just edit it directly). The project has no documentation yet (write docs
first, don't sync nothing).

## Instructions

### Phase 1: Discovery

Spawn an Explore subagent using the Agent tool to perform the discovery phase.
This keeps the heavy codebase scanning out of the main conversation context.

If `$ARGUMENTS` was provided, use it to focus the scan (e.g., "removed federation
module" or "renamed auth types"). Otherwise, do a full scan.

The Explore subagent should scan these documentation surfaces against the
current codebase:

#### Surfaces to check

- `README.md`
- All files in `docs/` (recursive)
- `Benchmarks.md`
- `CLAUDE.md`
- `CHANGELOG.md`
- `.pyi` stub files (if Python bindings exist)
- `Dockerfile` and `docker-compose.yml` (if they exist)
- Code comments and doc strings that reference other modules or APIs

#### What to look for

1. **Removed references**
   - Grep for function names, type names, module names, and feature names
     mentioned in docs - verify each still exists in the codebase
   - Check for references to removed crates, deleted files, or deprecated APIs

2. **Renamed references**
   - Look for names that are close but not exact matches (common after refactors)
   - Check imports and use statements referenced in examples

3. **Outdated examples**
   - Code examples that reference old API signatures
   - Configuration examples with removed or renamed fields
   - CLI examples with changed flags or subcommands

4. **Stale metrics**
   - Test counts, benchmark numbers, LOC counts, crate counts
   - Version numbers that no longer match Cargo.toml
   - Feature lists that are incomplete or include removed features

5. **Structural gaps**
   - New public APIs or features with no documentation
   - New crates or modules missing from the project overview

#### Report format

For each stale reference found:

```
File: README.md:42
Issue: References `federation` module (removed in v0.8.0)
Fix: Remove the federation section and update the feature list
```

Group by file. Include the specific line or section.

### Phase 2: Triage with user

When the Explore subagent returns findings to the main context, present
each stale reference **one at a time**, grouped by file, starting with the
highest-impact issues:

1. For each stale reference, present:
   - The file, line, and what is stale
   - Your recommended fix (remove, update, rewrite)
   - Ask: **fix**, **skip**, or **defer**
2. Wait for the user's decision before presenting the next finding
3. At file boundaries, ask: "Continue to next file, or stop here?"

### Phase 3: Fix

For approved fixes:

1. Work through fixes file by file in the order approved
2. Apply technical writing conventions to all updated content
3. After all fixes, do a final grep for any remaining stale terms

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "README is most visible, rest can wait" | API docs and examples mislead more directly than READMEs. Fix what users copy-paste first. |
| "Stale examples aren't critical" | Stale examples waste hours for every user who tries them. They're the highest-cost stale content. |
| ".pyi stubs regenerate automatically" | They don't. They're the most commonly forgotten documentation surface after refactors. |
| "Spot-check a few version numbers" | The one you miss is the one someone copies into their config. Check them all. |

## Red Flags

Stop and reassess if you observe:
- Scanning only README and ignoring other documentation surfaces
- Fixing references without verifying the fix against current code
- Presenting all stale references at once instead of one at a time
- Skipping the final grep to confirm no remaining stale terms

## Verification

- [ ] All documentation surfaces scanned (README, docs/, comments, .pyi, Dockerfile)
- [ ] Stale references verified against current codebase
- [ ] Findings triaged one at a time with user
- [ ] Final grep for remaining stale terms after fixes

## Guidance

The highest-value checks are removed feature references and stale API examples.
These are what confuse users and future-you. A README that mentions a federation
feature that was removed 3 months ago is actively misleading.

Check .pyi stubs carefully if they exist - these are the most commonly forgotten
documentation surface after refactors that change Python-exposed APIs.
