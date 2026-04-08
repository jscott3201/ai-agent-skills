# SeleneDB Graph Schema

Node types and edge types for the reasoning graph. All nodes include
auto-generated properties: `id`, `created_at`, `updated_at`, `version`.
Text properties with `searchable = true` are indexed for BM25 full-text
search and auto-embedded for vector search.

## Schema Registration

Node type schemas must be registered in SeleneDB for search and indexing
to work. Use the MCP `create_schema` tool or GQL DDL to register each
node type before first use. Properties marked `(searchable)` in the
tables below must have `searchable = true` in their schema definition.

Without schema registration:
- INSERT and MATCH work (schemaless mode)
- MERGE works for matching on properties
- Search procedures (`semanticSearch`, `hybridSearch`, `textSearch`)
  return no results — they rely on search indexes built from schemas

Register schemas once per SeleneDB instance, not per session.

## Reserved Keywords

The following are reserved in ISO GQL and cannot be used as label names:
`Commit`, `Match`, `Insert`, `Delete`, `Set`, `Return`, `Where`, `With`,
`Order`, `Group`, `Filter`, `Limit`, `Union`, `All`, `Any`, `Not`, `And`,
`Or`, `True`, `False`, `Null`, `In`, `Is`, `By`, `As`, `On`, `Create`.

Use alternatives: `GitCommit` instead of `Commit`, etc.

## Node Types

### :Session
Conversation context anchor. Every reasoning node links back to a session.

| Property | Type | Description |
|---|---|---|
| `date` | Date | When the session occurred |
| `project` | String | Git remote or directory name |
| `branch` | String | Git branch |
| `scope` | String (searchable) | What was being worked on |
| `skill` | String | Which skill ran |
| `outcome` | String | completed, aborted, deferred, partial |
| `summary` | String (searchable) | Rolling summary of what was accomplished |
| `next_steps` | String (searchable) | What to do next (populated at completion) |

### :Document
Full artifact container (plan, research doc, review report).

| Property | Type | Description |
|---|---|---|
| `title` | String (searchable) | Document title |
| `doc_type` | String | plan, research, review, landscape, deep_dive |
| `content` | String (searchable) | Full markdown content |
| `mode` | String | Research mode (deep-dive, multi-perspective, landscape) |

### :Decision
Atomic choice with rationale. The fundamental reasoning unit.

| Property | Type | Description |
|---|---|---|
| `summary` | String (searchable) | What was decided |
| `rationale` | String (searchable) | Why this choice was made |
| `alternatives` | String | What was considered and rejected |
| `confidence` | String | high, medium, low |

### :Finding
Review or audit discovery with severity classification.

| Property | Type | Description |
|---|---|---|
| `summary` | String (searchable) | What was found |
| `severity` | String | S1_critical, S2_high, S3_medium, S4_low |
| `category` | String | Review category (1-13 from deep-review) |
| `why_it_matters` | String | Impact if left unfixed |
| `suggested_fix` | String | Concrete fix direction |
| `triage` | String | fix_now, skip, defer |

### :Insight
Research learning with cited sources.

| Property | Type | Description |
|---|---|---|
| `summary` | String (searchable) | What was learned |
| `sources` | String | Cited references |
| `confidence` | String | high, medium, low |
| `actionable` | Boolean | Whether this directly informs a decision |

### :Hypothesis
Debug theory following the scientific method.

| Property | Type | Description |
|---|---|---|
| `statement` | String (searchable) | The hypothesis |
| `prediction` | String | What would be observed if true |
| `test` | String | How to check |
| `result` | String | What was actually observed |
| `conclusion` | String | confirmed, eliminated, inconclusive |
| `rank` | Integer | Likelihood ranking (1 = most likely) |

### :RootCause
Link in a 5 Whys chain. Each level points deeper.

| Property | Type | Description |
|---|---|---|
| `why` | String (searchable) | The causal explanation at this level |
| `level` | Integer | Depth in the chain (1 = surface, 5 = systemic) |
| `systemic` | Boolean | Whether this is the root systemic cause |

### :DeferredItem
Tracked deferred work with a verifiable gate.

| Property | Type | Description |
|---|---|---|
| `item` | String (searchable) | Short name |
| `description` | String (searchable) | What the work involves |
| `priority` | String | high, medium, low |
| `category` | String | Project-specific grouping |
| `kind` | String | bug, feature, tech_debt, research, optimization |
| `status` | String | open, in_progress, completed, wont_do |
| `source` | String | Where this came from (plan, phase, conversation) |
| `stale` | Boolean | Flagged during review |

### :Gate
Verifiable trigger condition for deferred work.

| Property | Type | Description |
|---|---|---|
| `condition` | String (searchable) | What must be true |
| `met` | Boolean | Whether the condition has been satisfied |
| `met_on` | Date | When the gate was met |
| `evidence` | String | How we know it was met |

### :CoverageGap
Untested code path identified by test-strategy.

| Property | Type | Description |
|---|---|---|
| `function` | String | Function or method name |
| `gap_type` | String | edge_case, error_path, boundary, concurrency, property |
| `description` | String (searchable) | What is not tested |
| `addressed` | Boolean | Whether tests were generated |

### :Release
Version release with changelog and breaking changes.

| Property | Type | Description |
|---|---|---|
| `version` | String | Semantic version (e.g., 1.3.0) |
| `bump_type` | String | patch, minor, major |
| `date` | Date | Release date |
| `changelog` | String (searchable) | Full changelog content |
| `has_breaking_changes` | Boolean | Whether breaking API changes exist |

### :CodeLocation
File and optional line range in the codebase.

| Property | Type | Description |
|---|---|---|
| `file` | String | Relative file path |
| `line_start` | Integer | Start line (optional) |
| `line_end` | Integer | End line (optional) |
| `function` | String | Function or method name (optional) |
| `module` | String | Module path (optional) |

### :Rationalization
When an anti-rationalization pattern was observed during a session.

| Property | Type | Description |
|---|---|---|
| `pattern` | String (searchable) | The rationalization that was caught |
| `skill` | String | Which skill's anti-rationalization table matched |
| `corrective_action` | String | What was done instead |

### :PlanClaim
A claim made in a plan about the codebase (used by plan-verify).

| Property | Type | Description |
|---|---|---|
| `claim` | String (searchable) | What the plan asserted |
| `actual` | String | What the codebase actually shows |
| `inaccuracy_type` | String | naming, mapping, resource, staleness, none |
| `blast_radius` | Integer | Number of downstream tasks affected |

### :Incident
Production issue tracked through triage, mitigation, and postmortem.

| Property | Type | Description |
|---|---|---|
| `title` | String (searchable) | Brief incident description |
| `severity` | String | S1_critical, S2_high, S3_medium, S4_low |
| `blast_radius` | String | Who/what was affected |
| `started_at` | String | When symptoms first appeared |
| `resolved_at` | String | When impact ended |
| `duration` | String | Time from detection to resolution |
| `mitigation` | String (searchable) | What was done to stop the bleeding |
| `root_cause` | String (searchable) | What actually went wrong |
| `lessons_learned` | String (searchable) | What we learned |

### :Perspective
A viewpoint in a structured debate with Toulmin argument structure.

| Property | Type | Description |
|---|---|---|
| `role` | String | Perspective name (e.g., Security Advocate) |
| `priority_focus` | String | What this perspective optimizes for |
| `claim` | String (searchable) | The position taken |
| `grounds` | String | Evidence supporting the claim |
| `warrant` | String | Why the evidence supports the claim |
| `qualifier` | String | Degree of certainty |
| `rebuttal` | String | When this position is wrong |
| `score` | Integer | Final synthesis score (0-50) |

### :Note
Free-form annotation attached to any graph node. Captures context that doesn't
fit structured types: rationale, TODOs, observations, bookmarks.

| Property | Type | Description |
|---|---|---|
| `content` | String (searchable) | The note text |
| `kind` | String | todo, rationale, observation, bookmark |
| `author` | String | user, agent |

### :Convention
Project-specific coding or architectural rule promoted from recurring review
findings. Supplements (does not replace) built-in skill rules.

| Property | Type | Description |
|---|---|---|
| `rule` | String (searchable) | The convention statement (e.g., "All public API functions must validate input") |
| `scope` | String | Where it applies (e.g., "rust", "api-design", "selene-gql", "testing") |
| `severity` | String | critical, recommended, advisory |
| `rationale` | String (searchable) | Why this convention exists |
| `source` | String | Where it was discovered (e.g., "promoted from 4 deep-review findings") |
| `active` | Boolean | Whether this convention is currently enforced |

### :Milestone
Named development initiative grouping 5-25 commits, documents, and decisions.
Fills the gap between individual commits and the full project roadmap.

| Property | Type | Description |
|---|---|---|
| `name` | String (searchable) | Initiative name (e.g., "Auth middleware rewrite") |
| `description` | String (searchable) | What this milestone covers |
| `status` | String | planned, in_progress, completed, abandoned |
| `started_on` | Date | When work began |
| `completed_on` | Date | When work finished |
| `target_date` | Date | Expected completion (optional) |

### :Topic
Domain area or subject that documents, insights, and deferred items can be
tagged with. Enables cross-skill discovery: "What research covers embeddings?"

| Property | Type | Description |
|---|---|---|
| `name` | String (searchable) | Topic name (e.g., "embeddings", "auth", "query-engine") |
| `domain` | String | Broad domain grouping (e.g., "infrastructure", "security", "ml") |
| `description` | String (searchable) | What this topic area covers |

### :GitCommit
A git commit that implements, fixes, or introduces a change linked to reasoning.
Note: `Commit` is a reserved keyword in ISO GQL — use `GitCommit` instead.

| Property | Type | Description |
|---|---|---|
| `sha` | String | Full commit SHA (unique identifier) |
| `short_sha` | String | Short SHA for display (e.g., a30c465) |
| `message` | String (searchable) | Commit message |
| `author` | String | Commit author |
| `date` | Date | Commit date |
| `branch` | String | Branch the commit was made on |
| `files_changed` | Integer | Number of files modified |

## Edge Types

| Edge | From | To | Meaning |
|---|---|---|---|
| `:produced` | Session | any reasoning node | Session generated this |
| `:contains` | Document | Decision, Finding, Insight | Parent-child hierarchy |
| `:based_on` | Decision | Insight, Finding, Hypothesis | Evidence for the decision |
| `:affects` | Decision, Finding | CodeLocation | What code is impacted |
| `:led_to` | Decision | Decision, Finding | Downstream consequence |
| `:resolved_by` | Finding, DeferredItem | Decision | How it was addressed |
| `:gated_by` | DeferredItem | Gate | Trigger condition |
| `:blocks` | DeferredItem | DeferredItem | Dependency |
| `:supersedes` | any | any (same type) | Invalidation/replacement |
| `:why` | RootCause | RootCause | 5 Whys depth chain |
| `:tested_by` | Hypothesis | (inline) | Test applied to hypothesis |
| `:covers` | CoverageGap | CodeLocation | What code is untested |
| `:continued_from` | Session | Session | Multi-session chains |
| `:in_project` | Session | (project scope) | Project grouping |
| `:observed_in` | Rationalization | Session | When pattern was caught |
| `:verified_as` | Document (plan) | (quality gate) | Plan verification result |
| `:breaking_change` | Release | CodeLocation | What API changed |
| `:changelog_entry` | Release | (inline) | Release note |
| `:mitigated_by` | Incident | Decision | Mitigation strategy chosen |
| `:caused_by` | Incident | RootCause | Root cause link |
| `:postmortem` | Incident | Document | Postmortem document |
| `:argued_by` | Document (debate) | Perspective | Debate viewpoint |
| `:ruled_as` | Document (debate) | Decision | Debate ruling |
| `:non_goal` | Document (plan/design) | Decision | Explicitly scoped out |
| `:implemented_by` | Decision, Document (plan) | Commit | Reasoning produced this change |
| `:fixed_by` | Finding, RootCause | Commit | Issue was addressed in this commit |
| `:introduced_by` | Incident | Commit | This commit caused the incident |
| `:released_in` | Commit | Release | Commit included in this release |
| `:annotates` | Note | any | Free-form annotation attached to a node |
| `:promoted_from` | Convention | Finding | Convention was derived from recurring findings |
| `:informs` | Document, Insight | Document, Decision | Upstream artifact informed downstream one |
| `:about` | Document, Insight, DeferredItem, Milestone | Topic | Domain area this artifact covers |
| `:part_of` | GitCommit, Document, Decision, Session | Milestone | Artifact belongs to this initiative |
