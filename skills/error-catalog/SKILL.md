---
name: error-catalog
description: >
  Design error type hierarchies for Rust crates. Analyzes failure modes,
  proposes error enums, ensures From chains, and verifies propagation.
  Use when creating or redesigning error types.
disable-model-invocation: true
argument-hint: "[crate or module name]"
---

## Purpose

Design error types correctly upfront rather than discovering propagation
gaps during code review. Analyzes all failure modes in a module or crate,
proposes a structured error enum hierarchy, ensures proper conversion
chains, and verifies all `?` propagation paths are covered.

## Instructions

### 1. Analyze failure modes

For the target crate or module (`$ARGUMENTS`):

1. Read all functions that return `Result`
2. Catalog every failure mode: I/O errors, parse errors, validation
   failures, external service errors, internal invariant violations
3. Group by source: which errors come from dependencies, which are
   domain-specific, which represent programming errors

### 1b. Confirm design approach

Before proposing the full error hierarchy, present 2-3 structural options
with tradeoffs:

> "For [crate/module], I see N failure modes across M sources. Design options:
>
> 1. **Single enum** (recommended) - one `Error` type per crate with
>    variants per failure source. Simple, standard, good for most crates.
> 2. **Split enums** - separate error types per domain (e.g., `ParseError`,
>    `RuntimeError`). Better when failure domains never intersect.
> 3. **Flat + context** - single enum with a generic context field for
>    dynamic information. More flexible, less type-safe.
>
> I recommend [option] because [reason]. Which approach?"

Also confirm the scope:
- Per-crate or per-module error types?
- Wrap dependency errors or expose them?

Wait for the user's decisions before designing the hierarchy.

### 2. Design the error hierarchy

Propose an error enum using `thiserror`:

```rust
/// Errors produced by [crate-name].
#[derive(Debug, thiserror::Error)]
pub enum Error {
    /// Failed to read or write data.
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    /// Input failed validation.
    #[error("validation: {message}")]
    Validation { message: String, field: &'static str },

    /// External service returned an error.
    #[error("service error: {service}: {detail}")]
    Service { service: &'static str, detail: String },

    /// Internal invariant violated.
    #[error("internal: {0}")]
    Internal(String),
}
```

**Design rules:**
- One error type per crate (or per major module if the crate is large)
- Use `#[from]` for direct conversion from dependency errors
- Wrap dependency errors rather than re-exporting them (prevents leaking
  internal dependencies to consumers)
- Include enough context for debugging: what failed, where, and why
- Separate recoverable errors from programming errors

### 3. Verify conversion chains

For every function that uses `?`:

1. Trace what error types can be produced at each `?` site
2. Verify each has a `From` impl (either `#[from]` or manual)
3. Flag any gaps where `?` would fail to compile
4. Flag any overly broad conversions (e.g., `From<Box<dyn Error>>`)

### 4. Check context propagation

Errors must carry enough context for debugging:

- **File/resource names** for I/O errors
- **Field names** for validation errors
- **Request/response details** for service errors
- **Expected vs actual** for type or format mismatches

If an error variant discards context (e.g., `Io(std::io::Error)` without
noting which file), suggest adding context fields.

### 5. Verify consumer handling

Check that callers handle error variants appropriately:

- No wildcard match on error types (`_ =>` hides new variants)
- Errors logged at appropriate levels (internal = error!, validation = warn!)
- User-facing error messages do not leak internal details
- Errors at API boundaries are mapped to appropriate status codes

### 6. Present the design

Report:
- The proposed error type with all variants
- Conversion chain diagram (which errors convert to which)
- Any gaps or issues found in existing error handling
- Migration plan if redesigning existing error types

## Guidance

**One error type per crate is the default.** Split only if the crate has
genuinely distinct error domains (e.g., a `ParseError` and a `RuntimeError`
that never convert to each other).

**`anyhow` for applications, `thiserror` for libraries.** Library crates
expose typed errors for consumers. Application crates can use `anyhow` for
convenience at the top level.

**Never expose dependency errors directly.** `pub enum Error { Serde(serde_json::Error) }`
forces consumers to depend on `serde_json`. Wrap it:
`Serialization { detail: String }`.
