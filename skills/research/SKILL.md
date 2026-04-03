---
name: research
description: >
  Structured research producing actionable findings documents. Supports
  technical deep-dives, multi-perspective analysis, competitive landscape,
  and documentation lookup. Use when investigating before building.
disable-model-invocation: true
argument-hint: "[topic or question]"
---

## Purpose

Produce structured, verifiable research findings that feed directly into
design and implementation decisions. Every finding is specific (file, line,
code snippet), severity-ranked, and cross-referenced. Research outputs are
decision documentation, not exploratory notes.

## Instructions

### 1. Select research mode

If `$ARGUMENTS` was provided, use it as the research topic. Ask the user
which mode fits their question:

> "Four research modes available:
> 1. **Technical deep-dive** - understand how something works (algorithm, protocol, technology)
> 2. **Multi-perspective analysis** - evaluate a decision from multiple angles with scoring
> 3. **Competitive/landscape analysis** - compare competing solutions or approaches
> 4. **Documentation research** - quick lookup of current library APIs and patterns
>
> Which mode?"

### 2. Execute research

Each mode has its own workflow and output format. See the supporting
templates for detailed structure.

#### Mode 1: Technical deep-dive

**When:** "How does X work?" before building something.

**Process:**
1. Search the web for authoritative sources (official docs, RFCs, papers)
2. Search academic literature via Consensus for peer-reviewed research
3. Fetch current library docs via Context7 if applicable
4. Synthesize into a structured findings document

**Tools to use:**
- `WebSearch` + `WebFetch` for general technical content
- `Consensus` for academic papers and peer-reviewed research
- `Context7` for library/framework documentation
- `Read` + `Grep` + `Glob` for codebase context

**Output:** [deep-dive-template.md](deep-dive-template.md)

Key sections: executive summary, how it works (with diagrams where helpful),
implementation considerations, performance characteristics, risks and
limitations, recommended approach, sources.

#### Mode 2: Multi-perspective analysis

**When:** Evaluating a strategic or architectural decision where multiple
valid perspectives exist.

**Process:**
1. Define the question and the decision space
2. Define 3-5 perspectives (roles) that bring different priorities:
   - e.g., Performance Advocate, Security Advocate, DX Advocate,
     Edge/IoT Advocate, Devil's Advocate
   - Tailor roles to the specific decision
3. Analyze from each perspective independently
4. Score each perspective's assessment (0-50 scale per perspective)
5. Identify consensus items (majority agreement)
6. Surface key debates where perspectives disagree
7. Provide a ruling for each debate with rationale

**Output:** [multi-perspective-template.md](multi-perspective-template.md)

Key sections: question, perspectives defined, scoring matrix, consensus
items, key debates with rulings, priority recommendations, not recommended.

#### Mode 3: Competitive/landscape analysis

**When:** "What else exists for X?" Evaluating alternatives before building
or choosing a technology.

**Process:**
1. Search the web for competing solutions, libraries, or approaches
2. For each candidate: identify key features, architecture, strengths,
   weaknesses, adoption, and maintenance status
3. Build a feature comparison matrix
4. Identify differentiation and gaps
5. Recommend an approach

**Tools to use:**
- `WebSearch` for discovery and feature comparison
- `Context7` for documentation of specific candidates
- `dep-audit` methodology for health assessment of library candidates

**Output:** [landscape-template.md](landscape-template.md)

Key sections: overview, candidate profiles, feature comparison matrix,
differentiation analysis, recommendation, not recommended.

#### Mode 4: Documentation research

**When:** Quick-turnaround lookup of current APIs, configuration options,
or usage patterns for a specific library or framework.

**Process:**
1. Resolve the library via Context7 (`resolve-library-id`)
2. Query documentation via Context7 (`query-docs`) with specific questions
3. Supplement with web search for recent changes or migration guides
4. Produce a focused reference summary

**Tools to use:**
- `Context7` as primary source (resolve-library-id + query-docs)
- `WebSearch` + `WebFetch` for supplementary information
- `Consensus` for papers about the technology if relevant

**Output:** concise reference document with:
- API signatures and usage patterns relevant to the question
- Configuration options with defaults and recommended values
- Common pitfalls and migration notes
- Code examples (copy-pasteable)

This mode does not need a formal template. Output directly in the
conversation or save to a file if the user requests.

### 3. Save and report

For modes 1-3, save the findings document to the configured location
(default `_plans/`, or ask the user). Name the file with the date and
topic: `YYYY-MM-DD-<topic>-research.md`.

For mode 4 (doc lookup), output directly unless the user asks to save.

Present a summary of key findings to the user after saving.

## Supporting files

- [deep-dive-template.md](deep-dive-template.md) - technical deep-dive output format
- [multi-perspective-template.md](multi-perspective-template.md) - multi-perspective analysis output format
- [landscape-template.md](landscape-template.md) - competitive/landscape analysis output format

## Guidance

**Every finding must be specific.** "X might be an issue" is not a finding.
"X uses algorithm Y which has O(n^2) complexity at scale Z, causing
performance degradation above N items" is a finding. Cite sources for
every claim.

**Not Recommended sections are as valuable as recommendations.** Documenting
what was considered and rejected prevents future contributors from
re-investigating dead ends.

**Research feeds into action.** Every research document should end with
clear next steps: what to build, what to investigate further, what to
defer, and what to reject.

**Use persistent memory.** If running as the researcher agent, save key
findings (competitive landscapes, technology evaluations, API patterns)
to memory so they are available in future sessions without re-researching.
