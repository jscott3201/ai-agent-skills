---
name: env-audit
description: >
  Audit environment variable usage against configuration files. Finds vars
  referenced in code but missing from config, unused config vars, and
  plaintext secrets. Use before deployment or after config changes.
disable-model-invocation: true
argument-hint: "[scope or environment name]"
---

## Purpose

Prevent configuration-related failures by verifying that environment
variables referenced in code are defined in configuration, and that
configuration files do not contain stale or unused entries. Configuration
errors are a top cause of production incidents and are easy to prevent
with a pre-deployment audit.

This is an interactive skill. Present each mismatch one at a time with
options to fix, accept, or flag for review.

## Instructions

### 1. Scan code for environment variable references

Search the codebase for env var access patterns per language:

**Rust:**
```
std::env::var("VAR_NAME")
std::env::var_os("VAR_NAME")
env!("VAR_NAME")
option_env!("VAR_NAME")
```

**Python:**
```
os.environ["VAR_NAME"]
os.environ.get("VAR_NAME")
os.getenv("VAR_NAME")
```

**JavaScript/TypeScript:**
```
process.env.VAR_NAME
process.env["VAR_NAME"]
import.meta.env.VITE_VAR_NAME
```

Also check for config libraries that wrap env access:
- `dotenv`, `python-dotenv`, `dotenvy`
- `config` crate, `pydantic-settings`, `@nestjs/config`
- Framework-specific patterns (Next.js `NEXT_PUBLIC_*`, Vite `VITE_*`)

Record each variable with its source location (file:line).

### 2. Scan configuration sources

Check these locations for defined variables:

| Source | Files |
|:--|:--|
| **Env files** | `.env`, `.env.example`, `.env.local`, `.env.production`, `.env.test` |
| **Docker** | `Dockerfile` (ENV directives), `docker-compose.yml` (environment section) |
| **CI/CD** | `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile` |
| **Kubernetes** | `k8s/*.yml`, `**/configmap*.yml`, `**/secret*.yml` |
| **Infra** | `terraform/*.tf` (variable blocks), `pulumi/*`, `cdk/*` |
| **App config** | `config/*.toml`, `settings.py`, framework config files |

If `$ARGUMENTS` specifies a scope (e.g., "production" or "docker"), focus
on that subset. Otherwise scan all discovered sources.

Record each variable with its source file and whether it has a value,
a placeholder, or just a key.

### 3. Cross-reference and identify mismatches

Build the comparison matrix:

| Category | Meaning | Severity |
|:--|:--|:--|
| **In code, missing from config** | App will fail at runtime | High |
| **In code, in `.env.example` only** | Template exists but no actual value | Medium |
| **In config, not referenced in code** | Stale config entry | Low |
| **Required (no default) vs optional (has fallback)** | Distinguishes hard failures from soft | Context |

For each variable referenced in code, determine:
- Is a default/fallback provided? (reduces severity of missing config)
- Is it accessed at startup or lazily? (startup = immediate crash)
- Is it in all environments or just some?

### 4. Check for secrets exposure

Flag variables that appear to contain secrets based on naming patterns:

- Names containing: `SECRET`, `KEY`, `TOKEN`, `PASSWORD`, `CREDENTIAL`,
  `API_KEY`, `AUTH`, `PRIVATE`
- Variables with actual values in committed files (not `.gitignore`d)
- Variables in `.env.example` with real-looking values instead of
  placeholders

This complements the `safety-checks` skill's secrets scanning but focuses
specifically on environment configuration.

### 5. Present findings one at a time

Start with high severity (variables in code but missing from config):

> **Missing from config:** `DATABASE_URL`
> **Referenced in:** `src/db/connection.rs:15` (no default, accessed at startup)
> **Config sources checked:** `.env`, `.env.example`, `docker-compose.yml`
>
> This will cause a startup failure in any environment where the var
> is not set externally.
>
> Options:
> 1. **Add to config** - add to `.env.example` with a placeholder
> 2. **Accept** - var is provided externally (document where)
> 3. **Add default** - add a fallback value in code
>
> I recommend adding to `.env.example` with a placeholder so the
> requirement is discoverable.

Wait for the user's decision before presenting the next finding.

After high severity, ask before continuing:

> "N high-severity gaps addressed. Move to medium severity (template-only
> vars), or stop here?"

### 6. Produce audit report

Save to `_agentskills/reviews/YYYY-MM-DD-env-audit.md`:

```markdown
# Environment Audit: [Project Name]

**Date:** YYYY-MM-DD
**Scope:** [all environments / specific environment]

## Summary

- Variables in code: N
- Variables in config: N
- Missing from config: N (N addressed, N accepted)
- Stale config entries: N
- Secret exposure flags: N

## Missing from Config (High)

| Variable | Referenced In | Default | Action Taken |
|----------|-------------|---------|-------------|
| `DB_URL` | src/db.rs:15 | None | Added to .env.example |

## Template Only (Medium)

| Variable | .env.example | Actual Config |
|----------|-------------|--------------|
| `REDIS_URL` | placeholder | Not in .env |

## Stale Config (Low)

| Variable | Config Source | Not Referenced In Code |
|----------|-------------|----------------------|
| `OLD_API_KEY` | .env | Removed |

## Secrets Review

| Variable | Issue | Action |
|----------|-------|--------|
| `API_KEY` | Real value in .env.example | Replaced with placeholder |
```

## Guidance

**Run before deployment, not after incidents.** The cheapest time to
catch a missing env var is before the deploy, not during a 2am page.

**`.env.example` is documentation.** It should list every variable the
app needs with a placeholder value and a comment explaining its purpose.
Missing entries in `.env.example` are the #1 cause of "works on my
machine" failures.

**Distinguish required from optional.** A variable with a sensible
default (like `LOG_LEVEL=info`) is low risk. A variable with no default
that is accessed at startup (like `DATABASE_URL`) is a hard failure
waiting to happen.

**Framework prefixes matter.** Next.js only exposes `NEXT_PUBLIC_*` to
the browser. Vite only exposes `VITE_*`. A variable without the prefix
is server-only, which may be intentional or a bug.
