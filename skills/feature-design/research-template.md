# Research and Design Document Template

Use this template for Stage 3 formal research. Scale sections to complexity -
a focused feature might have short sections; a major initiative needs depth.

```markdown
# [Feature] Design Document

**Date:** YYYY-MM-DD
**Status:** Draft | Under Review | Approved
**Author:** [who conducted the analysis]

## Goals

What this feature delivers. Bullet points, specific and measurable.

- [Primary goal - the core capability being built]
- [Secondary goals - supporting capabilities]

## Non-Goals

What this feature explicitly does NOT address. Equally important as goals.
These prevent scope creep during implementation.

- [Adjacent capability that is out of scope]
- [Future enhancement that is deferred]
- [Related problem that is someone else's responsibility]

## Context

Brief landscape of the current state. How does the system work today?
What gap does this feature fill? Link to existing docs rather than
reproducing them.

[2-3 paragraphs max. Include a system context description showing how
the new component fits the existing architecture if helpful.]

## Design Decisions

Decisions made during this design, with full rationale. Use the format:

| ID | Decision | Alternatives Rejected | Rationale | Impact |
|----|----------|-----------------------|-----------|--------|
| D-01 | [What was decided] | [What was not chosen] | [Why this option wins] | [What changes as a result] |

For complex decisions, expand with a paragraph below the table:

### D-01: [Decision Title]

**Context:** [What forces are at play - constraints, requirements, tradeoffs]

**Decision:** [What we chose]

**Alternatives considered:**
1. [Option B] - rejected because [specific reason]
2. [Option C] - rejected because [specific reason]

**Consequences:** [What follows from this decision - both positive and negative]

## Technical Analysis

Structure this section based on what matters for the feature. Common
subsections (include only what is relevant):

### Data Model / Data Structures

[Key types, schemas, or data structures. Show actual code or type
definitions, not prose descriptions.]

### API Design

[Endpoints, function signatures, or protocol messages. Show the
interface the consumer will use.]

### Integration Points

[How this feature connects to existing code. Which modules are
affected, which APIs are consumed, which events are emitted.]

### Performance Considerations

[Expected throughput, latency targets, memory bounds. Include
estimates with assumptions stated.]

### Security Considerations

[Auth requirements, input validation, data sensitivity, encryption
needs. Reference the safety-checks skill categories.]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [What could go wrong] | Low/Med/High | [Consequence] | [How to prevent or handle] |

## Not Recommended

What was explicitly considered and rejected, with rationale. This is
one of the most valuable sections - it prevents future contributors
from re-proposing ideas that were already evaluated.

- **[Rejected approach]:** [Why it was rejected - be specific about the
  failure mode or tradeoff that made it unacceptable]
```

## Guidelines for writing research docs

**Scale to complexity.** A small feature needs 1-2 pages. A major initiative
needs 5-10. If the document exceeds 15 pages, the feature may need
decomposition.

**Decisions are the core artifact.** Everything else supports the decisions.
If you remove all other sections, the decision table should still tell the
story of what was chosen and why.

**"Not Recommended" earns its place.** This section prevents wasted effort.
Every hour spent documenting a rejected approach saves days of someone
re-discovering why it does not work.

**Be specific, not comprehensive.** Show the API signature, not the full
implementation. Show the data model, not every field. Show the performance
estimate, not the benchmarking methodology. Details belong in the
implementation plan, not the design doc.

**State assumptions explicitly.** "This design assumes the database handles
100K reads/second" is useful. An unstated assumption becomes a silent failure
mode.
