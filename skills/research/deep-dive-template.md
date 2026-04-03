# Technical Deep-Dive Template

Use this format for Mode 1 (technical deep-dive) research output.

```markdown
# [Topic] Technical Deep-Dive

**Date:** YYYY-MM-DD
**Question:** [The specific question being investigated]
**Status:** Complete

## Executive Summary

[2-3 sentences: what was investigated, key finding, recommended approach]

## How It Works

[Technical explanation of the subject. Use subsections as needed.
Include diagrams (ASCII art) where they clarify structure or flow.
Explain at a level appropriate for the project's engineering team.]

### Core Concepts

[Foundational concepts needed to understand the technology]

### Architecture / Data Flow

[How components interact. ASCII diagrams for complex flows.]

### Key Algorithms

[Algorithm descriptions with complexity analysis. Include pseudocode
or actual code samples in the project's primary language.]

## Implementation Considerations

[What matters when building with or on top of this technology]

### Integration Points

[How this would connect to the existing codebase. Reference specific
modules, APIs, or patterns in the project.]

### Performance Characteristics

[Throughput, latency, memory usage. Include benchmarks or estimates
with stated assumptions. Cite sources.]

### Trade-offs

| Choice | Advantage | Disadvantage |
|--------|-----------|--------------|
| [Option A] | [What it does well] | [What it costs] |
| [Option B] | [What it does well] | [What it costs] |

## Risks and Limitations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [What could go wrong] | Low/Med/High | [Consequence] | [How to handle] |

## Recommended Approach

[Clear recommendation with rationale. Reference the trade-off analysis
and risk assessment above.]

## Not Recommended

[Approaches that were considered and rejected. Be specific about why
each was rejected so future researchers don't re-investigate.]

- **[Rejected approach]:** [Why - specific failure mode or unacceptable tradeoff]

## Sources

[Numbered list of all sources consulted. Include URLs, paper titles,
documentation versions. Every claim in the document should trace to
a source.]

1. [Source title](URL) - what it contributed
2. [Source title](URL) - what it contributed
```

## Writing guidelines

- **Cite everything.** No unsourced claims. If a performance number comes
  from a benchmark, link the benchmark. If a limitation comes from a paper,
  cite the paper.
- **Show, don't just tell.** Code examples, diagrams, and data tables are
  more convincing than prose assertions.
- **Quantify where possible.** "Slow" is not useful. "O(n^2) above 10K
  items, measured at 340ms for n=50K" is useful.
- **State assumptions explicitly.** "This analysis assumes single-threaded
  execution on ARM64" prevents misinterpretation.
