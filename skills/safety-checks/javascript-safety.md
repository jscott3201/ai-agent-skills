# JavaScript/TypeScript Safety Patterns

## Input validation

- Use `zod`, `joi`, or `ajv` for schema validation on all external input
- `JSON.parse()` on untrusted input: check `Buffer.byteLength(raw) < MAX` first
- Never use `eval()`, `new Function()`, or `setTimeout(string)` with user input
- `parseInt()` always with radix: `parseInt(value, 10)`
- Validate and sanitize before use, not after

## Prototype pollution

```javascript
// VULNERABLE: deep merge with user input
Object.assign(target, userInput);
_.merge(target, userInput);
// Payload: {"__proto__": {"isAdmin": true}}

// SAFE: validate keys, use Map, freeze prototypes
const DANGEROUS_KEYS = ['__proto__', 'constructor', 'prototype'];
function safeMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (DANGEROUS_KEYS.includes(key)) continue;
    target[key] = source[key];
  }
}
```

Also flag: `lodash.merge`, `lodash.set`, `lodash.defaultsDeep` with user input,
`JSON.parse()` result used directly in `Object.assign()`. Use `Map` instead of
plain objects for user-keyed data. `Object.freeze()` on configuration objects.

## ReDoS (Regular Expression Denial of Service)

```javascript
// VULNERABLE: catastrophic backtracking
const emailRegex = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z]{2,4})+$/;
// Attack input: "a".repeat(50) + "!"

// SAFE: use re2 library, set timeouts, or use simple patterns
```

Flag: nested quantifiers (`(a+)+`), overlapping alternations with repetition,
user-supplied regex patterns. Use the `re2` library for untrusted patterns.

## XSS prevention

- React/Vue/Svelte auto-escape by default - do not bypass with
  `dangerouslySetInnerHTML`, `v-html`, or `{@html}` on user content
- If raw HTML is needed, sanitize with `DOMPurify` or `sanitize-html`
- Set `Content-Security-Policy` headers to restrict inline scripts
- `httpOnly` and `secure` flags on all auth cookies
- `Angular.bypassSecurityTrust*()` methods require careful review

## SSRF (Server-Side Request Forgery)

```javascript
// VULNERABLE
const resp = await fetch(userProvidedUrl);
// Can access: internal services, cloud metadata (169.254.169.254),
// file:// protocol, internal DNS names
```

Validate URL scheme (http/https only). Resolve DNS and check against private
IP ranges AFTER resolution (prevents DNS rebinding):
- Block: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.169.254, [::1]
- Block: `file://`, `gopher://`, `dict://` schemes

## Authentication

- `crypto.timingSafeEqual()` for token comparison, not `===`
- `crypto.randomBytes()` or `crypto.randomUUID()` for token generation
- `bcrypt` or `argon2` for password hashing, not raw crypto.createHash
- JWT: validate `alg` field (reject `none`), check `exp`, verify with correct key
- Store refresh tokens server-side, not in localStorage (XSS-accessible)
- Implement token rotation: invalidate old refresh token when issuing new

## SQL / GQL injection

- Use parameterized queries:
  ```javascript
  // pg
  client.query('SELECT * FROM users WHERE id = $1', [userId])
  // prisma
  prisma.$queryRaw`SELECT * FROM users WHERE id = ${userId}`
  ```
- Never use template literals or string concatenation to build queries
- ORMs are safe through their query API; raw queries still need parameterization

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

- `process.env` or secret managers, never hardcoded
- `.env` files in `.gitignore`, never committed
- Logging: mask sensitive fields in structured loggers (pino `redact` option)
- No secrets in client-side bundles - use server-side env only
- No secrets in `next.config.js` `publicRuntimeConfig`

## Supply chain

- `npm audit` or `pnpm audit` regularly
- Lock file (`package-lock.json`, `pnpm-lock.yaml`) committed to repo
- Set `ignore-scripts=true` in `.npmrc` by default, allowlist trusted packages
- Review new dependencies for `preinstall`/`postinstall` scripts containing
  `eval`, `Function`, `base64`, `curl`, `wget`, or HTTP URLs
- Flag packages published less than 7 days ago or with fewer than 100
  weekly downloads
- Check for `hasInstallScript` in lockfile entries from new dependencies

## Dependency safety signals

- Typosquatting: check package names for single-character substitutions
  of popular packages (`lodash` vs `loadash`, `express` vs `expres`)
- Registry URL changes in lockfile without corresponding manifest changes
- Integrity hash changes without version bumps
