# Review Patterns Reference

Detailed patterns and examples for each review category. Load this file
during deep reviews for specific detection guidance.

## Concurrency hazards

### Lock ordering violations

All code paths must acquire locks in the same global order. A violation:

```
Thread A: lock(mutex_a) -> lock(mutex_b)
Thread B: lock(mutex_b) -> lock(mutex_a)  // DEADLOCK
```

Look for: nested lock acquisitions, multiple mutex/rwlock guards alive in
the same scope, lock acquisition inside callbacks or closures.

### Lock held across await

Holding a synchronous lock guard across an `.await` point can deadlock:

```rust
// WRONG: MutexGuard alive across await
let guard = mutex.lock().unwrap();
let result = some_async_call().await;  // guard still held
drop(guard);

// RIGHT: drop before await
let data = {
    let guard = mutex.lock().unwrap();
    guard.clone()
};
let result = some_async_call().await;
```

In async Rust, use `tokio::sync::Mutex` if the lock must span an await,
or restructure to release before the await point.

### TOCTOU (Time-of-Check-to-Time-of-Use)

A condition is verified, then a gap allows another operation to change it:

```python
# VULNERABLE: gap between check and use
if os.path.exists(filepath):
    # another process could delete the file here
    with open(filepath) as f:
        data = f.read()
```

Fix: use atomic operations, hold a lock from check through use, or handle
the failure at the use site instead of checking first.

### Shared mutable state

Look for: global mutable variables accessed from multiple threads/tasks,
`Arc<Mutex<T>>` patterns that could use `Arc<RwLock<T>>` or `ArcSwap` for
read-heavy workloads, message-passing alternatives to shared state.

## Performance patterns

### N+1 queries

A loop that makes one database/API call per iteration:

```python
# N+1: one query per order
orders = db.query("SELECT * FROM orders WHERE user_id = ?", user_id)
for order in orders:
    items = db.query("SELECT * FROM items WHERE order_id = ?", order.id)
```

Fix: batch query, JOIN, or eager loading.

### Allocation in hot paths

Object creation inside tight loops:

```rust
// WRONG: allocates a String every iteration
for item in items {
    let key = format!("prefix_{}", item.id);
    map.insert(key, item);
}

// BETTER: reuse a buffer
let mut buf = String::new();
for item in items {
    buf.clear();
    write!(buf, "prefix_{}", item.id).unwrap();
    map.insert(buf.clone(), item);
}
```

Also flag: regex compilation inside loops (compile once outside), closure
creation in hot loops, unnecessary `.clone()` of large structures.

### Synchronous I/O in async context

Blocking calls in async code starve the executor:

```rust
// WRONG: blocks the async runtime
async fn process() {
    let data = std::fs::read_to_string("file.txt").unwrap(); // BLOCKING
}

// RIGHT: use async I/O
async fn process() {
    let data = tokio::fs::read_to_string("file.txt").await.unwrap();
}
```

Also flag: `std::thread::sleep` in async code (use `tokio::time::sleep`),
CPU-intensive computation without `spawn_blocking`.

### Unbounded iteration

Queries or iterations with no limit on result size:

```python
# DANGEROUS: could return millions of rows
results = db.query("SELECT * FROM events WHERE type = ?", event_type)
for result in results:
    process(result)
```

Fix: add LIMIT/pagination, cap the iterator, or stream with backpressure.

## Resource lifecycle

### File handle leaks

Every opened file must be closed on all code paths, including error paths:

```python
# WRONG: leak on exception
f = open("data.txt")
data = process(f.read())  # if process() throws, f is never closed
f.close()

# RIGHT: context manager
with open("data.txt") as f:
    data = process(f.read())
```

Rust equivalent: RAII handles this automatically, but watch for
`ManuallyDrop`, `mem::forget`, or `Box::leak` that bypass drop.

### Connection pool leaks

Database connections acquired but not returned on error paths:

```rust
// WRONG: connection not returned if process() fails
let conn = pool.acquire().await?;
let result = process(&conn).await?;  // if this fails, conn may not return
pool.release(conn);

// RIGHT: use a guard that returns on drop
let conn = pool.acquire().await?;
// conn returns to pool when dropped
```

Look for: explicit `release`/`close` calls that could be skipped on
error paths, connections stored in long-lived structs without cleanup.

### General pattern

For any acquired resource, verify:
1. Acquisition has a corresponding release
2. Release happens on ALL code paths (success, error, panic)
3. The release mechanism is automatic (RAII, context manager, finally)
   rather than manual

## Boundary conditions

### Off-by-one errors

The most common pattern: miscounting items vs intervals.

```
10 fence sections need 11 fence posts
Array of length 5: valid indices 0-4, not 0-5
"Between 1 and 5" may or may not include 5 depending on the API
```

Test mentally at: 0, 1, typical value, max-1, max, max+1.

### Empty collection handling

What happens when a list, map, or result set has zero items?

```rust
// WRONG: panics on empty
let first = items[0];
let max = items.iter().max().unwrap();

// RIGHT: handle empty case
let first = items.first().ok_or(Error::Empty)?;
let max = items.iter().max().unwrap_or(&default);
```

### Integer overflow

Rust: debug panics, release silently wraps. Both are wrong for external data.

```rust
// WRONG in release mode
let total: u32 = count * size;  // silent wrap if product > u32::MAX

// RIGHT
let total = count.checked_mul(size).ok_or(Error::Overflow)?;
```

Python: arbitrary precision integers avoid overflow but can cause memory
exhaustion with attacker-controlled values. Cap input magnitude.

JavaScript: all numbers are f64. Integer precision lost above 2^53.
Use BigInt for large integer arithmetic.

## Error handling

### Swallowed errors

Catching and discarding:

```python
# WRONG: error silently disappears
try:
    process(data)
except Exception:
    pass

# ALSO WRONG: logged but not propagated
try:
    process(data)
except Exception as e:
    logger.error(f"Error: {e}")
    # caller thinks it succeeded
```

### Missing rollback

Multi-step operations that partially succeed:

```python
# WRONG: if step 2 fails, step 1 is not rolled back
create_user(data)          # step 1: succeeds
create_user_profile(data)  # step 2: fails
# database now has a user without a profile
```

Fix: use transactions, or implement compensating actions on failure.

### Wrong error granularity

Catching too broadly hides real issues:

```python
# WRONG: catches everything including programming errors
try:
    result = complex_operation()
except Exception:
    return default_value

# RIGHT: catch specific expected errors
try:
    result = complex_operation()
except ConnectionError:
    return default_value
except ValueError as e:
    raise InvalidInput(str(e))
```

## State management

### Cache invalidation

When data is mutated, all caches that hold that data must be invalidated:

- Check: does the mutation function know about all caches?
- Check: are there multiple cache layers (app cache, CDN, browser)?
- Check: do related caches get invalidated? (user cache when user's
  team membership changes)

### Stale reads

Reading cached/old data after a mutation in the same request:

```python
# WRONG: reads stale cache after mutation
update_user_role(user_id, "admin")
user = get_user_from_cache(user_id)  # still has old role
```

Fix: invalidate before read, or read from the write path's return value.

## Post-implementation specific checks

These apply to post-implementation reviews but not to individual PR reviews:

1. **Integration completeness** - are all pieces actually wired together?
   No orphaned functions, no dead configuration, no unregistered routes.
2. **Cross-module consistency** - do all parts use the same patterns for
   error handling, logging, configuration, naming?
3. **Dependency graph health** - do new modules create circular dependencies
   or unhealthy coupling between layers?
4. **Documentation alignment** - does the README/docs describe what was
   actually built, or what was originally planned?
5. **Operational readiness** - logging, monitoring, feature flags, rollback
   capability for the new feature.
