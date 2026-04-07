---
name: migration-guide
description: >
  Manage breaking API changes: catalog changes, generate migration guides,
  plan deprecation paths, and produce codemods. Use when making breaking
  changes to library crates with downstream consumers.
disable-model-invocation: true
argument-hint: "[crate name or change description]"
---

## Purpose

When making breaking API changes to library crates, ensure downstream
consumers have a clear, structured path to migrate. Catalog all breaking
changes, produce a migration guide, plan deprecation-first rollout when
possible, and optionally generate transformation scripts.

## Instructions

### 1. Catalog breaking changes

For the target package or change (`$ARGUMENTS`):

**Rust:**
```bash
cargo semver-checks check-release
```

**Python:** Review `__all__` exports, class/function signatures, removed modules.

**JavaScript/TypeScript:** Diff exported types and function signatures.
Check `package.json` `exports` and `types` fields.

Supplement all ecosystems with manual analysis: grep for changed public
signatures, removed types, renamed functions.

Classify each change:

| Type | Example | Migration Effort |
|:--|:--|:--|
| Removed | `pub fn old_name()` deleted | Find replacement or remove usage |
| Renamed | `old_name` -> `new_name` | Find-and-replace |
| Signature changed | New parameter, changed return type | Update call sites |
| Semantic change | Same signature, different behavior | Review and adjust logic |
| Type changed | `String` -> `&str`, enum variant added | Update types at call sites |
| Trait bound added | `T: Clone` added to generic | Ensure implementors satisfy bound |

### 1b. Confirm migration strategy

Present the catalog to the user and ask for the overall strategy:

> "I found N breaking changes. Two strategy options:
> 1. **Deprecation-first** - add deprecation warnings in a minor release,
>    remove in the next major. Safer for downstream consumers, takes two
>    releases.
> 2. **Immediate** - make all breaking changes in a single major release
>    with a migration guide. Faster, but consumers must migrate all at once.
>
> I recommend [option] because [reason]. Which approach?"

Then present each breaking change **one at a time**:

1. Show the change (what, type, affected sites)
2. Recommend a migration approach for this specific change
3. Ask the user to confirm or adjust before moving to the next change

### 2. Plan the migration path

**Prefer deprecation-first when possible:**

**Rust:**
1. Minor release: `#[deprecated(since = "N.x", note = "Use new_name instead")]`
2. Next major: remove the deprecated API

**Python:**
1. Minor release: add `warnings.warn("Use new_name", DeprecationWarning, stacklevel=2)`
2. Next major: remove the deprecated function

**JavaScript/TypeScript:**
1. Minor release: add `/** @deprecated Use newName instead */` JSDoc tag
   and `console.warn('Deprecated: use newName')` at runtime
2. Next major: remove the deprecated export

This gives consumers one release cycle to migrate without breaking them.

**When deprecation-first is not possible** (fundamental restructure):

1. Document all changes in a migration guide
2. Provide before/after code examples for each change
3. Suggest a migration order (which changes to make first)

### 3. Generate the migration guide

Save to `_agentskills/design/YYYY-MM-DD-<crate>-migration-guide.md`:

```markdown
# [Crate] v[OLD] -> v[NEW] Migration Guide

## Breaking Changes Summary

| Change | Type | Migration |
|--------|------|-----------|
| `old_fn` removed | Removed | Use `new_fn` instead |
| `Config::new` signature | Changed | Add `timeout` parameter |

## Detailed Migration Steps

### 1. [Change description]

**Before:**
[code example]

**After:**
[code example]

**Why:** [rationale for the breaking change]
```

### 4. Generate transformation aids (optional)

For simple renames and signature changes, offer:

- `sed` one-liners for find-and-replace across a project
- Rust deprecation attributes with migration notes
- A checklist of all changes for manual verification

### 5. Verify migration guide completeness

- Every breaking change in the catalog has a migration path
- Every migration path has before/after code examples
- The guide is ordered by dependency (changes that must be made first)
- The guide is tested: following the steps on example code produces
  a working result

## Verification

- [ ] All breaking changes cataloged
- [ ] Migration strategy confirmed with user
- [ ] Migration guide with before/after examples generated
- [ ] Transformation aids (codemods, scripts) provided where feasible
- [ ] Guide tested against a representative consumer

## Guidance

**Deprecation-first is always preferred.** It gives consumers time to
migrate on their schedule rather than being forced by a major version bump.
Only skip deprecation when the change is a fundamental restructure.

**Hyrum's Law.** With a sufficient number of users, every observable
behavior of your API will be depended upon by someone — including
behaviors you consider bugs or implementation details. This means even
"safe" changes (reordering fields, changing error messages, adjusting
timing) can break downstream consumers.

**Semantic changes are the hardest to migrate.** A renamed function is
easy to find-and-replace. A function that returns the same type but with
different behavior requires careful review of every call site. Flag
semantic changes prominently.

**Test the migration guide.** If possible, apply the guide's steps to a
sample consumer and verify the result compiles and passes tests.
