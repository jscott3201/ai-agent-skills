# Rust Coding Standards

Best practices, naming conventions, and idiomatic patterns for Rust.
Load when the code-standards skill targets Rust code.

## Naming conventions

Rust enforces naming via compiler warnings. Follow RFC 430:

| Item | Convention | Example |
|:--|:--|:--|
| Crates | snake_case | `my_crate` |
| Modules | snake_case | `mod network_client` |
| Types (struct, enum, trait) | UpperCamelCase | `HttpClient`, `ParseError` |
| Functions, methods | snake_case | `process_order` |
| Local variables | snake_case | `user_count` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRIES` |
| Statics | SCREAMING_SNAKE_CASE | `DEFAULT_TIMEOUT` |
| Type parameters | Single uppercase or short CamelCase | `T`, `K`, `De` |
| Lifetimes | Short lowercase | `'a`, `'de` |

### Naming anti-patterns

- **Module name repetition**: use `io::Error`, not `io::IoError`.
  Clippy lint: `module_name_repetitions`
- **Negated booleans**: use `is_valid` not `is_not_invalid`
- **Hungarian notation**: no `str_name` or `vec_items`
- **Abbreviations**: spell out unless domain-standard (`ctx`, `cfg` are fine;
  `proc_ord` is not)

### Conversion and access naming

Follow the API Guidelines (C-CONV):

| Pattern | Method name | Example |
|:--|:--|:--|
| Borrowed → Borrowed | `as_` | `as_str()`, `as_bytes()` |
| Owned → Owned | `into_` | `into_inner()`, `into_vec()` |
| Borrowed → Owned | `to_` | `to_string()`, `to_vec()` |
| Access by ref | No prefix | `name()`, `len()` |
| Mutable access | No prefix + `_mut` | `name_mut()`, `get_mut()` |
| Predicate | `is_` or `has_` | `is_empty()`, `has_key()` |

## Visibility

Default to the minimum visibility needed:

1. Private (no modifier) for implementation details
2. `pub(super)` when only the parent module needs access
3. `pub(crate)` for cross-module internal APIs
4. `pub` only for the crate's documented external API

AI-generated code over-uses `pub`. Audit every public item: if nothing
outside the crate uses it, tighten to `pub(crate)`.

## Error handling

### Custom error types

Use `thiserror` for library error types, `anyhow`/`eyre` for application
error handling:

```rust
// Library: structured errors with thiserror
#[derive(Debug, thiserror::Error)]
pub enum ParseError {
    #[error("invalid token at position {position}: {token}")]
    InvalidToken { position: usize, token: String },
    #[error("unexpected end of input")]
    UnexpectedEof,
    #[error(transparent)]
    Io(#[from] std::io::Error),
}

// Application: context-rich errors with anyhow
fn load_config(path: &Path) -> anyhow::Result<Config> {
    let content = fs::read_to_string(path)
        .context("failed to read config file")?;
    toml::from_str(&content)
        .context("failed to parse config")
}
```

### Error anti-patterns

- **Stringly-typed errors**: `Err("something failed".into())` loses type info
- **Bare `.unwrap()`**: acceptable in tests and infallible cases, never on
  external input
- **`.expect()` without context**: use `.expect("config must be loaded before use")`
- **Swallowing errors**: `let _ = dangerous_op();` without logging
- **Box<dyn Error>** in library APIs: use concrete error types

## Idiomatic patterns

### Use iterators over manual loops

```rust
// Avoid
let mut results = Vec::new();
for item in items {
    if item.is_valid() {
        results.push(item.transform());
    }
}

// Prefer
let results: Vec<_> = items.iter()
    .filter(|item| item.is_valid())
    .map(|item| item.transform())
    .collect();
```

### Use `?` operator over match chains

```rust
// Avoid
let file = match File::open(path) {
    Ok(f) => f,
    Err(e) => return Err(e.into()),
};

// Prefer
let file = File::open(path)?;
```

### Use builder pattern for complex construction

When a struct has 4+ optional fields, provide a builder:

```rust
let config = Config::builder()
    .timeout(Duration::from_secs(30))
    .retries(3)
    .build()?;
```

### Use newtype for type safety

```rust
struct UserId(u64);
struct OrderId(u64);

// These are now distinct types - can't accidentally pass OrderId as UserId
fn get_user(id: UserId) -> User { ... }
```

### Prefer `impl Trait` in argument position

```rust
// Flexible: accepts any iterator of strings
fn process(items: impl IntoIterator<Item = String>) { ... }

// Instead of requiring a specific collection
fn process(items: Vec<String>) { ... }
```

## Anti-patterns

| Pattern | Problem | Fix |
|:--|:--|:--|
| Excessive `.clone()` | Avoids borrow checker instead of designing for it | Restructure ownership, use references |
| `Arc<Mutex<T>>` everywhere | Shared mutable state, defeats Rust's safety model | Channel-based communication, actor pattern |
| Stringly-typed enums | `match status.as_str() { "active" => ... }` | Use an enum with `FromStr`/`Display` |
| `Box<dyn Any>` | Type erasure, runtime panics | Use generics or trait objects with known traits |
| Wildcard match arms | `_ => {}` hides new variants | Handle all variants explicitly |
| `unsafe` for convenience | Bypasses safety guarantees | Find the safe alternative; document if truly needed |

## Clippy configuration

Recommended `clippy.toml` for enforcing these standards:

```toml
cognitive-complexity-threshold = 15
too-many-arguments-threshold = 5
too-many-lines-threshold = 60      # counts blank lines; ~50 lines of code
excessive-nesting-threshold = 4
type-complexity-threshold = 250
enum-variant-size-threshold = 200
```

### Key lint groups

```bash
# Pedantic: stricter but valuable
cargo clippy -- -W clippy::pedantic

# Useful individual lints
cargo clippy -- \
  -W clippy::cognitive_complexity \
  -W clippy::too_many_lines \
  -W clippy::too_many_arguments \
  -W clippy::module_name_repetitions \
  -W clippy::needless_pass_by_value \
  -W clippy::implicit_clone \
  -W clippy::redundant_closure_for_method_calls
```

## Trait design

- Traits should have 1-5 methods. Larger traits can often be split.
- Provide default implementations where a sensible default exists.
- Consider sealed traits when you don't want external implementations.
- Use associated types when there's exactly one valid type per implementor.
- Use generics when the caller chooses the type.
