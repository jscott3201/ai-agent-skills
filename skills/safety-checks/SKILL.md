---
name: safety-checks
description: >
  Security auditing with graph-persisted concerns. STRIDE-based threat
  analysis writing SecurityConcern nodes linked to dependencies, crates,
  and modules. Enables supply chain and security posture queries.
argument-hint: "[audit scope]"
---

## Purpose

Security auditing with graph persistence. Every finding becomes a
`:SecurityConcern` node linked to affected dependencies, crates, and modules.
Auto-triggers as background knowledge during development. When invoked
manually, performs a full codebase audit using STRIDE-based threat analysis
with all findings persisted to the graph for cross-session tracking.

**When NOT to use:** Pure internal logic with no external input. Style or
readability concerns (use `code-standards`). Performance investigation
(use `perf-profile`).

## Principles

Non-negotiable. Apply before consulting the checklist.

1. **Never trust external input.** All data crossing a trust boundary is
   hostile until validated: HTTP bodies, query parameters, WebSocket messages,
   deserialized payloads, file uploads, and DNS responses.

2. **Auth is not optional.** Every endpoint that serves or mutates data must
   verify identity and authorization. Anonymous access is an explicit design
   choice, never a default.

3. **All allocations must be bounded.** No unbounded Vec, String, HashMap, or
   equivalent grown from user-controlled input. Set hard limits and reject
   input that exceeds them.

4. **Secrets never appear in logs, source, or error messages.** Credentials,
   tokens, API keys, and private keys are redacted in debug output, never
   hardcoded, and zeroized when no longer needed.

5. **Fail closed.** When validation, auth, or a safety check fails, deny the
   request. Do not fall through to a permissive default.

6. **Defense in depth.** No single layer is the only defense. Validate at the
   boundary, re-validate at the data layer, and enforce at the auth layer.

## Checklist

When writing code that handles external input, verify each relevant category.

### Resource bounds

- [ ] Parser nesting/recursion depth is capped (typical: 32-128)
- [ ] Request body size is limited (typical: 1-10MB)
- [ ] String length from external input is capped
- [ ] Collection sizes from deserialization are capped (typical: 10K-1M items)
- [ ] Concurrent connections/subscriptions have a hard limit
- [ ] Timeouts on all external calls and long-running operations
- [ ] Query result sets are paginated or capped
- [ ] File upload size, type, and content validated

### Input validation and sanitization

- [ ] No string interpolation of user input into queries (SQL, GQL, Cypher, shell)
- [ ] Use parameterized queries or prepared statements
- [ ] Non-parameterizable query elements (labels, property names) validated
      against allowlists
- [ ] HTML output escaped to prevent XSS
- [ ] File paths from user input canonicalized and checked against allowed roots
- [ ] Regex from user input rejected or sandboxed (ReDoS risk)
- [ ] Numeric inputs range-checked before use
- [ ] URL inputs validated for scheme (http/https only) and destination
      (block private IP ranges for SSRF prevention)

### Authentication and authorization

- [ ] Every endpoint has explicit auth (no accidental anonymous access)
- [ ] Object-level authorization on every data access (BOLA/IDOR prevention)
- [ ] No mass assignment - request bodies filtered to allowed fields
- [ ] Auth tokens have expiry, are rotated, and use cryptographic randomness
- [ ] Password storage uses a strong KDF (Argon2id preferred, bcrypt, scrypt)
- [ ] Timing-safe comparison for token/password verification
- [ ] Rate limiting on auth endpoints (login, token refresh, registration)
- [ ] CORS configured to allow only expected origins (no wildcard with credentials,
      no origin reflection, anchored regex patterns)
- [ ] CSRF protection on state-changing requests
- [ ] OAuth flows use PKCE (required by OAuth 2.1 for all clients)
- [ ] JWT: `alg` validated (reject `none`), `exp`/`iss`/`aud` checked

### Secret handling

- [ ] No credentials hardcoded in source - see [secrets-patterns.md](secrets-patterns.md)
      for detection patterns
- [ ] Debug/Display impls redact sensitive fields
- [ ] Sensitive data zeroized after use (not just dropped/garbage collected)
- [ ] Secrets not logged at any log level
- [ ] Error messages do not leak internal state or stack traces to clients
- [ ] `.env` files in `.gitignore`, never committed
- [ ] No secrets in Dockerfile ENV/ARG instructions or build layers

### Cryptography

- [ ] No deprecated algorithms - see [crypto-guidelines.md](crypto-guidelines.md)
- [ ] No hardcoded IVs, nonces, or encryption keys
- [ ] Nonces/IVs are never reused (especially critical for GCM mode)
- [ ] AEAD mode for symmetric encryption (AES-256-GCM or ChaCha20-Poly1305)
- [ ] Constant-time comparison for MAC/token verification
- [ ] RSA keys at least 2048 bits (prefer 4096 or ECC P-256/P-384)

### Supply chain

- [ ] All dependencies pinned with integrity hashes in lockfiles
- [ ] No lifecycle scripts from untrusted packages (`preinstall`, `postinstall`)
- [ ] Security audit clean (`cargo-audit`, `npm audit`, `pip-audit`)
- [ ] No `[patch]`/`[replace]` in Cargo.toml overriding published crates
- [ ] No `--extra-index-url` pointing to non-standard registries
- [ ] New dependencies reviewed for adoption health (see `dep-audit` skill)

### Memory safety

- [ ] No unbounded allocation from user-controlled input
- [ ] Slice/array indices validated before access
- [ ] Deserialization of untrusted data has size and depth limits
- [ ] No bare unwrap/expect on data from external sources
- [ ] Integer overflow checked on arithmetic with external values
      (Rust: `checked_add`/`saturating_add`, not default operators in release)
- [ ] No unsafe deserialization of untrusted data (use JSON or protobuf,
      not language-native serialization formats)

### Container and infrastructure

- [ ] Containers run as non-root user
- [ ] Base images pinned by digest, not `latest` tag
- [ ] Multi-stage builds to minimize attack surface
- [ ] No secrets in environment variables or build args
- [ ] Only necessary ports exposed
- [ ] `.dockerignore` excludes `.env`, `.git`, credentials, `node_modules`

### Error handling

- [ ] No stack traces or internal details in user-facing errors
- [ ] Fail-closed on exceptions (deny access by default)
- [ ] All error paths handled (no bare `except: pass`, no `.unwrap()` on
      external data)
- [ ] Security-relevant actions logged (auth failures, access denials,
      input validation failures)

## Graph Integration

### 0. Context recall

Query prior security concerns for this project before starting:

```gql
MATCH (sc:SecurityConcern)
WHERE sc.project = $project AND sc.status = 'open'
OPTIONAL MATCH (sc)-[:affects]->(target)
RETURN sc.summary, sc.severity, sc.category, sc.cve,
  labels(target) AS affected_type, target.name AS affected_name
ORDER BY sc.severity
```

Present open concerns to the user: "N open security concerns from prior
audits. [Summarize top items]." This establishes baseline before new analysis.

Also query dependencies flagged as security-relevant:

```gql
MATCH (d:dependency {security_relevant: true})
RETURN d.name, d.version
```

### Session creation

Create a session at audit start per [selene-integration.md](../_selene/selene-integration.md).

### Graph write: security concern

After each finding is triaged (fix now, defer, accept, false positive),
write a SecurityConcern node:

```gql
INSERT (sc:SecurityConcern {
  project: $project,
  summary: $summary,
  severity: $severity,
  status: $triage_status,
  category: $stride_category,
  found_date: date(),
  cve: $cve,
  audit_session: $session_id
})
RETURN id(sc) AS concern_id
```

Link to session, affected code, and affected dependencies per patterns
in [selene-patterns.md](../_selene/selene-patterns.md).

### Graph write: mitigation

When a fix is applied and committed:

```gql
MATCH (sc:SecurityConcern) WHERE id(sc) = $concern_id
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET c.project = $project, c.short_sha = $short_sha,
  c.message = $commit_message, c.author = $author, c.date = date(),
  c.branch = $branch
INSERT (sc)-[:mitigated_by]->(c)
SET sc.status = 'mitigated'
```

## Manual audit mode

When invoked manually, determine scope first:

**For full codebase audit:** delegate to the `security-auditor` agent
using the Agent tool. This keeps heavy scanning out of the main context.
The agent has the safety-checks methodology preloaded and uses read-only
tools.

**For focused audit** (specific module, endpoint, or trust boundary):
perform the analysis directly in the main conversation. Present findings
one at a time per the triage pattern below.

### Setup

1. If `$ARGUMENTS` specifies a scope, use it to focus the audit.
   For delegated audits, include the scope in the delegation prompt.
2. The auditor identifies all trust boundaries (external input entry points,
   auth boundaries, service-to-service calls, data persistence layers).

### STRIDE analysis

For each trust boundary, evaluate:

| Threat | Question |
|--------|----------|
| **Spoofing** | Can users impersonate others? Are tokens validated on every request? |
| **Tampering** | Can request data be modified? Are inputs validated server-side? |
| **Repudiation** | Are security-relevant actions logged? Are logs tamper-proof? |
| **Information Disclosure** | Do errors leak internals? Are secrets in code/logs? Data encrypted at rest/transit? |
| **Denial of Service** | Unbounded queries? Missing rate limits? Algorithmic complexity attacks? |
| **Elevation of Privilege** | Can users access admin functions? Is authorization checked at every layer? |

### Report

3. Run every item in the checklist above against the codebase.
4. Report findings grouped by STRIDE category with severity:
   - **Critical** - active exploitability, data exposure, auth bypass
   - **High** - exploitable with effort, missing auth on endpoints
   - **Medium** - defense-in-depth gaps, missing rate limits
   - **Low** - hardening opportunities, best practice deviations
5. For each finding, include: file, line, STRIDE category, and specific fix.
6. Summarize: total findings by severity, top 3 priorities, and recommended
   fix order.

### 7. Triage findings with user

After the security-auditor returns findings, present critical and high
findings to the user **one at a time** before applying any fixes:

1. For each Critical finding, present:
   - The finding (file, line, STRIDE category, specific vulnerability)
   - Your recommended fix
   - Ask: **fix now**, **defer** (with risk acknowledgment), or **skip**
2. Wait for the user's decision before presenting the next finding
3. After all Critical findings, ask: "Move to High findings, or stop here?"
4. Repeat for High severity. Medium and Low findings can be summarized
   as a group with the user choosing to review individually or batch-fix.

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Internal-only code doesn't need input validation" | Internal today, exposed tomorrow. Trust boundaries shift. Validate at every boundary. |
| "Middleware handles auth, endpoints don't need checks" | Middleware can be bypassed, misconfigured, or skipped in new routes. Defense in depth means checking at every layer. |
| "It's a prototype, security hardening comes later" | Prototypes ship. Security bolted on later is security never done right. |
| "Standard library handles crypto, skip crypto review" | The standard library provides primitives. Using them wrong (ECB mode, weak KDF, hardcoded IV) is the actual risk. |
| "Well-known packages can't be compromised" | event-stream, ua-parser-js, colors.js were all well-known. Popularity is not security. |

## Red Flags

Stop and reassess if you observe:
- Skipping checklist categories because "the code looks safe"
- No STRIDE analysis performed for endpoints handling external input
- Treating popularity as proof of security for dependencies
- Reporting zero findings (even well-written code has hardening opportunities)

## Verification

- [ ] Every checklist item checked against the codebase (not sampled)
- [ ] STRIDE analysis completed for each trust boundary
- [ ] Findings grouped by STRIDE category with severity assigned
- [ ] Critical and High findings triaged one at a time with user
- [ ] Approved fixes applied and verified

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) — SeleneDB detection, sessions, auto-recall
- [selene-patterns.md](../_selene/selene-patterns.md) — SecurityConcern write/read patterns

Language-specific (load ONLY the one matching the project language):
- [python-safety.md](python-safety.md) - Python-specific vulnerability patterns
- [rust-safety.md](rust-safety.md) - Rust-specific vulnerability patterns
- [javascript-safety.md](javascript-safety.md) - JavaScript/TypeScript vulnerability patterns

Scope-conditional (load only when the audit covers the relevant domain):
- [secrets-patterns.md](secrets-patterns.md) - Regex patterns for detecting
  hardcoded secrets. Load when checking secret handling or running a full audit.
- [crypto-guidelines.md](crypto-guidelines.md) - Approved and deprecated
  cryptographic algorithms. Load when the codebase uses cryptographic
  operations or running a full audit.

Never load all five files at once. For a typical single-language audit,
load one language file plus only the domain files relevant to the scope.
