# Rust Safety Patterns

## Crate-level safety

- `#![forbid(unsafe_code)]` on every crate unless unsafe is genuinely required
- If unsafe is needed, isolate it in a dedicated module with safety comments
  explaining each invariant
- Audit unsafe in dependencies: `cargo geiger` for unsafe tracking,
  `cargo-audit` for known CVEs, `cargo-deny` for license and advisory policy,
  `cargo-crev` for peer review status

## Input validation

- No bare `.unwrap()` or `.expect()` on data from external sources - use
  `?` operator or explicit error handling
- Validate slice lengths before indexing: check `slice.len() >= required`
  before `slice[index]`
- `serde` deserialization: use `#[serde(deny_unknown_fields)]` and custom
  deserializers with size limits for untrusted input

## Integer overflow

```rust
// Debug: panics. Release: SILENT OVERFLOW.
let x: u32 = u32::MAX;
let y = x + 1;  // In release: y = 0

// SAFE: explicit overflow handling
let y = x.checked_add(1).ok_or(Error::Overflow)?;
let y = x.saturating_add(1);  // clamps at MAX
let y = x.wrapping_add(1);    // explicit wrapping
```

Flag any arithmetic on values derived from external input that uses default
operators (`+`, `-`, `*`) without `checked_` or `saturating_` variants.

## Parser safety

- Set recursion/nesting depth limit (typical: 32-128)
- Cap string length during parsing (typical: 1-10MB)
- Cap collection sizes during deserialization (typical: 10K-1M)
- Detect and reject unterminated sequences (missing closing bracket, quote)
- Use iterative parsing instead of recursive where possible to avoid
  stack overflow

## GQL/Query injection

- Never interpolate user strings into GQL with `format!()`:
  ```rust
  // VULNERABLE
  let query = format!("MATCH (n:User) WHERE n.name = '{}' RETURN n", input);

  // SAFE: parameterized execution
  let stmt = parse_statement("MATCH (n:User) WHERE n.name = $name RETURN n")?;
  execute_statement_with_params(stmt, params!{"name" => input})?;
  ```
- Non-parameterizable elements (labels, property names): validate against
  allowlists, strip disallowed characters, truncate to max length
- Sanitize with `sanitize_gql(s, max_len)` for any interpolated values

## Authentication

- `constant_time_eq` crate or `ring::constant_time::verify_slices_are_equal`
  for timing-safe comparison
- `argon2` or `bcrypt` crate for password hashing, not raw SHA/Blake
- Cap PBKDF2/Argon2 iterations to prevent DoS via high iteration requests
- `zeroize` crate on credential structs: `#[derive(Zeroize, ZeroizeOnDrop)]`
- Redact sensitive fields in `Debug` impls:
  ```rust
  impl fmt::Debug for Credentials {
      fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
          f.debug_struct("Credentials")
              .field("username", &self.username)
              .field("password", &"[REDACTED]")
              .finish()
      }
  }
  ```
- Do not derive `Clone` on types holding secrets

## Resource bounds

- `tower::limit::ConcurrencyLimit` and `RateLimit` for HTTP services
- `axum::extract::DefaultBodyLimit` for request body size caps
- Bounded channels (`tokio::sync::mpsc::channel(N)`) not unbounded
- `tokio::time::timeout()` on every external call and long-running operation
- Bounded caches: use LRU with max capacity, not unbounded HashMap
- `Vec::with_capacity(min(user_len, MAX))` not `Vec::with_capacity(user_len)`

## TOCTOU (Time-of-Check-to-Time-of-Use)

```rust
// VULNERABLE: gap between check and use in async code
let metadata = fs::metadata(path).await?;
if !metadata.permissions().readonly() {
    let content = fs::read_to_string(path).await?;  // file could change
}

// SAFE: use file descriptors, atomic operations, or database transactions
```

Flag any pattern where a check (exists, permissions, size) is followed by
a separate operation on the same resource across an `.await` point.

## Algorithmic complexity DoS

- `HashMap` with attacker-controlled keys: Rust's default `SipHash` is
  resistant, but flag any custom `Hasher` implementations
- Sorting algorithms: attacker can craft worst-case input for comparison-based
  sorts. Cap input size before sorting.
- Regex: avoid complex patterns on untrusted input. Use `regex` crate with
  size limits or `regex::RegexBuilder::size_limit()`
- Graph traversal: cap depth and visited-node count when traversing
  user-influenced graph structures

## Concurrency safety

- Document lock ordering when multiple locks are needed - deadlocks are silent
- Never hold a lock across an `.await` point (use `tokio::sync::Mutex` which
  is designed for this, or restructure to release before await)
- Minimize critical sections - hold locks for the shortest time possible
- `Arc<T>` + `ArcSwap` for lock-free shared reads

## Error handling

- `thiserror` for library error types, `anyhow` for application error types
- Never expose internal error details to clients - map to appropriate
  HTTP status codes with generic messages
- Log the full error server-side at `error!` or `warn!` level
- `tracing` for structured logging with span context

## Unsafe code audit checklist

When reviewing `unsafe` blocks (73% of Rust CVEs involve unsafe code):

- [ ] Null pointer: validated before dereference?
- [ ] Lifetime: does the reference outlive the data?
- [ ] Use-after-free: is the memory still valid?
- [ ] Uninitialized memory: is `MaybeUninit` handled correctly?
- [ ] Buffer bounds: are all accesses within allocated size?
- [ ] FFI: are C return values checked? Are buffers validated post-call?
- [ ] Safety comment: does the `// SAFETY:` comment explain the invariant?
