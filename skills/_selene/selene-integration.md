# SeleneDB Integration Guide

Supporting file for all skills. SeleneDB is the foundation of this
plugin — every skill reads from and writes to the property graph.
Skills reference this file for detection, session management, and
auto-recall. Schema and query patterns are in separate supporting files.

**Supporting files:**
- [selene-schema.md](selene-schema.md) — node types, edge types, property definitions
- [selene-patterns.md](selene-patterns.md) — write patterns, read patterns, rationalization tracking
- [reasoning-schema.gql](reasoning-schema.gql) — GQL DDL statements for schema registration
- [setup-schema.sh](setup-schema.sh) — one-command schema setup script

## Multi-Project Convention

Multiple projects share a single SeleneDB graph. All project-specific
node types carry a `project` property for isolation. Cross-cutting
nodes (`skill`, `agent`, `dependency`, `workflow_category`) are shared
and have no `project` property.

**Rules:**
- Every INSERT of a project-specific node must include `project: $project`
- MERGE on CodeLocation must include `project` (same file path in
  different repos refers to different files)
- Topics can omit `project` to bridge projects, or include it for
  project-scoped topics
- Filter by `WHERE n.project = $project` for project-scoped queries
- Omit the filter for cross-project aggregation

**Project naming:** Use the well-known project or plugin name
(e.g., `'justin-tools'`, `'SeleneDB'`), not directory paths that
vary per user's machine. Set this once at session start.

See [selene-schema.md](selene-schema.md) for which node types are
project-specific vs shared.

## Detection

SeleneDB is required. Check that the `gql_query` tool is available
at skill start. If it is not available, inform the user:

> "This plugin requires SeleneDB. Configure the SeleneDB MCP server
> in your project or user settings, then retry."

Do not proceed with the skill workflow without SeleneDB.

## Session Creation

When a skill starts, auto-create a session node before any other
graph operations:

```gql
INSERT (s:Session {
  date: date(),
  project: $project,
  branch: $branch,
  scope: $scope,
  skill: $skill_name,
  outcome: 'in_progress'
})
RETURN id(s) AS session_id
```

**GQL syntax notes:**
- String literals use **single quotes**: `'value'` not `"value"`
- INSERT requires a **variable binding** (`s:Session`) to RETURN from it
- Use `id(s)` to get the auto-generated node ID
- Variable-length paths use ISO GQL syntax: `-[:edge]->{1,5}` not `*1..5`
- Negation patterns use `NOT EXISTS { MATCH ... }` not `NOT (n)-[:e]->()`
- `$variable` placeholders in examples represent values the skill substitutes

**Schema registration required for search.** Semantic search, hybrid
search, and text search only work on properties marked `SEARCHABLE`
in registered schemas. Run the setup script once per SeleneDB instance,
then restart SeleneDB to build search indexes:

```bash
./skills/_selene/setup-schema.sh http://localhost:8080
# then restart SeleneDB
```

See [selene-schema.md](selene-schema.md) for which properties are searchable.

Capture `session_id` for linking all reasoning produced in this session.

**Property sources:**
- `project`: well-known project/plugin name (e.g., `'justin-tools'`,
  `'SeleneDB'`). Derive from plugin name or repo identity, not
  directory path. Must be stable across machines.
- `branch`: output of `git branch --show-current`
- `scope`: `$ARGUMENTS` or user-provided description
- `skill`: the skill name from SKILL.md frontmatter

**Mandatory: update session outcome and summary when the skill completes.**
Every skill must close its session, regardless of whether it has an explicit
graph write section for this. Set the outcome and write a rolling summary:

```gql
MATCH (s:Session) WHERE id(s) = $session_id
SET s.outcome = $outcome,
    s.summary = $summary,
    s.next_steps = $next_steps
```

- `summary`: 1-2 sentences describing what was accomplished. Be specific:
  "Researched query optimization, evaluated 3 candidates, recommended
  BTreeMap index" not "Did some research."
- `next_steps`: What the next session should do. Be actionable:
  "Design caching layer based on research findings" not "Continue work."
  If no clear next steps, leave null.

These fields power cross-session continuity. The SessionStart hook loads
the last 3 sessions' summaries to bootstrap new sessions with full
context of recent work.

| Outcome | When to use |
|---|---|
| `completed` | Skill finished its full workflow |
| `partial` | User stopped early (e.g., "Enough" at checkpoint) |
| `aborted` | Skill was abandoned or context switched |
| `deferred` | Work was explicitly deferred for later |

For plan-verify, the quality gate decision (`go`, `fix_and_go`, `rewrite`,
`kill`) replaces the generic outcome as a more specific signal.

## Scoped Auto-Recall

After creating the session, query for relevant prior reasoning before
starting the skill's main workflow. This surfaces context from past
sessions that worked on the same code or topic.

**Step 1 — Scope query.** Search for prior reasoning connected to the
current scope using semantic search (text-based, handles embedding
internally):

```gql
CALL graph.semanticSearch($scope_description, 10)
YIELD node_id, score
MATCH (n) WHERE id(n) = node_id
MATCH (n)<-[:produced]-(s:Session)
WHERE s.project = $project
RETURN n, s.skill AS source_skill, s.date AS when, score
ORDER BY score DESC
```

For label-scoped search, use `hybridSearch` (BM25 + vector fusion):

```gql
CALL graph.hybridSearch('Finding', $scope_description, 10)
YIELD node_id, score
MATCH (n) WHERE id(n) = node_id
MATCH (n)<-[:produced]-(s:Session)
WHERE s.project = $project
RETURN n, s.skill AS source_skill, s.date AS when, score
ORDER BY score DESC
```

**Available search procedures:**
- `graph.semanticSearch(query, k)` — text search across all searchable properties, yields `node_id, score, path`
- `graph.hybridSearch(label, query, k)` — BM25 + vector fusion on a specific label, yields `node_id, score`
- `graph.textSearch(label, property, query, k)` — BM25 full-text on a specific property, yields `node_id, score`
- `graph.vectorSearch(label, property, queryVector, k)` — raw vector search (requires pre-computed vector), yields `node_id, score`
- `graph.similarNodes(nodeId, property, k)` — find nodes similar to a given node, yields `node_id, score`

All search procedures yield `node_id` (not full nodes). Chain with
`MATCH (n) WHERE id(n) = node_id` to resolve full node data.

**Step 2 — Present context.** If results are found, present a brief
summary before starting the skill's main work:

> "Prior context for this scope:
> - [N] previous [skill] sessions touched this area
> - [Key finding/insight/hypothesis summary]
> - [Any approaching deferred item gates]
>
> Proceeding with [skill workflow]. Let me know if any of this
> context changes your approach."

If no results are found, skip silently and proceed normally.

**Step 3 — Continuation detection.** If prior sessions closely match
the current scope and skill, offer to continue:

> "I found a previous [skill] session on [date] that [describe state].
> Continue from there, or start fresh?"

If the user continues, create a `:continued_from` edge:

```gql
MATCH (current:Session) WHERE id(current) = $session_id
MATCH (prior:Session) WHERE id(prior) = $prior_session_id
INSERT (current)-[:continued_from]->(prior)
```

## Background Annotation

All skills auto-annotate the graph with `:Note` nodes as they work.
This is a background discipline, not a separate invocation:

| Kind | When to create | Example |
|---|---|---|
| `rationale` | Making a judgment call or close decision | "Chose BTreeMap over HashMap for ordered range scans" |
| `observation` | Spotting a pattern or something interesting | "Module B mirrors module A — possible shared abstraction" |
| `todo` | Identifying future work lighter than a DeferredItem | "TODO: add retry logic after transport layer stabilizes" |
| `bookmark` | Noting something to revisit next session | "Revisit this optimization after real-workload benchmarks" |

Attach notes to the most specific target node available (CodeLocation,
Decision, Milestone, etc.) via `:annotates` edges. Link to the current
session via `:produced`.
