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

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior research before starting:

1. **Create session** with `skill: 'research'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior research on this topic:
   - Prior `:Insight` and `:Decision` nodes matching the scope
   - Prior `:Document {doc_type: 'research'}` on similar topics
   - Any `:DeferredItem` nodes with research-related gates approaching

3. If relevant prior research is found, present it:

> "Prior research context:
> - [Date]: [Topic] — [key finding or recommendation]
> - [Any rejected approaches from prior 'Not Recommended' sections]
>
> This may inform the current investigation. Proceeding with research."

This prevents re-investigating dead ends and builds on prior findings.
If no prior context is found, skip silently.

If SeleneDB is not available or no prior context exists, skip silently.

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

### 3. Checkpoint before synthesis (modes 1-3)

After gathering sources and before producing the full document, present
an outline to the user:

> "Research gathered. Here's what I found and what I plan to write:
>
> **Sources:** N sources consulted ([list key ones])
> **Key findings so far:**
> 1. [Most important finding]
> 2. [Second finding]
> 3. [Third finding]
>
> **Proposed document structure:**
> - [Section 1 — what it covers]
> - [Section 2 — what it covers]
> - [...]
>
> **My recommendation:** [brief summary of where the research points]
>
> Options:
> 1. **Proceed** — produce the full document with this structure
> 2. **Adjust** — change focus, add/remove sections, investigate more
> 3. **Enough** — the findings above answer my question, skip the document
>
> Which direction?"

Wait for the user's decision. This prevents spending effort synthesizing
a document that misses what the user actually needed.

Skip this checkpoint for mode 4 (doc lookup), which is quick-turnaround.

#### Graph write: checkpoint (SeleneDB)

At checkpoint, write preliminary insights to the graph. These capture
the research direction even if the user adjusts or stops here.

For each key finding presented at checkpoint, create an `:Insight` node:

```gql
INSERT (i:Insight {
  summary: $finding_summary,
  sources: $cited_sources,
  confidence: 'preliminary',
  actionable: false
})
RETURN id(i) AS insight_id
```

Link each insight to the session and to relevant code locations if the
finding references specific code:

```gql
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (i:Insight) WHERE id(i) = $insight_id
INSERT (s)-[:produced]->(i)
```

If the user chooses "Enough", update these insights to `confidence:
'final'` and `actionable: true` where applicable, then update the
session outcome to `completed`.

### 4. Save and report

For modes 1-3, save the findings document to `_agentskills/research/`.
Name the file with the date and topic: `YYYY-MM-DD-<topic>-research.md`.
Create the directory if it does not exist.

For mode 4 (doc lookup), output directly unless the user asks to save.

Present a summary of key findings to the user after saving.

#### Graph write: synthesis (SeleneDB)

After the full document is saved, extract structured reasoning into the
graph. What to extract depends on the research mode:

**All modes:**
- Create a `:Document` node with `doc_type` matching the mode
  (`deep_dive`, `multi_perspective`, `landscape`) and `content` set to
  the full markdown. Link to session via `:produced`.
- Update checkpoint `:Insight` nodes from `preliminary` to `final`.
  Set `actionable: true` for findings that directly inform decisions.
- **Tag with topics.** Identify 1-5 domain areas the research covers.
  For each, create/merge a `:Topic` node and link via `:about`:

```gql
MERGE (t:Topic {name: $topic_name})
ON CREATE SET t.domain = $domain, t.description = $topic_description

MATCH (doc:Document) WHERE id(doc) = $doc_id
MATCH (t:Topic {name: $topic_name})
INSERT (doc)-[:about]->(t)
```

  Also link individual `:Insight` nodes to their most relevant topic:

```gql
MATCH (i:Insight) WHERE id(i) = $insight_id
MATCH (t:Topic {name: $topic_name})
INSERT (i)-[:about]->(t)
```

  Topic names: lowercase, specific, reusable (`'embeddings'`, `'auth'`,
  `'query-optimization'`). See [selene-patterns.md](../_selene/selene-patterns.md)
  for naming conventions.

**Mode 1 (deep-dive) additional extraction:**
- Each trade-off row → `:Decision` node with `alternatives` capturing
  both sides. Link to document via `:contains`.
- Each risk row → `:Insight` with risk context in summary.
- Recommended approach → `:Decision` with `confidence: 'high'` and
  rationale from the analysis.
- Each "Not Recommended" item → `:Decision` with rationale capturing
  why it was rejected. These are high-value for future recall.

**Mode 2 (multi-perspective) additional extraction:**
- Each consensus item → `:Insight` with `confidence: 'high'`.
- Each debate ruling → `:Decision` with `rationale` capturing the
  deciding factor and `alternatives` capturing the losing position.
- Each priority recommendation → `:Decision` with confidence level.
- Each deferred item from the template → `:DeferredItem` with `:Gate`.
  This bridges directly to deferred-tracking.

**Mode 3 (landscape) additional extraction:**
- Recommendation → `:Decision` with candidate details.
- Build-vs-depend verdict → `:Decision`.
- Each "Not Recommended" candidate → `:Decision` with rejection reason.
- Each candidate profile → `:Insight` summarizing key strength/weakness.

**Linking to code:**
If the research references specific modules, files, or functions in the
codebase, create `:CodeLocation` nodes and link via `:affects`.

**Session completion:**
Update session outcome to `completed` (or `partial` if the user chose
"Enough" at checkpoint without full synthesis).

## Supporting files

- [deep-dive-template.md](deep-dive-template.md) - technical deep-dive output format
- [multi-perspective-template.md](multi-perspective-template.md) - multi-perspective analysis output format
- [landscape-template.md](landscape-template.md) - competitive/landscape analysis output format
- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Skip checkpoint, proceed to synthesis" | Checkpoints catch wrong directions before you invest in synthesis. Minutes saved, hours wasted. |
| "High-level findings are good enough" | Vague findings produce vague decisions. Every finding must be specific and cite sources. |
| "Skip 'not recommended' section" | Knowing what to avoid is as valuable as knowing what to adopt. It prevents re-investigation. |
| "Share findings in conversation, don't save" | Conversations disappear. Saved research persists for the team and future sessions. |

## Red Flags

Stop and reassess if you observe:
- Synthesizing without presenting the checkpoint to the user first
- Findings without cited sources or specific evidence
- Missing "Not Recommended" section (rejected approaches are as valuable as recommendations)
- Skipping web search or academic sources when investigating a technology

## Verification

- [ ] Research mode selected and appropriate for the question
- [ ] Checkpoint presented to user before synthesis
- [ ] Every finding is specific with cited sources
- [ ] "Not recommended" section included where applicable
- [ ] Research document saved to `_agentskills/research/`

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

**SeleneDB amplifies "Not Recommended" value.** Rejected approaches
stored in the graph surface automatically when future research covers
the same topic. This directly prevents the re-investigation problem the
skill's guidance warns about.
