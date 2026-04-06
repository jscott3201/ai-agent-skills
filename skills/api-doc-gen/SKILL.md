---
name: api-doc-gen
description: >
  Generate and update API documentation from code. Scans public items,
  generates doc comments, module overviews, and verifies doc-tests.
  Use when a crate or module needs documentation from scratch.
disable-model-invocation: true
argument-hint: "[crate or module path]"
---

## Purpose

Generate documentation for code that has none, or bring incomplete
documentation up to standard. Scans the public API surface, generates
doc comments following language conventions, creates module-level
overviews, and verifies that code examples compile.

## Instructions

### 1. Scan the public API

For the target (`$ARGUMENTS`):

1. Find all public items: functions, structs, enums, traits, type aliases,
   constants, modules
2. Identify which items already have documentation and which are bare
3. Assess the existing doc quality: are examples present? Are parameters
   documented? Are errors/panics documented?

Report: "Found N public items, M undocumented, K with incomplete docs."

### 1b. Confirm scope with user

Present the scan results and confirm scope before generating:

> "Found N public items: M undocumented, K with incomplete docs.
>
> Grouped by priority:
> 1. **Public API functions** (N items) - highest user impact
> 2. **Public types and traits** (N items) - needed for API understanding
> 3. **Module overviews** (N modules) - orientation and navigation
>
> I recommend starting with group 1. Generate docs for all groups, a
> specific group, or a subset? You can also exclude items that are
> intentionally undocumented."

Wait for the user to confirm scope before generating any documentation.

### 2. Generate documentation incrementally

Generate docs in batches of 5-10 items, grouped by module or logical area.
For each batch:

1. Write the doc comments for that batch
2. Run verification (doc-tests, compilation) for the batch
3. Present the batch to the user:

> "Batch N: documented [items] in [module/area].
> [Show a representative sample — 2-3 items, not all]
>
> Options:
> 1. **Accept** — keep these, move to next batch
> 2. **Adjust** — change the style or depth (explain what to change)
> 3. **Review all** — show every item in this batch before accepting
>
> I recommend accepting. [N items remain.]"

4. Wait for the user's decision before the next batch

This catches style mismatches early. If the first batch's tone or depth
is wrong, correct before generating 40 more items the same way.

For each item, generate documentation following the language's convention
(see the `technical-writing` skill's `docstring-conventions.md` for
format details).

**Rust documentation:**
- `///` for items, `//!` for module-level
- Summary in third person singular: "Returns", "Creates", "Parses"
- `# Examples` section with compilable code
- `# Panics` section if the function can panic
- `# Errors` section for functions returning `Result`
- `# Safety` section for unsafe functions

**Python documentation:**
- Google-style docstrings
- `Args:`, `Returns:`, `Raises:`, `Examples:` sections
- Type information in the signature, not duplicated in docs

**TypeScript documentation:**
- TSDoc `/** */` blocks
- `@param`, `@returns`, `@throws`, `@example` tags
- Don't restate type information from the signature

### 3. Create module-level overview

For each module without a `//!` (Rust) or module docstring:

1. Describe the module's purpose in 1-2 sentences
2. List the key types and functions with brief descriptions
3. Show a basic usage example
4. Note any important conventions or patterns

### 4. Generate crate-level documentation

If the crate root (`lib.rs` or `__init__.py`) lacks an overview:

1. Describe the crate's purpose and how it fits the workspace
2. Show a quick-start example
3. Link to key modules and types
4. Note feature flags and their effects (Rust)

### 5. Verify documentation

**Rust:** Run `cargo test --doc -p <crate>` to verify all code examples
compile and pass.

**Python:** Run `pytest --doctest-modules <module>` if doctest format is
used.

Fix any examples that fail to compile or produce wrong output.

### 6. Report

Summary of what was generated:
- Items documented: N new, M updated
- Module overviews: N created
- Doc-tests: N passing, M fixed
- Any items where documentation was unclear (flag for human review)

## Guidance

**Don't document the obvious.** A getter named `get_name` returning a
`String` does not need "Returns the name as a String." Instead, document
what "name" means in the domain, any invariants (is it ever empty?), and
when you would use this vs alternatives.

**Examples are the most valuable part.** A good example answers "how do I
use this?" more effectively than any prose description. Make examples
copy-pasteable and runnable.

**Doc-tests are free tests.** In Rust, every code example in `///` blocks
runs as a test. Use this to keep documentation accurate as code evolves.

**Batching prevents cascading errors.** Verifying after each batch of
5-10 items catches compilation errors and style mismatches before they
multiply across the remaining items.
