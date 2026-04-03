# Multi-Perspective Analysis Template

Use this format for Mode 2 (multi-perspective analysis) research output.
This mirrors the agent debate format used in SeleneDB and Helios strategic
planning.

```markdown
# [Topic] Multi-Perspective Analysis

**Date:** YYYY-MM-DD
**Question:** [The specific decision being evaluated]
**Method:** [N]-perspective analysis
**Status:** Complete

## The Decision

[1-2 paragraphs framing the decision: what needs to be decided, what
constraints exist, what the stakes are.]

## Perspectives

[Define 3-5 perspectives. Each is a role with specific priorities.
Tailor to the decision domain.]

| # | Perspective | Priority Focus |
|---|-------------|---------------|
| 1 | [Role name] | [What this perspective optimizes for] |
| 2 | [Role name] | [What this perspective optimizes for] |
| 3 | [Role name] | [What this perspective optimizes for] |
| 4 | Devil's Advocate | Challenge assumptions and surface hidden risks |

## Scoring Summary

| Perspective | Score (0-50) | Key Argument |
|-------------|-------------|--------------|
| [Role 1] | [score] | [One-sentence core argument] |
| [Role 2] | [score] | [One-sentence core argument] |
| [Role 3] | [score] | [One-sentence core argument] |
| Devil's Advocate | [score] | [One-sentence core argument] |

## Consensus Items (majority agreement)

[Items where 3+ perspectives agree. These are highest-confidence findings.]

1. [Finding that most perspectives support]
2. [Finding that most perspectives support]

## Key Debates

### Debate 1: [Decision point where perspectives disagree]

**[Role A] argues:** [Position and supporting evidence]

**[Role B] argues:** [Opposing position and supporting evidence]

**Ruling:** [Which position wins and why. Be specific about the
deciding factor.]

### Debate 2: [Next disagreement]

[Same format]

## Priority Recommendations

[Ranked list of actions based on the analysis. Include confidence level.]

| Priority | Recommendation | Confidence | Rationale |
|----------|---------------|------------|-----------|
| 1 | [Top priority action] | High/Med/Low | [Why this is #1] |
| 2 | [Second priority] | High/Med/Low | [Why] |

## Not Recommended

[What was considered and rejected through this analysis.]

- **[Rejected approach]:** [Why - which perspectives opposed it and
  what risks were identified]

## Deferred Items

[Items that surfaced during analysis but are not actionable now.
Include gate conditions for when they become relevant.]

| Item | Gate | Source |
|------|------|--------|
| [Deferred work] | [What must be true first] | [Which perspective raised it] |
```

## Choosing perspectives

**Good perspectives are:**
- Distinct (each optimizes for something different)
- Relevant (each has genuine standing in the decision)
- Adversarial (at least one should challenge the prevailing assumption)

**Common role sets:**
- Technical: Performance, Security, DX, Maintainability, Devil's Advocate
- Strategic: Product, Engineering, Operations, Customer, Devil's Advocate
- Domain-specific: Edge/IoT, Cloud, Protocol, Integration, Devil's Advocate

**Always include Devil's Advocate.** This role explicitly challenges
assumptions, surfaces hidden costs, and argues for the minority position.
Without it, analysis tends toward groupthink.

## Scoring guidelines

- **40-50:** Strong argument with evidence, addresses counterarguments
- **30-39:** Reasonable argument but with gaps or unaddressed concerns
- **20-29:** Weak argument, significant counterarguments not addressed
- **10-19:** Largely unsupported position
- **0-9:** Contradicted by available evidence
