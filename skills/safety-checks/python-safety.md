# Python Safety Patterns

## Input validation

- Use `pydantic` or `attrs` with validators for structured input, not raw dicts
- `json.loads()` on untrusted input: wrap with size check first (`len(raw) < MAX`)
- `yaml.safe_load()` only, never `yaml.load()` with untrusted data
- `pickle` is never safe for untrusted data - use JSON, msgpack, or protobuf
- `eval()` and `exec()` with user input is code injection

## Authentication

- `secrets.compare_digest()` for timing-safe token comparison, not `==`
- `secrets.token_urlsafe()` for generating tokens, not `random` module
- `hashlib` alone is not password hashing - use `bcrypt`, `argon2-cffi`, or `passlib`
- Store password hashes, never plaintext or reversible encryption

## SQL injection

- Always use parameterized queries with DB-API 2.0 placeholders:
  ```python
  cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
  ```
- Never use f-strings or `.format()` to build SQL
- ORMs (SQLAlchemy, Django ORM) are safe when using their query API;
  raw SQL through ORMs still needs parameterization

## Path traversal

- `pathlib.Path.resolve()` to canonicalize, then check `.is_relative_to(allowed_root)`
- Never use `os.path.join(base, user_input)` without validating the result
  stays under `base` - `../` in user_input escapes the base directory

## Command injection

- `subprocess.run(["cmd", arg1, arg2])` with list form, never `shell=True`
  with user input
- `shlex.quote()` if `shell=True` is unavoidable (rare)
- Never pass user input to `os.system()`

## Memory and resource limits

- Set `max_length` on file reads: `f.read(MAX_SIZE)`
- `itertools.islice()` to cap iteration over untrusted iterables
- `signal.alarm()` or `asyncio.wait_for()` for timeout enforcement
- `resource.setrlimit()` for process-level memory caps in long-running services

## Secret handling

- `os.environ` or `python-dotenv` for secrets, never hardcoded
- Logging: use a formatter that redacts known secret field names
- Avoid keeping secrets in Python strings longer than necessary

## Async safety (asyncio/FastAPI/Starlette)

- `asyncio.wait_for(coro, timeout=N)` on every external call
- Limit concurrent connections in ASGI middleware (e.g., `slowapi` for rate limiting)
- `httpx` timeouts: always set `timeout=httpx.Timeout(connect=5, read=30)`
- Never `await` unbounded generators from external input
