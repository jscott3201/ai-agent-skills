# JavaScript/TypeScript Safety Patterns

## Input validation

- Use `zod`, `joi`, or `ajv` for schema validation on all external input
- `JSON.parse()` on untrusted input: check `Buffer.byteLength(raw) < MAX` first
- Never use `eval()`, `new Function()`, or `setTimeout(string)` with user input
- `parseInt()` always with radix: `parseInt(value, 10)`
- Validate and sanitize before use, not after

## Authentication

- `crypto.timingSafeEqual()` for token comparison, not `===`
- `crypto.randomBytes()` or `crypto.randomUUID()` for token generation
- `bcrypt` or `argon2` for password hashing, not raw crypto.createHash
- JWT: validate `alg` field (reject `none`), check `exp`, verify with correct key
- Store refresh tokens server-side, not in localStorage

## SQL injection

- Use parameterized queries with your ORM/driver:
  ```javascript
  // pg
  client.query('SELECT * FROM users WHERE id = $1', [userId])
  // prisma
  prisma.$queryRaw`SELECT * FROM users WHERE id = ${userId}`
  ```
- Never use template literals or string concatenation to build SQL
- ORMs (Prisma, Drizzle, Sequelize) are safe through their query API;
  raw queries still need parameterization

## XSS prevention

- React/Vue/Svelte auto-escape by default - do not bypass with
  `dangerouslySetInnerHTML`, `v-html`, or `{@html}` on user content
- If raw HTML is needed, sanitize with `DOMPurify` or `sanitize-html`
- Set `Content-Security-Policy` headers to restrict inline scripts
- `httpOnly` and `secure` flags on all auth cookies

## Path traversal

- `path.resolve()` then verify result starts with allowed base directory
- Never use `path.join(base, userInput)` without checking the resolved
  path stays under `base`
- `express.static()` is safe; custom file serving needs path validation

## Command injection

- Use `child_process.execFile()` or `child_process.spawn()` with array
  args - these do not invoke a shell
- Never pass user input to shell-invoking functions
- If shell features are needed, validate input against strict allow-list

## Prototype pollution

- `Object.create(null)` for dictionary objects from user input
- Reject `__proto__`, `constructor`, `prototype` keys in user-provided objects
- Use `Map` instead of plain objects for user-keyed data
- `Object.freeze()` on configuration objects

## Resource limits

- `express.json({ limit: '1mb' })` or equivalent body parser limits
- `express-rate-limit` or `@fastify/rate-limit` on auth endpoints
- `AbortController` with `setTimeout` for fetch timeouts:
  ```javascript
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 5000)
  const response = await fetch(url, { signal: controller.signal })
  clearTimeout(timeout)
  ```
- Limit WebSocket message size and connection count
- `stream.pipeline()` with backpressure for large data transfers

## Secret handling

- `process.env` or secret managers (AWS Secrets Manager, Vault), never hardcoded
- `.env` files in `.gitignore`, never committed
- Logging: mask sensitive fields in structured loggers (pino redact option)
- No secrets in client-side bundles - use server-side env only

## Dependency safety

- `npm audit` or `pnpm audit` regularly
- Lock file (`package-lock.json`, `pnpm-lock.yaml`) committed to repo
- Avoid packages with postinstall scripts that run arbitrary code
- Review transitive dependencies for known vulnerabilities
