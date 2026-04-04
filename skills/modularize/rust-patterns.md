# Rust Modularization Patterns

Language-specific guidance for restructuring Rust codebases. Load when the
modularize skill targets Rust code.

## Module splitting

### When to split a module

Split when any condition holds:
- File exceeds 500 lines of non-test code
- More than 3 distinct responsibilities in one file
- An `impl` block exceeds 200 lines
- Two developers frequently modify the same file for unrelated changes
- Borrow checker fights caused by god structs (see Compose Structs below)

### File-per-module style (preferred)

Use the modern layout over `mod.rs`:

```
src/
  network/
    client.rs
    server.rs
  network.rs      # module root (declares mod client; mod server;)
  lib.rs
```

Avoid `mod.rs` in new code. It causes tab-name confusion in editors and
the Rust 2018+ file-per-module style is equivalent.

### Extract module steps

1. Create `new_module.rs`
2. Move types, impls, and related functions into the new file
3. Add `mod new_module;` to the parent
4. Adjust visibility: items that were private need `pub(super)` or `pub(crate)`
5. Add `pub use new_module::MainType;` if the type should remain accessible
   at the parent path
6. Run `cargo check` to verify
7. Run full test suite

### Split impl blocks by concern

Rust allows multiple `impl` blocks for the same type across different files:

```rust
// storage/mod.rs
mod queries;
mod mutations;
pub struct Storage { /* fields */ }

// storage/queries.rs
impl Storage {
    pub fn get_user(&self, id: UserId) -> Option<User> { /* ... */ }
}

// storage/mutations.rs
impl Storage {
    pub fn create_user(&mut self, name: &str) -> User { /* ... */ }
}
```

## Crate extraction

### When to extract a crate

Extract to a separate workspace crate when:
- The module has standalone library value (other projects could use it)
- Independent versioning is needed
- Feature flags would reduce compilation for consumers
- Build parallelism would improve (the module has few dependencies)

### When to keep as a module

Keep within the crate when:
- Code is tightly coupled (many `pub(crate)` items needed if separated)
- Private types are shared with sibling modules
- Separate versioning adds overhead without benefit
- All crates would depend on each other (no parallelism gain)

### Workspace layout

Follow the flat workspace pattern (used by rust-analyzer, 200k+ lines):

```
Cargo.toml          # [workspace] with members = ["crates/*"]
crates/
  core/             # shared vocabulary types
  parser/           # parsing logic
  runtime/          # execution engine
  cli/              # binary entry point, depends on all above
```

The vocabulary crate pattern: one common crate holds shared types that
multiple crates depend on. Independent features live in their own crates.
A leaf crate ties everything together.

### Feature flags vs crate splitting

Prefer feature flags when:
- Code shares many internal types with the main crate
- Users want to opt into subsystems (like tokio's `rt`, `net`, `io`)
- The subsystem is not useful standalone

Prefer crate splitting when:
- Code is independently useful
- The subsystem has its own dependency tree
- Build time reduction is the primary goal

## Compose structs

The most important Rust-specific modularization pattern. Addresses borrow
checker contention from god structs.

### Problem

A struct with many fields causes `&mut self` to lock the entire struct,
even when a method only touches one field:

```rust
struct App {
    db: Database,
    cache: Cache,
    config: Config,
    metrics: Metrics,
    logger: Logger,
    // ... borrow checker prevents calling two &mut self methods
}
```

### Solution

Decompose into smaller structs grouped by responsibility:

```rust
struct App {
    storage: Storage,
    runtime: Runtime,
}

struct Storage {
    db: Database,
    cache: Cache,
}

struct Runtime {
    config: Config,
    metrics: Metrics,
    logger: Logger,
}
```

Now `&mut app.storage` and `&mut app.runtime` can coexist because the
borrow checker sees them as independent borrows.

### When to apply

- Struct has 7+ fields spanning multiple concerns
- Methods that touch one field cannot compose with methods touching another
- The `impl` block exceeds 200 lines with unrelated method groups

## Visibility tightening

### Default to minimal visibility

| Modifier | Scope | Use when |
|:--|:--|:--|
| (none) | Current module only | Internal helpers, implementation details |
| `pub(super)` | Parent module | Selectively widened access |
| `pub(crate)` | Current crate | Cross-module internal APIs |
| `pub` | External consumers | Documented, tested public API |

AI-generated code frequently over-exposes with `pub`. During modularization,
audit every `pub` item:
- Is it used outside this crate? Keep `pub`
- Is it used in other modules within this crate? Change to `pub(crate)`
- Is it only used in the parent module? Change to `pub(super)`
- Is it only used in this module? Remove `pub`

### Re-exports

Use `pub use` to create a flat API surface:

```rust
// lib.rs
pub use parser::Parser;
pub use runtime::Engine;
// Users write: use mycrate::Parser; instead of use mycrate::parser::Parser;
```

Avoid glob re-exports (`pub use module::*`) in library crates. Spell out
each re-exported name explicitly.

## Verification commands

After each structural change:

```bash
cargo check                    # compilation
cargo test                     # behavior preservation
cargo clippy -- -D warnings    # lint check
```

### Recommended clippy.toml thresholds

```toml
cognitive-complexity-threshold = 15
too-many-arguments-threshold = 5
too-many-lines-threshold = 60      # counts blank lines; ~50 lines of code
excessive-nesting-threshold = 4
```

## Decision flowchart

```
File > 500 lines?
├─ Yes → Split into submodules by responsibility
└─ No → Struct has > 7 fields spanning multiple concerns?
    ├─ Yes → Apply Compose Structs pattern
    └─ No → impl block > 200 lines?
        ├─ Yes → Split impl into concern-based files
        └─ No → Type shared across multiple crates?
            ├─ Yes → Extract to vocabulary crate
            └─ No → Keep as-is, tighten visibility
```
