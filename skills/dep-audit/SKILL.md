---
name: dep-audit
description: >
  Audit dependencies before adoption. Checks health metrics, license
  compatibility, supply chain signals, and evaluates build vs depend.
  Use when recommending or adding a new library or package.
---

## Purpose

Prevent adopting unmaintained, compromised, or unnecessary dependencies. Every
external dependency is a liability: it introduces maintenance burden,
potential vulnerabilities, license obligations, and supply chain risk.
Evaluate whether to depend at all, then verify the specific package is
healthy and safe before recommending it.

## Instructions

### 1. Build vs depend

Before evaluating any specific package, answer this question:

**Does this belong in-house or as a dependency?**

**Build in-house** when:
- The code sits on the critical path of the product's core value proposition
- You need full control over integration, memory layout, serialization, and
  future evolution
- The implementation is straightforward (could you build it in an afternoon?)
- The candidate dependency pulls in a large transitive tree for a small feature

**Depend externally** when:
- The problem is complex and well-solved (cryptography, compression, HTTP,
  serialization formats, parser generators)
- The library is a de facto ecosystem standard with corporate backing
- Building it yourself would take weeks and produce an inferior result
- The dependency has few transitive dependencies itself

**Quantitative check:** Run `cargo tree -p <crate>` / `npm ls <pkg>` /
`pipdeptree -p <pkg>` before adopting. If a dependency pulls in >20
transitive packages for a simple feature, reconsider.

If in-house is the right call, state that and stop. Do not audit packages.

### 2. Health audit

For each candidate package, evaluate these dimensions. See
[ecosystem-audit.md](ecosystem-audit.md) for ecosystem-specific tools,
thresholds, and commands.

#### Adoption and maintenance

- **Recent downloads:** growing or stable, not declining
- **Last release:** within 12 months (18 months is caution, >24 is reject)
- **Maintainer count:** 2+ active maintainers (bus factor > 1)
- **Issue triage:** are issues being responded to? Are PRs reviewed?
- **OpenSSF Scorecard:** aim for 6+ overall (below 4 is a red flag)

#### Vulnerability status

- No known unpatched CVEs in the package or its transitive tree
- Run the ecosystem's audit tool: `cargo-audit`, `npm audit`, `pip-audit`
- Check vulnerability response history: how quickly does the maintainer
  address reported issues?

#### Transitive dependency risk

- Count transitive dependencies (fewer is better)
- Check for single-maintainer transitives (high abandonment risk)
- Verify no duplicate versions of the same transitive (version conflicts)
- Aim for dependency depth of 4 or fewer levels

### 3. License check

Verify license compatibility with your project. See
[license-compatibility.md](license-compatibility.md) for the full matrix.

Key risks:
- **GPL in a non-GPL project:** combined work becomes GPL
- **AGPL in SaaS:** requires source disclosure to all network users
- **No license:** legally unusable, treat as all-rights-reserved

Run: `cargo deny check licenses` / `npx license-checker` / `pip-licenses`

### 4. Supply chain signals

Check for red flags that indicate a compromised or risky package:

- **Sudden release burst** after long dormancy (months/years inactive, then
  rapid releases)
- **New maintainer** added shortly before a suspicious release
- **Install scripts** with network calls, encoded strings, or code execution
  (`preinstall`/`postinstall` in npm)
- **Package name** is a near-miss of a popular package (typosquatting)
- **Package age** less than 30 days with no established community
- **Binary artifacts** bundled without explanation
- **Lockfile manipulation:** integrity hash changes without version bumps,
  registry URL changes

### 5. Report findings

Present a clear recommendation for each candidate:

```
Package: sketches-ddsketch v0.3
Downloads: 54M (90-day), trending stable
Last release: 2025-11-14 (5 months ago)
Maintainers: 3 active
License: Apache-2.0 (compatible)
Transitive deps: 2
Vulnerabilities: none known
OpenSSF Scorecard: 7.2
Recommendation: ADOPT
```

Or:

```
Package: tsz-compress v0.2
Downloads: 1.2K (90-day), declining
Last release: 2023-08-01 (2.5 years ago)
Maintainers: 1 (inactive)
License: MIT (compatible)
Transitive deps: 0
Vulnerabilities: none known
OpenSSF Scorecard: 2.1
Recommendation: REJECT - unmaintained, low adoption
Alternative: hand-roll Gorilla encoding (~200 lines)
```

When auditing multiple candidates, present them side by side:

```
| Metric | Option A | Option B | Option C |
|--------|----------|----------|----------|
| Downloads (90d) | 54M | 12K | 890K |
| Last release | 5 months | 2.5 years | 3 months |
| Maintainers | 3 | 1 | 2 |
| License | Apache-2.0 | MIT | GPL-3.0 |
| Transitive deps | 2 | 0 | 14 |
| Recommendation | ADOPT | REJECT | CAUTION (GPL) |
```

If rejecting, always suggest an alternative (another package or hand-rolling).

### 6. User selection

When auditing multiple candidates, present the comparison matrix from
Step 5, then walk through each recommendation:

1. For each candidate, present:
   - The health audit summary (from Step 5 format)
   - Your recommendation: ADOPT, CAUTION, or REJECT with rationale
   - If CAUTION: what specific risk the user accepts by adopting
2. After presenting the comparison, ask:
   > "Based on the audit, I recommend [package]. Adopt it, or would you
   > prefer to evaluate alternatives?"
3. Wait for the user's decision before proceeding to integration.

If only one candidate is being audited (not a comparison), present the
report and ask: "Adopt, reject, or investigate alternatives?"

## Supporting files

- [ecosystem-audit.md](ecosystem-audit.md) - tools, thresholds, and commands per ecosystem
- [license-compatibility.md](license-compatibility.md) - license contamination matrix and rules

## Guidance

**Total downloads are misleading.** A package with 10M all-time downloads but
200 recent downloads is likely abandoned. Always check recent trends.

**Transitive dependencies are invisible risk.** 70% of critical security debt
originates from third-party code. Run the dependency tree before adopting.

**Corporate backing matters for longevity.** Corporate-backed libraries have
3x the survival rate over 5 years. Weight maintainer stability heavily for
dependencies you will use long-term.

**The 80% rule:** 80% of software's total cost occurs after initial adoption.
A dependency that saves a week of development but requires ongoing
vulnerability monitoring, version conflict resolution, and update churn may
cost more than building it yourself.
