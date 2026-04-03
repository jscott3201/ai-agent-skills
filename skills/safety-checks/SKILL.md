---
name: safety-checks
description: >
  Security, auth, and memory safety for code handling external input.
  Use when writing parsers, handlers, auth, or APIs. Invoke manually
  for a full codebase safety audit.
argument-hint: "[audit scope]"
---

## Purpose

Enforce security, authentication, and memory safety when writing code that
handles external input, manages authentication, or allocates resources based
on user data. Auto-triggers as background knowledge during development. When
invoked manually, performs a full codebase safety audit.

## Principles

These are non-negotiable. Apply them before consulting the checklist.

1. **Never trust external input.** All data crossing a trust boundary is
   hostile until validated. This includes HTTP bodies, query parameters,
   WebSocket messages, deserialized payloads, and file uploads.

2. **Auth is not optional.** Every endpoint that serves or mutates data
   must verify identity and authorization. Anonymous access is an explicit
   design choice, never a default.

3. **All allocations must be bounded.** No unbounded Vec, String, HashMap,
   or equivalent grown from user-controlled input. Set hard limits and
   reject input that exceeds them.

4. **Secrets never appear in logs, source, or error messages.** Credentials,
   tokens, API keys, and private keys are redacted in debug output, never
   hardcoded, and zeroized when no longer needed.

5. **Fail closed.** When validation, auth, or a safety check fails, deny
   the request. Do not fall through to a permissive default.

## Checklist

When writing code that handles external input, verify each relevant category.

### Resource bounds

- [ ] Parser nesting/recursion depth is capped (typical: 32-128)
- [ ] Request body size is limited (typical: 1-10MB)
- [ ] String length from external input is capped
- [ ] Collection sizes from deserialization are capped (typical: 10K-1M items)
- [ ] Concurrent connections/subscriptions have a hard limit
- [ ] Timeouts are set on all external calls and long-running operations
- [ ] Query result sets are paginated or capped

### Input validation and sanitization

- [ ] No string interpolation of user input into queries (SQL, GQL, shell)
- [ ] Use parameterized queries or prepared statements
- [ ] HTML output is escaped to prevent XSS
- [ ] File paths from user input are canonicalized and checked against allowed roots
- [ ] Regex from user input is rejected or sandboxed (ReDoS risk)
- [ ] Numeric inputs are range-checked before use

### Authentication and authorization

- [ ] Every endpoint has explicit auth (no accidental anonymous access)
- [ ] Auth tokens have expiry and are rotated
- [ ] Password storage uses a strong KDF (bcrypt, scrypt, Argon2, PBKDF2 with high iterations)
- [ ] Timing-safe comparison for token/password verification
- [ ] Rate limiting on auth endpoints (login, token refresh)
- [ ] CORS configured to allow only expected origins
- [ ] CSRF protection on state-changing requests

### Secret handling

- [ ] No credentials hardcoded in source (use env vars or secret managers)
- [ ] Debug/Display impls redact sensitive fields
- [ ] Sensitive data zeroized after use (not just dropped)
- [ ] Secrets not logged at any log level
- [ ] Error messages do not leak internal state or stack traces to clients

### Memory safety

- [ ] No unbounded allocation from user-controlled input
- [ ] Slice/array indices validated before access
- [ ] Deserialization of untrusted data has size and depth limits
- [ ] No bare unwrap/expect on data from external sources (use proper error handling)
- [ ] Integer overflow checked on arithmetic with external values

## Manual audit mode

When invoked manually (e.g., `/justin-tools:safety-checks` or with a scope
argument), perform a full audit:

1. If `$ARGUMENTS` specifies a scope, focus on that area. Otherwise, scan
   the full codebase.
2. Check every endpoint, parser, and handler against the checklist above.
3. Report findings grouped by category with severity (Critical/High/Medium/Low).
4. For each finding, include the file, line, and a specific fix recommendation.

## Language-specific guidance

- For Python-specific patterns, see [python-safety.md](python-safety.md)
- For Rust-specific patterns, see [rust-safety.md](rust-safety.md)
- For JavaScript-specific patterns, see [javascript-safety.md](javascript-safety.md)

Load the relevant file when working in that language.
