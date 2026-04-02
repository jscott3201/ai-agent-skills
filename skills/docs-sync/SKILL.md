---
name: docs-sync
description: >
  Full scan of all documentation against the current codebase to find and fix
  stale references. Use after major code changes, refactors, or feature removals.
context: fork
agent: Explore
---

## Purpose

Documentation drifts from code. After major changes, scan every documentation
surface against the current codebase to find stale references, removed features,
renamed types, and outdated examples. Report what needs fixing, then fix it.

## Instructions

### Phase 1: Discovery (runs in Explore subagent)

Scan the full documentation surface against the current codebase. Do not limit
to recent changes - check everything.

#### Documentation surfaces to check

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

### Phase 2: Fix (runs in main context)

After findings are reported to the main context:

1. Work through fixes file by file
2. Apply technical writing conventions to all updated content
3. After all fixes, do a final grep for any remaining stale terms

## Guidance

The highest-value checks are removed feature references and stale API examples.
These are what confuse users and future-you. A README that mentions a federation
feature that was removed 3 months ago is actively misleading.

Check .pyi stubs carefully if they exist - these are the most commonly forgotten
documentation surface after refactors that change Python-exposed APIs.
