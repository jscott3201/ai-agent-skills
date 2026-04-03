# Competitive/Landscape Analysis Template

Use this format for Mode 3 (competitive/landscape analysis) research output.

```markdown
# [Domain] Landscape Analysis

**Date:** YYYY-MM-DD
**Question:** [What alternatives exist for X?]
**Status:** Complete

## Overview

[2-3 sentences: what problem space is being evaluated, how many
candidates were found, the key differentiators.]

## Candidate Profiles

### [Candidate A]

- **Repository/URL:** [link]
- **Language:** [implementation language]
- **License:** [SPDX identifier]
- **Stars/Downloads:** [adoption metric]
- **Last release:** [date]
- **Maintainers:** [count, active status]
- **Architecture:** [1-2 sentences on how it works]
- **Key strength:** [What it does best]
- **Key weakness:** [What it does worst or lacks]

### [Candidate B]

[Same format]

### [Candidate C]

[Same format]

## Feature Comparison

| Feature | Candidate A | Candidate B | Candidate C | Our Needs |
|---------|------------|------------|------------|-----------|
| [Feature 1] | [status/detail] | [status/detail] | [status/detail] | [Required/Nice-to-have/N/A] |
| [Feature 2] | [status/detail] | [status/detail] | [status/detail] | [Required/Nice-to-have/N/A] |
| [Feature 3] | [status/detail] | [status/detail] | [status/detail] | [Required/Nice-to-have/N/A] |

**Legend:** Full support, Partial, Not supported, Unknown

## Health Assessment

| Metric | Candidate A | Candidate B | Candidate C |
|--------|------------|------------|------------|
| Recent downloads | [number] | [number] | [number] |
| Last release | [date] | [date] | [date] |
| Open issues | [count] | [count] | [count] |
| Maintainers | [count] | [count] | [count] |
| License | [SPDX] | [SPDX] | [SPDX] |
| Transitive deps | [count] | [count] | [count] |

## Differentiation Analysis

[What makes each candidate unique? Where does the project's needs
align or misalign with each candidate's strengths?]

### Where [Our Project] differs

[Specific capabilities, constraints, or requirements that narrow
the field. "We need X which only Candidate A provides" or "Our edge
deployment constraint eliminates Candidates B and C."]

## Recommendation

[Clear recommendation with rationale. Reference the feature comparison
and health assessment above.]

**Recommended:** [Candidate] because [specific reasons tied to features
and health metrics].

**Runner-up:** [Candidate] because [when this would be the better choice].

## Not Recommended

- **[Rejected candidate]:** [Why - specific gap, health concern, or
  incompatibility. Be precise enough that future researchers don't
  re-evaluate without new information.]

## Build-vs-Depend Assessment

[For the recommended candidate: should we depend on it, or build the
needed functionality in-house? Apply the dep-audit decision framework.]

- Core to product differentiation? [Yes/No]
- Implementation complexity? [Lines of code estimate]
- Transitive dependency cost? [Count and risk]
- 5-year maintainer confidence? [Assessment]
- **Verdict:** [Depend / Build in-house / Hybrid]

## Sources

1. [Source](URL) - what it contributed
2. [Source](URL) - what it contributed
```

## Research thoroughness

- **Minimum 3 candidates** for a meaningful comparison. If fewer exist,
  note that the space is thin and evaluate build-vs-depend more heavily.
- **Check adoption trends** (growing, stable, declining), not just
  current numbers.
- **Verify claims from project READMEs** against actual code or issues.
  Projects often overstate capabilities.
- **Check for recent security advisories** on each candidate.
- **Include build-in-house as an implicit candidate** when the
  implementation would be under ~500 lines.
