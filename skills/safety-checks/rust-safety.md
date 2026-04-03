# Rust Safety Patterns

## Crate-level safety

- `#![forbid(unsafe_code)]` on every crate unless unsafe is genuinely required
- If unsafe is needed, isolate it in a dedicated module with safety comments
  explaining each invariant
- Audit unsafe in dependencies: `cargo geiger` or `cargo deny`

## Input validation

- No bare `.unwrap()` or `.expect()` on data from external sources - use
  `?` operator or explicit error handling
- Validate slice lengths before indexing: check `slice.len() >= required`
  before `slice[index]`
- Use `checked_add`, `checked_mul`, `saturating_add` for arithmetic on
  external values - integer overflow panics in debug, wraps in release
- `serde` deserialization: use `#[serde(deny_unknown_fields)]` and custom
  deserializers with size limits for untrusted input

## Parser safety

- Set recursion/nesting depth limit (typical: 32-128)
- Cap string length during parsing (typical: 1-10MB)
- Cap collection sizes during deserialization (typical: 10K-1M)
- Detect and reject unterminated sequences (missing closing bracket, quote)
- Use iterative parsing instead of recursive where possible to avoid stack overflow

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

## SQL/Query injection

- Use parameterized queries with `sqlx::query!()` or `sqlx::query_as!()`
- For GQL/Cypher: use parameterized execution or sanitize with allow-list
  character filtering and length truncation
- Never interpolate user strings into any query language with `format!()`

## Resource bounds

- `tower::limit::ConcurrencyLimit` and `RateLimit` for HTTP services
- `axum::extract::DefaultBodyLimit` for request body size caps
- Bounded channels (`tokio::sync::mpsc::channel(N)`) not unbounded
- `tokio::time::timeout()` on every external call and long-running operation
- Bounded caches: use LRU with max capacity, not unbounded HashMap

## Memory safety patterns

- Prefer `Vec::with_capacity(min(user_len, MAX))` over `Vec::with_capacity(user_len)`
- `Bytes` / `BytesMut` for zero-copy network buffer sharing
- `Arc<T>` + `ArcSwap` for lock-free shared reads
- Minimize critical sections - hold locks for the shortest time possible
- Explicit lock ordering when multiple locks are needed (document the order)

## Error handling

- `thiserror` for library error types, `anyhow` for application error types
- Never expose internal error details to clients - map to appropriate
  HTTP status codes with generic messages
- Log the full error server-side at `error!` or `warn!` level
- `tracing` for structured logging with span context
