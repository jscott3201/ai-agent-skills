---
name: no-shortcuts
description: >
  Cross-cutting changes must touch all affected sites. No partial
  implementations, no wildcard arms, no deferring. Use when a change
  affects multiple call sites across the codebase.
---

## Purpose

When a change affects N call sites, modify all N. Do not prioritize a subset
and defer the rest. Partial changes create inconsistency that is harder to
find later than doing it all now.

**When NOT to use:** The change affects a single call site (just fix it).
The user is exploring or prototyping (cross-cutting discipline applies
to committed code). The change is additive with no existing consumers.

## Instructions

### 1. Recommend a checkpoint

Before starting the cross-cutting change, suggest committing all current work
as a clean rollback point. If the user declines, proceed but note the risk.

### 2. Find all affected sites

Use the compiler or equivalent tooling to discover every site that needs
updating. Do not rely on manual search alone.

**Rust:**
```bash
cargo check --workspace 2>&1
```
Compiler errors and warnings enumerate every affected site.

**TypeScript:**
```bash
tsc --noEmit 2>&1
```

**Other languages:** Use the language's type checker, linter, or grep for the
changed symbol name. The goal is a complete list, not a sample.

### 2b. Confirm scope with user

Present the list of affected sites and get confirmation:

> "Found N affected sites across M files:
>
> [List the files and count of sites per file, grouped logically]
>
> This is a cross-cutting change. Options:
> 1. **Proceed** - fix all N sites now
> 2. **Review** - walk through sites one at a time before fixing
> 3. **Abort** - the scope is larger than expected, reconsider the approach
>
> I recommend proceeding. The compiler found all sites, and partial changes
> create inconsistency."

Wait for the user's decision. If the user chooses "Review," present each
affected site one at a time with the proposed change before applying it.

### 3. Fix every site

Work through every affected site. For each one:

- Use explicit handling, not catch-alls
- No wildcard match arms (`_ => ...`) to suppress new variants
- No `#[allow(...)]` or equivalent to silence warnings
- No "handle the important ones now, clean up later"

If a site genuinely does not need to change, document why with a comment at
that site.

### 4. Verify

Run the full workspace build and test suite:

```bash
cargo check --workspace && cargo test --workspace --all-features
```

Or equivalent for the project's language. Zero warnings, zero failures.

### 5. Handle failure

If the change cascades further than expected or breaks something:

- If a checkpoint commit exists, revert to it
- If not, use `git stash` or `git diff > patch.diff` to save progress
- Report what happened and get guidance before continuing

## Verification

- [ ] All affected call sites identified via grep
- [ ] Every call site updated (no "will handle later")
- [ ] No wildcard arms or catch-all branches introduced
- [ ] Compilation passes after all sites updated

## Red Flags

Stop and reassess if you observe:
- Using `_ => ...` wildcard arms to handle new variants
- Adding `#[allow(...)]` or equivalent to silence warnings
- Fixing some call sites and deferring others with TODO comments
- Using grep instead of the compiler to find affected sites

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Handle the important sites now, fix the rest later" | Later never comes. Partial implementations leave traps for the next developer. |
| "Wildcard arm quiets the compiler" | Wildcards hide new variants. The compiler warning is telling you something; silencing it creates silent bugs. |
| "These sites are internal/private, skip them" | Internal code still executes. A missed call site is a bug regardless of visibility. |
| "Grep will find all occurrences" | Grep finds strings, not semantics. The compiler/type checker finds actual usage — use it. |
| "Add a TODO and defer remaining sites" | A TODO is a promise with no enforcement. Fix it now or accept the tech debt consciously with the user. |

## Guidance

The most common shortcuts are: handling 3 of 5 enum variants and using a
wildcard for the rest, updating "key" call sites and deferring others, and
adding `#[allow(unused)]` to silence warnings from incomplete changes.

All of these trade immediate convenience for future confusion. The compiler
found every site for a reason - each one is a place where the old assumption
is now wrong.
