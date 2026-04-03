---
name: debate
description: >
  Structured multi-perspective debate for evaluating decisions. 3-phase
  methodology: independent generation, adversarial exchange, synthesis.
  Use when a decision has multiple valid approaches or high stakes.
disable-model-invocation: true
argument-hint: "[decision or question]"
---

## Purpose

Produce higher-quality decisions by evaluating them from multiple
independent perspectives that challenge each other's assumptions.
Research shows multi-perspective analysis mitigates anchoring bias,
confirmation bias, and groupthink while surfacing risks that
single-perspective analysis misses.

**Preferred invocation:** Delegate to the `debate-lead` agent, which has
this skill and `technical-writing` preloaded with persistent memory.
When agent teams are available, the agent spawns real teammates per
perspective for genuine inter-agent debate.

## Instructions

### Setup

1. If `$ARGUMENTS` was provided, use it as the decision to evaluate
2. Frame the decision clearly: what needs to be decided, what constraints
   exist, what the stakes are
3. Ask the user to confirm the framing before proceeding

### Choose perspectives

Select 3-5 perspectives with explicitly different frames. Each must
optimize for something different. Tailor to the decision domain.

**Common perspective sets:**

| Domain | Perspectives |
|:--|:--|
| Technical architecture | Performance, Security, DX/Maintainability, Devil's Advocate |
| Strategic/product | Product, Engineering, Operations, Customer, Devil's Advocate |
| Build vs depend | In-house Advocate, Dependency Advocate, Risk Analyst, Devil's Advocate |
| Edge/cloud | Edge Advocate, Cloud Advocate, Integration Architect, Devil's Advocate |

**Always include Devil's Advocate.** This perspective must:
- Argue from a specific alternative frame (not just "disagree")
- Propose a concrete alternative, not just criticize
- Be bounded to 1-2 rounds of objection before synthesis

Ask the user to confirm or adjust perspectives before starting.

### Phase 1: Independent generation

Each perspective generates its full argument independently before seeing
others. This prevents anchoring to the first position stated.

Each argument must use the Toulmin structure:

| Component | Purpose | Example |
|:--|:--|:--|
| **Claim** | The position | "We should build HNSW in-house" |
| **Grounds** | Evidence | Benchmarks, complexity analysis, team capability |
| **Warrant** | Why the evidence supports the claim | "Full control over memory layout enables 2x search speed" |
| **Qualifier** | Degree of certainty | "Likely correct if team maintains 2+ Rust engineers" |
| **Rebuttal** | When this position is wrong | "Unless time-to-market matters more than performance" |

**In team mode:** spawn one teammate per perspective. Each generates
independently before any messaging.

**In single-agent mode:** generate each perspective sequentially,
maintaining clear separation. Do not let earlier perspectives influence
later ones.

### Phase 2: Adversarial exchange (2-3 rounds)

Perspectives engage with each other's arguments. Each round has
decreasing contentiousness:

- **Round 1 (high contentiousness):** each perspective must identify the
  strongest counterargument to their position and address it directly.
  Must engage with the strongest opposing argument, not the weakest.
- **Round 2 (medium):** perspectives revise their positions based on
  what they learned. Must explicitly state what (if anything) changed
  their assessment and why.
- **Round 3 (low, optional):** final positions with explicit residual
  disagreements. Only run if significant unresolved tensions remain.

**Anti-conformity rule:** a perspective that agrees with the majority
must provide substantive new reasoning, not just "I agree." Agreement
without new evidence is noise.

**In team mode:** teammates message each other directly to challenge
arguments. Lead monitors but does not intervene unless debate stalls.

**In single-agent mode:** for each round, revisit each perspective
with knowledge of others' arguments.

### Phase 3: Synthesis

The moderator (lead or main agent) evaluates the full debate trajectory.

**Score each perspective's final argument:**

| Dimension | 1 (Weak) | 3 (Moderate) | 5 (Strong) |
|:--|:--|:--|:--|
| Evidence | Assertions only | Some data/examples | Concrete metrics, benchmarks |
| Relevance | Tangential | Related but indirect | Directly addresses decision criteria |
| Rebuttal quality | Ignores counterargs | Acknowledges opposition | Systematically addresses strongest counterargs |
| Reversibility | Ignores lock-in | Mentions switching cost | Quantifies commitment and exit paths |
| Confidence calibration | No uncertainty | Vague hedging | Explicit conditions for being wrong |

**Bias check:** before producing the final output, check for:
- Anchoring to the first perspective generated
- Sunk cost reasoning ("we've already invested in X")
- Groupthink (all perspectives converging without genuine tension)
- Optimism bias (underestimating effort or risk)

**Produce the output document.** See
[debate-output-template.md](debate-output-template.md) for the format.

### Save and report

Save findings to the configured location (default `_plans/`).
Name: `YYYY-MM-DD-<topic>-debate.md`.

Present a summary: the decision, key arguments, and the ruling.

## Supporting files

- [debate-output-template.md](debate-output-template.md) - output format for debate findings

## Guidance

**3-5 perspectives, 3 rounds.** Research consistently shows this is the
sweet spot. Beyond 5 perspectives, gains are marginal and token costs
increase substantially. Beyond 3 rounds, positions are established and
further exchange adds little.

**Diversity of frame matters more than quantity.** Three perspectives
with genuinely different optimization targets outperform five perspectives
that share similar reasoning frames.

**The Devil's Advocate must propose alternatives, not just object.**
Pure criticism without constructive alternatives causes analysis paralysis.
An effective Devil's Advocate says "here is a concrete failure mode, and
here is what we should do instead."

**Residual disagreements are valuable.** Do not force false consensus.
Documenting what remains unresolved and under what conditions to revisit
is more useful than a fabricated agreement.
