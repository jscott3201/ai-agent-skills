---
name: dep-audit
description: >
  Audit dependencies before adoption. Checks health metrics and evaluates
  build vs depend. Use when recommending or adding a new library or package.
---

## Purpose

Prevent adopting unmaintained, abandoned, or unnecessary dependencies. Every
external dependency is a liability - evaluate whether to depend at all, then
verify the specific package is healthy before recommending it.

## Instructions

### 1. Build vs depend

Before evaluating any specific package, answer this question:

**Does this belong in-house or as a dependency?**

- **Build in-house** if the data structure or algorithm sits on the critical
  path of the product's core value proposition. Full control over integration,
  memory layout, serialization, and future evolution outweighs the cost of
  implementation.

- **Depend externally** if it is infrastructure or utility code: serialization
  formats, compression, cryptography, HTTP frameworks, test harnesses. These
  are well-solved problems where external packages provide better quality than
  hand-rolling.

The decision boundary: does this code define what makes the product unique,
or does it support the product's unique code?

If in-house is the right call, state that and stop. Do not audit packages.

### 2. Audit the package

For each candidate package, check:

#### Health metrics

**Rust (crates.io):**
- Recent 90-day downloads: must be >10K
- Last release date: must be within ~12 months
- Check `cargo deny` compatibility if the project uses it

**JavaScript (npm):**
- Weekly downloads: check for active usage
- Last publish date: must be within ~12 months
- Check for known vulnerabilities via `npm audit`

**Python (PyPI):**
- Recent download stats via pypistats.org or similar
- Last release date: must be within ~12 months
- Check for active maintenance

#### Repository activity

For any ecosystem:
- Open issues: reasonable count, some recent triage activity
- Recent commits: at least some activity in the last 6 months
- Maintainer responsiveness: are issues and PRs being addressed?

### 3. Report findings

Present a clear recommendation:

```
Package: sketches-ddsketch v0.3
90-day downloads: 54M
Last release: 2025-11-14 (5 months ago)
GitHub: active, 12 open issues, last commit 3 weeks ago
Recommendation: ADOPT - healthy, widely used, well-maintained
```

Or:

```
Package: tsz-compress v0.2
90-day downloads: 1.2K
Last release: 2023-08-01 (2.5 years ago)
GitHub: 4 open issues, no commits in 18 months
Recommendation: REJECT - low adoption, unmaintained
Alternative: hand-roll Gorilla encoding (~200 lines)
```

If rejecting, always suggest an alternative (another package or hand-rolling).

## Guidance

Total download count is misleading - a package with 10M total downloads but
200 recent downloads is likely abandoned. Always check recent activity.

When auditing multiple candidates for the same need, present them side by side
so the tradeoffs are visible. Do not just recommend the first one found.

For Rust specifically: check if the crate uses `#![forbid(unsafe_code)]` or
has significant unsafe blocks. Unsafe in a dependency is risk you inherit.
