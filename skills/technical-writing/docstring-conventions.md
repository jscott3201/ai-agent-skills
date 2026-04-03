# Docstring Conventions by Language

Follow these conventions when writing doc strings. The universal rule:
don't restate information the type system already provides. Focus on
semantics, constraints, edge cases, and the "why."

## Rust

Use `///` for item documentation, `//!` for module/crate-level docs.

**Summary:** third person singular present indicative ("Returns", "Creates",
not "Return" or "Create").

**Standard sections:** `# Examples` (always plural), `# Panics`, `# Errors`,
`# Safety` (for unsafe functions).

**Examples are tested.** Code in `# Examples` runs as part of `cargo test`.
Ensure they compile and pass.

```rust
/// Returns the node at the given index.
///
/// Returns `None` if the index is out of bounds. This operation
/// is O(1) for contiguous storage and O(n) for linked storage.
///
/// # Panics
///
/// Panics if the arena has been poisoned by a concurrent modification.
///
/// # Examples
///
/// ```
/// let arena = Arena::new();
/// let id = arena.insert(42);
/// assert_eq!(arena.get(id), Some(&42));
/// ```
pub fn get(&self, index: NodeId) -> Option<&T> { ... }
```

**Linting:** enable `clippy::missing_docs` for public item coverage.

## Python (Google style)

Use triple-quoted strings. Google style is recommended for most projects
(compact, readable). NumPy style is preferred in scientific computing.

**Summary:** imperative or third person, on the first line after the
opening quotes.

**Sections:** `Args:`, `Returns:`, `Raises:`, `Examples:`.

```python
def fetch_user(user_id: int, include_deleted: bool = False) -> User | None:
    """Fetch a user by their database ID.

    Queries the users table with an optional filter for soft-deleted
    records. Returns None if no matching user exists.

    Args:
        user_id: Primary key of the user to fetch.
        include_deleted: If True, include soft-deleted users.

    Returns:
        The matching User, or None if not found.

    Raises:
        ConnectionError: If the database is unreachable.

    Examples:
        >>> user = fetch_user(42)
        >>> user.name
        'Ada Lovelace'
    """
```

**Linting:** Ruff rule `D` with `convention = "google"` in `pyproject.toml`.

## TypeScript (TSDoc)

Use `/** */` block comments. TSDoc is the recommended standard.

**Summary:** first sentence in the block. Extended description follows
after a blank line.

**Tags:** `@param name - description`, `@returns description`,
`@throws description`, `@example`, `@remarks`, `@deprecated`.

```typescript
/**
 * Fetches a user by their database ID.
 *
 * Queries the users table with an optional filter for soft-deleted
 * records. Returns undefined if no matching user exists.
 *
 * @param userId - Primary key of the user to fetch
 * @param includeDeleted - If true, include soft-deleted users
 * @returns The matching user, or undefined if not found
 * @throws {@link ConnectionError} if the database is unreachable
 *
 * @example
 * ```typescript
 * const user = await fetchUser(42);
 * console.log(user?.name);
 * ```
 */
async function fetchUser(
  userId: number,
  includeDeleted?: boolean
): Promise<User | undefined>
```

**Key rule:** Do not restate type information that TypeScript's type system
already provides. `@param userId` does not need `{number}` because the
signature already declares it as `number`.

**Linting:** `eslint-plugin-tsdoc` for format validation.

## Changelog format

Use `CHANGELOG.md` with the Keep a Changelog format. Latest version first.
ISO 8601 dates (YYYY-MM-DD).

Six categories:
- **Added** - new features
- **Changed** - changes to existing functionality
- **Deprecated** - features to be removed
- **Removed** - features removed in this release
- **Fixed** - bug fixes
- **Security** - vulnerability patches

Maintain an `[Unreleased]` section at the top. Never dump raw git log
into the changelog. Changelogs are for humans, not machines.
