# Python Safety Patterns

## Input validation

- Use `pydantic` or `attrs` with validators for structured input, not raw dicts
- `json.loads()` on untrusted input: wrap with size check first (`len(raw) < MAX`)
- `yaml.safe_load()` only, never `yaml.load()` with untrusted data
- Unsafe deserialization formats (RCE risk): never use with untrusted input.
  Use JSON, msgpack, or protobuf instead.
- `eval()` and `exec()` with user input is code injection

## Server-Side Template Injection (SSTI)

```python
# VULNERABLE: user input in template string
template = Template(f"Hello {user_input}")
render_template_string("Hello " + user_input)

# SAFE: pass as variable
render_template_string("Hello {{ name }}", name=user_input)
```

Jinja2 SSTI payloads access Python internals via `__class__.__mro__` chains.
Never concatenate user input into template strings.

## Server-Side Request Forgery (SSRF)

```python
# VULNERABLE: unvalidated URL from user input
resp = requests.get(user_provided_url)  # can hit internal services

# Bypass vectors: 0x7f000001, IPv6 [::1], DNS rebinding,
# URL parser differences between validation and request libraries
```

Validate scheme (http/https only), resolve DNS and check against blocklist of
private ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.169.254,
::1). Validate AFTER DNS resolution to prevent DNS rebinding.

## Authentication

- `secrets.compare_digest()` for timing-safe token comparison, not `==`
- `secrets.token_urlsafe()` for generating tokens, not `random` module
- `hashlib` alone is not password hashing - use `bcrypt`, `argon2-cffi`, or `passlib`
- Store password hashes, never plaintext or reversible encryption

## SQL / GQL injection

- Always use parameterized queries:
  ```python
  cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
  ```
- Never use f-strings or `.format()` to build SQL or GQL queries
- For ISO GQL: use parameterized execution. Non-parameterizable elements
  (labels, property names) must be validated against allowlists or sanitized
  with character stripping and length truncation.
- ORMs are safe when using their query API; raw queries still need
  parameterization

## Path traversal

```python
# VULNERABLE
open(os.path.join(BASE_DIR, user_filename))  # ../../../etc/passwd

# SAFE: resolve and check
path = Path(BASE_DIR).joinpath(user_filename).resolve()
if not path.is_relative_to(Path(BASE_DIR).resolve()):
    raise ValueError("Path traversal detected")
```

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

## FastAPI-specific

- Use `Path(..., pattern="^[\\w-]*$")` for path parameters
- Validate all Pydantic models have explicit field definitions
  (prevents mass assignment via extra fields)
- Use `Depends(get_current_user)` on every route - missing it means
  anonymous access
- Body size limits via middleware, not just Pydantic validation

## Django-specific

- Always use ORM parameterized queries, never raw SQL with interpolation
- Validate IPv4 addresses (leading zeros bypass validation)
- `Storage.save()` path traversal (CVE-2024-39330) - validate filenames
- `ALLOWED_HOSTS` must be set in production (no wildcard `*`)
- CSRF middleware enabled, `@csrf_exempt` used sparingly with justification

## ML-specific

- `torch.load()` with untrusted models is unsafe (arbitrary code execution).
  Use `torch.load(path, weights_only=True)` or `safetensors` format.
- HuggingFace model downloads: verify model source and integrity
