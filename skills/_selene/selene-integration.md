# SeleneDB Integration Guide

Supporting file for skills that persist reasoning to SeleneDB.
Skills reference this file for detection, session management,
auto-recall, and fallback behavior. Schema and query patterns
are in separate supporting files.

**Supporting files:**
- [selene-schema.md](selene-schema.md) — node types, edge types, property definitions
- [selene-patterns.md](selene-patterns.md) — write patterns, read patterns, rationalization tracking
- [reasoning-schema.gql](reasoning-schema.gql) — GQL DDL statements for schema registration
- [setup-schema.sh](setup-schema.sh) — one-command schema setup script

## Detection

Check whether SeleneDB MCP tools are available before using them.
The user configures SeleneDB as an MCP server in their project or
user settings. Skills detect availability at runtime.

**Detection check:** Attempt to call the `gql_query` tool. If it
exists and responds, SeleneDB is available. Cache this result for
the session.

```
IF gql_query tool is available:
  -> SeleneDB mode: use graph persistence
ELSE:
  -> Fallback mode: use existing behavior (flat files or conversation)
```

Do not prompt the user about SeleneDB availability. If it is not
configured, proceed silently with fallback behavior.

## Session Creation

When a SeleneDB-integrated skill starts and SeleneDB is available,
auto-create a session node before any other graph operations:

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
- `project`: git remote origin URL or working directory basename
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

## Fallback Behavior

When SeleneDB is not available, skills use their existing behavior:

| Skill | SeleneDB Mode | Fallback Mode |
|---|---|---|
| **research** | Graph + `_agentskills/research/` file | `_agentskills/research/` file only |
| **deep-review** | Graph persistence of findings | Conversation only (current behavior) |
| **debug** | Graph persistence of hypotheses + root causes | Conversation only (current behavior) |
| **plan-verify** | Graph persistence of claims + quality gate | Conversation only (current behavior) |
| **release-prep** | Graph persistence of releases + changelog | Conversation only (current behavior) |
| **deferred-tracking** | Graph + `_agentskills/DEFERRED.md` | `_agentskills/DEFERRED.md` only |
| **test-strategy** | Graph persistence of coverage gaps | Test files only (current behavior) |
| **feature-design** | Graph persistence of design decisions + plan | `_agentskills/design/` and `_agentskills/plans/` only |
| **debate** | Graph persistence of perspectives + rulings | `_agentskills/debates/` file only |
| **incident-response** | Graph persistence of incidents + postmortem | `_agentskills/reviews/` file only |
| **refactor** | Graph persistence of smell analysis + decisions | Conversation only (current behavior) |
| **perf-profile** | Graph persistence of baselines + optimizations | `_agentskills/reviews/` file only |
| **modularize** | Graph persistence of structural findings | Conversation only (current behavior) |
| **project-onboard** | Graph persistence of project assessment | Agent persistent memory only |
| **requirements-trace** | Graph persistence of trace gaps + decisions | `_agentskills/reviews/` file only |
| **milestone-tracking** | Graph persistence of milestones + commit links | `_agentskills/milestones.md` only |
| **notes** | Graph persistence of annotations on any node | `_agentskills/NOTES.md` only |
| **session-tracker** | Session summaries + cross-session context queries | `_agentskills/SESSION_LOG.md` only |

In fallback mode:
- Skip session creation
- Skip scoped auto-recall
- Skip all graph write operations
- Proceed with the skill's existing workflow unchanged

The user's experience in fallback mode is identical to the current
skill behavior. SeleneDB is purely additive.
