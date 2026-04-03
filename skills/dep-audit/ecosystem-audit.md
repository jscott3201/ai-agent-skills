# Ecosystem-Specific Audit Guide

Tools, thresholds, and commands for auditing dependencies in each ecosystem.

## Rust (crates.io)

### Health thresholds

| Signal | Healthy | Caution | Reject |
|--------|---------|---------|--------|
| All-time downloads | >100K | 1K-100K | <1K |
| Recent downloads | Trending up/stable | Flat | Declining |
| Last release | Within 12 months | 12-24 months | >24 months |
| Maintainers | 2+, active | 1, active | 0 or archived |
| `unsafe` usage | Minimal, documented | Present, justified | Extensive, undocumented |
| RustSec advisories | None | Informational | Active vulnerability |

### Audit commands

```bash
# Vulnerability scan against RustSec advisory DB
cargo audit

# License, ban, advisory, and source policy enforcement
cargo deny check

# Unsafe code inventory across dependency tree
cargo geiger

# Detect abandoned/unmaintained dependencies
cargo unmaintained

# View full dependency tree
cargo tree

# Check for duplicate crate versions
cargo tree -d

# View feature flags enabled on dependencies
cargo tree -e features

# Check a specific crate's tree before adopting
cargo tree -p <crate-name>
```

### cargo-deny configuration

`deny.toml` key sections:

```toml
[advisories]
db-path = "~/.cargo/advisory-db"
vulnerability = "deny"
unmaintained = "warn"
unsound = "warn"

[licenses]
allow = ["MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "Zlib"]
confidence-threshold = 0.8

[bans]
multiple-versions = "warn"
wildcards = "deny"

[sources]
unknown-registry = "deny"
unknown-git = "deny"
```

### Unsafe code

- `cargo geiger` symbols: `:)` = `#![forbid(unsafe_code)]`, `?` = missing
  declaration, `!` = unsafe present
- 85% of unsafe/system effects are concentrated in ~3% of crates
- Flag any dependency with extensive undocumented unsafe

## JavaScript (npm)

### Health thresholds

| Signal | Healthy | Caution | Reject |
|--------|---------|---------|--------|
| Weekly downloads | >10K | 1K-10K | <1K |
| Snyk Advisor score | >70 | 50-70 | <50 |
| Maintainers | 2+ with 2FA | 1 active | 0 active |
| Last publish | Within 12 months | 12-18 months | >18 months |
| Direct dependencies | <10 | 10-20 | >20 |
| Install scripts | None | Documented | Obfuscated |
| Package age | >6 months | 1-6 months | <1 month |

### Audit commands

```bash
# Vulnerability audit
npm audit

# View dependency tree
npm ls

# View dependency tree with depth limit
npm ls --depth=3

# Check package metadata before installing
npm view <package> maintainers
npm view <package> dependencies
npm view <package> scripts

# Lockfile integrity check
npx lockfile-lint --path package-lock.json --type npm --allowed-hosts npm
```

### Install script safety

Check `package.json` for lifecycle scripts:

```bash
npm view <package> scripts
```

Red flags in scripts: `eval`, `Function`, `base64`, `curl`, `wget`,
HTTP URLs, encoded strings.

Defense: set `ignore-scripts=true` in `.npmrc`, allowlist trusted packages
with `@lavamoat/allow-scripts`.

### Dependency confusion defense

- Use scoped packages (`@yourorg/package-name`)
- Configure `.npmrc`: `@yourorg:registry=https://your-private-registry.example.com`
- Reserve internal package names on public registry

## Python (PyPI)

### Health thresholds

| Signal | Healthy | Caution | Reject |
|--------|---------|---------|--------|
| Monthly downloads | >10K | 1K-10K | <1K |
| Trusted publishing | Yes (OIDC) | No but active | Token-only, inactive |
| Attestations | Present | Not present | N/A |
| Last release | Within 12 months | 12-24 months | >24 months |
| PyPI metadata | Complete, links | Partial | Missing repo |

### Audit commands

```bash
# Vulnerability scan
pip-audit --requirement requirements.txt
pip-audit --format json --requirement requirements.txt > report.json

# Alternative vulnerability scan
safety check -r requirements.txt

# View dependency tree
pipdeptree
pipdeptree -p <package>

# License check
pip-licenses

# Generate requirements with hash pinning (tamper detection)
uv pip compile --generate-hashes requirements.in -o requirements.txt

# Exclude packages newer than N days (supply chain defense)
uv pip compile --exclude-newer 2026-03-26 requirements.in -o requirements.txt
```

### Typosquatting defense

- Always copy package names from official documentation, never type from memory
- Verify on pypi.org before installing
- Reserve your package names on PyPI
- Watch for near-miss names of popular packages (`reqeusts`, `djnago`)

### Dependency confusion defense

```toml
# pyproject.toml (uv)
[[tool.uv.index]]
name = "internal"
url = "https://internal.corp.com/pypi"
explicit = true

[tool.uv.sources]
mypackage = { index = "internal" }
```

For pip: use `--index-url` (single index) instead of `--extra-index-url`
to prevent fallback to PyPI for internal packages.

## Cross-Ecosystem Tools

| Tool | Purpose | Ecosystems |
|------|---------|------------|
| OpenSSF Scorecard | Automated 0-10 health scoring | Any (GitHub-hosted) |
| OWASP Dependency-Track | Continuous vulnerability monitoring | All |
| Snyk | Vulnerability scanning + monitoring | All |
| Renovate / Dependabot | Automated dependency updates | All |
| Endor Labs | Reachability analysis (does your code call the vuln?) | All |
