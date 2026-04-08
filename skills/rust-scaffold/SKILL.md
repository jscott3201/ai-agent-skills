---
name: rust-scaffold
description: >
  Scaffold a new Rust crate with layered architecture, feature flags, error
  types, and test structure. Use when creating a new crate or module.
disable-model-invocation: true
argument-hint: "[crate name]"
---

## Purpose

Create a new Rust crate that follows established conventions: layered
architecture, opt-in feature flags, forbidden unsafe code, proper error
types, and test infrastructure. Ensures new crates start with the right
structure rather than accumulating it later.

## Instructions

### 1. Gather requirements

Ask the user (skip any already provided via `$ARGUMENTS`):

- **Crate name:** kebab-case (e.g., `selene-graph`, `helios-protocol`)
- **Purpose:** one sentence on what this crate does
- **Layer position:** where it sits in the dependency hierarchy
  - Foundation (types, encoding) - no async, minimal deps
  - Middle (services, transport) - may need async
  - Top (client, server, CLI, bindings) - full dependencies
- **Async needed?** If yes, uses Tokio
- **Feature flags?** Any optional functionality to gate

### 2. Create the crate

#### Cargo.toml

```toml
[package]
name = "<crate-name>"
version = "0.1.0"
edition = "2024"
rust-version = "1.94"
description = "<purpose>"
license = "MIT"
publish = false

[dependencies]
thiserror = "2"
tracing = "0.1"
# tokio - add if async needed:
# tokio = { version = "1", features = ["rt-multi-thread", "macros"] }

[dev-dependencies]
# tokio = { version = "1", features = ["rt-multi-thread", "macros", "test-util"] }

[features]
default = []
# Add opt-in features here

[lints.rust]
unsafe_code = "forbid"
```

Adjust dependencies based on layer position:
- **Foundation:** minimal deps, consider `no_std` support
- **Middle:** add async runtime, domain-specific deps
- **Top:** full deps including HTTP framework, CLI, bindings

#### src/lib.rs

```rust
//! <purpose>

mod error;

pub use error::Error;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        // Replace with real tests
    }
}
```

#### src/error.rs

```rust
//! Error types for <crate-name>.

/// Errors produced by <crate-name>.
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("{0}")]
    Internal(String),
}
```

#### tests/ directory

Create `tests/` with a placeholder integration test:

```rust
// tests/integration.rs

#[test]
fn integration_placeholder() {
    // Replace with real integration tests
}
```

#### benches/ directory (if performance-relevant)

Create `benches/` with Criterion setup:

```rust
// benches/benchmarks.rs
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_placeholder(c: &mut Criterion) {
    c.bench_function("placeholder", |b| {
        b.iter(|| {
            // Replace with real benchmarks
        });
    });
}

criterion_group!(benches, bench_placeholder);
criterion_main!(benches);
```

Add to Cargo.toml:

```toml
[dev-dependencies]
criterion = { version = "0.5", features = ["html_reports"] }

[[bench]]
name = "benchmarks"
harness = false
```

### 3. Add to workspace

Add the new crate to the workspace `Cargo.toml`:

```toml
[workspace]
members = [
    # ... existing members
    "crates/<crate-name>",  # or appropriate path
]
```

If the crate is heavy (PyO3 bindings, gateway, CLI with many deps), add it
to `members` but exclude from `default-members` to keep normal builds fast:

```toml
[workspace]
members = ["crates/*"]
default-members = [
    # list only core crates, exclude heavy ones
]
```

### 4. Wire feature flags

If feature flags were requested:

- Add them to `[features]` in Cargo.toml
- Gate the relevant modules with `#[cfg(feature = "...")]`
- Document each feature in a comment above the `[features]` section
- All features are opt-in (not in `default`)

### 5. Verify

```bash
cargo check -p <crate-name>
cargo test -p <crate-name>
cargo clippy -p <crate-name> -- -D warnings
```

Report the crate is ready for development.

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Start minimal, add structure later" | Structure added later means refactoring existing code. Structure from the start means building on it. |
| "Feature flags add complexity" | Feature flags prevent dependency bloat. Without them, every consumer pays for every capability. |
| "Tests can wait until there's something to test" | The test infrastructure (fixtures, helpers, module structure) is harder to add retroactively. |
| "Copy the pattern from another crate" | Crate conventions evolve. Check the latest workspace conventions, not a crate that may be outdated. |

## Red Flags

Stop and reassess if you observe:
- Creating a crate without checking existing workspace conventions first
- Using `unsafe` without explicit user approval and safety comments
- Skipping feature flag setup for optional capabilities
- No test infrastructure in the scaffold (tests should exist from the start)

## Verification

- [ ] Requirements gathered (layer position, dependencies, features)
- [ ] Crate created with Cargo.toml, lib.rs, error.rs, tests
- [ ] Workspace Cargo.toml updated if applicable
- [ ] `cargo check --workspace` and `cargo test --workspace` pass

## Guidance

The layer position drives dependency decisions. Foundation crates should have
near-zero dependencies and avoid async - they are imported by everything above
them. Middle crates add domain logic and may need async. Top crates pull in
heavy dependencies like HTTP frameworks and are excluded from default builds
if they slow compilation.

When in doubt about feature flags, start without them. It is easier to add a
feature gate later than to remove one that has consumers.
