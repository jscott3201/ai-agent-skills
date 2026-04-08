# SeleneDB Write & Read Patterns

How skills write reasoning to the graph and query prior context.

All project-specific nodes carry `project: $project`. Include it in
every INSERT. For MERGE operations on shared nodes like Topics, include
`project` only when scoping to a single project.

## Write Patterns

Skills write to the graph at **decision points** — moments when the
user makes a triage decision or when a reasoning step resolves.

### General pattern

```gql
// 1. Create the reasoning node
INSERT (n:Finding {
  project: $project,
  summary: $summary,
  severity: $severity,
  category: $category,
  why_it_matters: $impact,
  suggested_fix: $fix,
  triage: $user_decision
})
RETURN id(n) AS node_id

// 2. Link to session
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (n:Finding) WHERE id(n) = $node_id
INSERT (s)-[:produced]->(n)

// 3. Link to code location (if applicable)
MERGE (loc:CodeLocation {project: $project, file: $file, function: $function})
INSERT (n)-[:affects]->(loc)

// 4. Link to parent document (if applicable)
MATCH (d:Document) WHERE id(d) = $doc_id
INSERT (d)-[:contains]->(n)
```

### Decision point triggers by skill

| Skill | Write Trigger | What Gets Written |
|---|---|---|
| **research** | User approves synthesis, checkpoint | :Document, :Insight nodes |
| **deep-review** | User triages each finding (fix/skip/defer) | :Finding with triage decision |
| **debug** | Hypothesis confirmed/eliminated, root cause found | :Hypothesis, :RootCause chain |
| **plan-verify** | User accepts/adjusts each inaccuracy, quality gate | :PlanClaim, quality gate decision |
| **release-prep** | Version bump confirmed, changelog approved | :Release, changelog entries |
| **deferred-tracking** | Item added, gate evaluated, item triaged | :DeferredItem, :Gate |
| **test-strategy** | Test group accepted/skipped, coverage gaps found | :CoverageGap, test plan decisions |
| **feature-design** | Design decision confirmed, plan written, non-goals stated | :Decision, :Document (plan/design) |
| **debate** | Perspectives scored, ruling made, residual disagreements | :Perspective, :Decision (ruling), :Document |
| **incident-response** | Severity assessed, mitigation chosen, postmortem written | :Incident, :Decision (mitigation), :Document |
| **refactor** | Smell identified, transformation plan approved | :Decision (smell + approach) |
| **perf-profile** | Baseline established, optimization measured | :Insight (baseline), :Decision (optimization) |
| **modularize** | Finding triaged (include/skip/defer) | :Decision, :DeferredItem |
| **project-onboard** | Setup step approved | :Insight (assessment), :Decision (setup) |
| **requirements-trace** | Gap triaged (address/accept/defer) | :Finding, :Decision, :DeferredItem |
| **safety-checks** | Security concern triaged, mitigation applied | :SecurityConcern, :Decision (mitigation) |
| **dep-audit** | Dependency audited, vulnerability found | :SecurityConcern (via :affects Dependency) |
| **code-standards** | Convention violation found, convention promoted | :Finding (violation), :Convention (promotion) |

### Security concern tracking

When a security audit or dependency review discovers a concern:

```gql
// Create security concern
INSERT (sc:SecurityConcern {
  project: $project,
  summary: $summary,
  severity: $severity,
  status: 'open',
  category: $category,
  found_date: date(),
  cve: $cve,
  audit_session: $session_id
})
RETURN id(sc) AS concern_id

// Link to session
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (sc:SecurityConcern) WHERE id(sc) = $concern_id
INSERT (s)-[:produced]->(sc)

// Link to affected dependency
MATCH (sc:SecurityConcern) WHERE id(sc) = $concern_id
MATCH (d:dependency {name: $dep_name})
INSERT (sc)-[:affects]->(d)

// Link to affected code location
MERGE (loc:CodeLocation {project: $project, file: $file, function: $function})
MATCH (sc:SecurityConcern) WHERE id(sc) = $concern_id
INSERT (sc)-[:affects]->(loc)
```

When a concern is mitigated by a commit or decision:

```gql
// Mitigated by a fixing commit
MATCH (sc:SecurityConcern) WHERE id(sc) = $concern_id
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET c.project = $project, c.short_sha = $short_sha,
  c.message = $commit_message, c.author = $author, c.date = date(),
  c.branch = $branch
INSERT (sc)-[:mitigated_by]->(c)
SET sc.status = 'mitigated'

// Accepted risk via decision
MATCH (sc:SecurityConcern) WHERE id(sc) = $concern_id
MATCH (d:Decision) WHERE id(d) = $decision_id
INSERT (sc)-[:mitigated_by]->(d)
SET sc.status = 'accepted'
```

### Dependency audit linking

When dep-audit evaluates a dependency:

```gql
// Update or create dependency node (cross-cutting, no project property)
MERGE (d:dependency {name: $dep_name})
ON CREATE SET d.version = $version, d.security_relevant = $is_security_relevant

// Link to session
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (d:dependency {name: $dep_name})
INSERT (s)-[:produced]->(d)
```

### Commit linking

When a skill produces reasoning that is later implemented via a git
commit, link the commit to the reasoning nodes it addresses. Any skill
that creates or verifies commits can write `:GitCommit` nodes.

**After a commit that implements a decision or plan:**

```gql
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET
  c.project = $project,
  c.short_sha = $short_sha,
  c.message = $commit_message,
  c.author = $author,
  c.date = date(),
  c.branch = $branch,
  c.files_changed = $file_count

MATCH (d:Decision) WHERE id(d) = $decision_id
INSERT (d)-[:implemented_by]->(c)
```

**After a commit that fixes a finding or root cause:**

```gql
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET c.project = $project, c.short_sha = $short_sha,
  c.message = $commit_message, c.author = $author, c.date = date(),
  c.branch = $branch

MATCH (f:Finding) WHERE id(f) = $finding_id
INSERT (f)-[:fixed_by]->(c)
```

**When an incident is correlated with a commit:**

```gql
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET c.project = $project, c.short_sha = $short_sha,
  c.message = $commit_message, c.author = $author, c.date = date(),
  c.branch = $branch

MATCH (i:Incident) WHERE id(i) = $incident_id
INSERT (i)-[:introduced_by]->(c)
```

`MERGE` on sha ensures each commit is a single node even when linked
from multiple reasoning artifacts.

### Rationalization tracking

When a skill detects that it is about to follow an anti-rationalization
pattern (from its Common Rationalizations table), record the catch:

```gql
INSERT (r:Rationalization {
  project: $project,
  pattern: $rationalization_text,
  skill: $skill_name,
  corrective_action: $what_was_done_instead
})
RETURN id(r) AS rat_id

// Link to session
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (r:Rationalization) WHERE id(r) = $rat_id
INSERT (s)-[:observed_in]->(r)
```

### Topic tagging

When a skill produces a document or insight that covers identifiable
domain areas, tag it with `:Topic` nodes. Use MERGE so topics accumulate
across sessions rather than duplicating.

Topics can be project-scoped or shared. Omit `project` for concepts
that bridge projects (e.g., `'performance'`, `'auth'`). Include
`project` for project-specific topics (e.g., `'gql-parser'`).

```gql
// Create or match topic (shared, cross-project)
MERGE (t:Topic {name: $topic_name})
ON CREATE SET t.domain = $domain, t.description = $topic_description

// Or create a project-scoped topic
MERGE (t:Topic {name: $topic_name, project: $project})
ON CREATE SET t.domain = $domain, t.description = $topic_description

// Link document to topic
MATCH (doc:Document) WHERE id(doc) = $doc_id
MATCH (t:Topic {name: $topic_name})
INSERT (doc)-[:about]->(t)
```

Topic names should be lowercase, specific, and reusable across sessions:
`'embeddings'`, `'auth-middleware'`, `'query-optimization'`, `'ci-pipeline'`.
Domains are broad groupings: `'infrastructure'`, `'security'`, `'ml'`,
`'database'`, `'api'`, `'frontend'`.

### Artifact linking with :informs

When a downstream artifact (plan, decision) was informed by an upstream
artifact (research document, insight), create an `:informs` edge. This
makes the provenance chain queryable.

```gql
MATCH (upstream:Document) WHERE id(upstream) = $research_doc_id
MATCH (downstream:Document) WHERE id(downstream) = $plan_doc_id
INSERT (upstream)-[:informs]->(downstream)
```

Skills that create `:informs` edges:
- **feature-design**: links prior research documents to the plan it produces
- **research**: links insights to decisions they inform (via `:based_on`,
  but `:informs` is used for document-to-document provenance)

### Notes

Attach free-form annotations to any graph node. Notes capture context
that doesn't fit structured types: triage rationale, TODOs, observations,
and bookmarks for revisiting later.

```gql
// Create note and link to target
INSERT (n:Note {
  project: $project,
  content: $content,
  kind: $kind,
  author: $author
})
RETURN id(n) AS note_id

MATCH (n:Note) WHERE id(n) = $note_id
MATCH (target) WHERE id(target) = $target_id
INSERT (n)-[:annotates]->(target)

// Link to session
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (n:Note) WHERE id(n) = $note_id
INSERT (s)-[:produced]->(n)
```

Note kinds:

| Kind | When to use |
|---|---|
| `todo` | Action item to come back to (lighter than a DeferredItem) |
| `rationale` | Why a decision was made — captures triage reasoning |
| `observation` | Something noticed but not actionable yet |
| `bookmark` | "Come back to this" marker for future sessions |

### Convention graduation

When deep-review detects a recurring pattern (same finding category and
similar summary across 3+ sessions), promote it to a convention:

```gql
INSERT (c:Convention {
  project: $project,
  rule: $rule_statement,
  scope: $scope,
  severity: $severity,
  rationale: $rationale,
  source: $source_description,
  active: true
})
RETURN id(c) AS convention_id

// Link to session that promoted it
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (c:Convention) WHERE id(c) = $convention_id
INSERT (s)-[:produced]->(c)

// Link to the findings that triggered promotion
MATCH (f:Finding) WHERE id(f) IN $finding_ids
MATCH (c:Convention) WHERE id(c) = $convention_id
INSERT (c)-[:promoted_from]->(f)
```

### Milestone lifecycle

Create a milestone when a plan is produced (usually from feature-design):

```gql
INSERT (m:Milestone {
  project: $project,
  name: $milestone_name,
  description: $description,
  status: 'planned',
  target_date: $target_date
})
RETURN id(m) AS milestone_id

// Link the plan document to the milestone
MATCH (doc:Document) WHERE id(doc) = $plan_doc_id
MATCH (m:Milestone) WHERE id(m) = $milestone_id
INSERT (doc)-[:part_of]->(m)
```

Link commits to an active milestone:

```gql
MATCH (m:Milestone) WHERE id(m) = $milestone_id
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET c.project = $project, c.short_sha = $short_sha,
  c.message = $commit_message, c.author = $author, c.date = date(),
  c.branch = $branch
INSERT (c)-[:part_of]->(m)
```

Transition milestone status:

```gql
// Start
MATCH (m:Milestone) WHERE id(m) = $milestone_id
SET m.status = 'in_progress', m.started_on = date()

// Complete
MATCH (m:Milestone) WHERE id(m) = $milestone_id
SET m.status = 'completed', m.completed_on = date()
```

## Read Patterns

### Common queries skills use

All read queries filter by `project` unless performing cross-project
aggregation. The `$project` variable is set by the skill at session start.

**Recent session context (for session start bootstrap):**
```gql
MATCH (s:Session)
WHERE s.project = $project AND s.summary IS NOT NULL
RETURN s.skill, s.scope, s.summary, s.next_steps,
  s.outcome, s.date
ORDER BY s.date DESC
LIMIT 3
```

**Prior findings for a code location:**
```gql
MATCH (f:Finding)-[:affects]->(loc:CodeLocation)
WHERE loc.project = $project AND loc.file = $file
MATCH (f)<-[:produced]-(s:Session)
RETURN f.summary, f.severity, f.triage, s.date
ORDER BY s.date DESC
LIMIT 5
```

**Hypothesis history for a module:**
```gql
MATCH (h:Hypothesis)<-[:produced]-(s:Session)
MATCH (h)-[:affects]->(loc:CodeLocation)
WHERE loc.project = $project AND loc.module = $module
RETURN h.statement, h.conclusion, s.date
ORDER BY s.date DESC
```

**Deferred items with approaching gates:**
```gql
MATCH (d:DeferredItem)-[:gated_by]->(g:Gate)
WHERE d.project = $project AND g.met = false AND d.stale = false
RETURN d.item, d.priority, g.condition
ORDER BY d.priority
```

**Decision chain for a feature:**
```gql
MATCH path = (d1:Decision)-[:led_to]->{1,5}(dn:Decision)
WHERE d1.project = $project AND d1.summary CONTAINS $feature_keyword
RETURN path
```

**Cross-session reasoning evolution:**
```gql
MATCH chain = (s1:Session)-[:continued_from]->{1,10}(sn:Session)
WHERE s1.project = $project AND s1.scope CONTAINS $scope_keyword
MATCH (s1)-[:produced]->(node)
RETURN s1.date, s1.skill, collect(node) AS reasoning
ORDER BY s1.date
```

**Rationalization frequency:**
```gql
MATCH (r:Rationalization)
WHERE r.project = $project
RETURN r.pattern, r.skill, count(*) AS times_caught
ORDER BY times_caught DESC
```

**Decision-to-commit traceability:**
```gql
MATCH (d:Decision)-[:implemented_by]->(c:GitCommit)
WHERE d.project = $project
RETURN d.summary, c.short_sha, c.message, c.date
ORDER BY c.date DESC
```

**Commits that later caused incidents:**
```gql
MATCH (i:Incident)-[:introduced_by]->(c:GitCommit)
MATCH (d:Decision)-[:implemented_by]->(c)
WHERE i.project = $project
RETURN i.title, i.severity, c.short_sha, d.summary AS original_decision
```

**What research exists about a topic:**
```gql
MATCH (doc:Document)-[:about]->(t:Topic {name: $topic_name})
WHERE doc.project = $project
MATCH (doc)<-[:produced]-(s:Session)
RETURN doc.title, doc.doc_type, s.date, s.skill
ORDER BY s.date DESC
```

**What topics does a document cover:**
```gql
MATCH (doc:Document)-[:about]->(t:Topic)
WHERE id(doc) = $doc_id
RETURN t.name, t.domain, t.project
```

**Provenance chain (what informed a plan):**
```gql
MATCH (upstream:Document)-[:informs]->(plan:Document {doc_type: 'plan'})
WHERE id(plan) = $plan_id
RETURN upstream.title, upstream.doc_type
```

**Notes attached to a node:**
```gql
MATCH (n:Note)-[:annotates]->(target)
WHERE id(target) = $target_id
MATCH (n)<-[:produced]-(s:Session)
RETURN n.content, n.kind, n.author, s.date
ORDER BY s.date DESC
```

**All open TODOs for a project:**
```gql
MATCH (n:Note {kind: 'todo'})
WHERE n.project = $project
OPTIONAL MATCH (n)-[:annotates]->(target)
RETURN n.content, labels(target) AS target_type
ORDER BY n.created_at DESC
```

**Notes by topic (via annotated node's :about edge):**
```gql
MATCH (n:Note)-[:annotates]->(target)-[:about]->(t:Topic {name: $topic})
WHERE n.project = $project
RETURN n.content, n.kind, labels(target) AS target_type
```

**Active conventions for a scope:**
```gql
MATCH (c:Convention {active: true})
WHERE c.project = $project AND c.scope = $scope
RETURN c.rule, c.severity, c.rationale
ORDER BY c.severity
```

**Recurring findings (graduation candidates):**
```gql
MATCH (f:Finding)
WHERE f.project = $project AND f.triage = 'fix_now'
WITH f.category AS cat, f.summary AS summary, count(*) AS occurrences,
  collect(id(f)) AS finding_ids
WHERE occurrences >= 3
RETURN cat, summary, occurrences, finding_ids
ORDER BY occurrences DESC
```

**Convention provenance (which findings led to it):**
```gql
MATCH (c:Convention)-[:promoted_from]->(f:Finding)
WHERE id(c) = $convention_id
MATCH (f)<-[:produced]-(s:Session)
RETURN f.summary, f.severity, s.date
ORDER BY s.date
```

**Active milestones with progress:**
```gql
MATCH (m:Milestone {status: 'in_progress'})
WHERE m.project = $project
OPTIONAL MATCH (c:GitCommit)-[:part_of]->(m)
OPTIONAL MATCH (doc:Document)-[:part_of]->(m)
RETURN m.name, m.started_on, m.target_date,
  count(DISTINCT c) AS commits, count(DISTINCT doc) AS documents
```

**What belongs to a milestone:**
```gql
MATCH (n)-[:part_of]->(m:Milestone) WHERE id(m) = $milestone_id
RETURN labels(n) AS type, n
ORDER BY n.date DESC
```

**Deferred items by topic:**
```gql
MATCH (d:DeferredItem)-[:about]->(t:Topic {name: $topic_name})
WHERE d.project = $project AND d.status = 'open'
RETURN d.item, d.priority, d.kind
ORDER BY d.priority
```

**Unlinked findings (fixed but no commit recorded):**
```gql
MATCH (f:Finding {triage: 'fix_now'})
WHERE f.project = $project
  AND NOT EXISTS { MATCH (f)-[:fixed_by]->(:GitCommit) }
RETURN f.summary, f.severity
```

**Open security concerns for a project:**
```gql
MATCH (sc:SecurityConcern)
WHERE sc.project = $project AND sc.status = 'open'
OPTIONAL MATCH (sc)-[:affects]->(target)
RETURN sc.summary, sc.severity, sc.category, sc.cve,
  labels(target) AS affected_type, target.name AS affected_name
ORDER BY sc.severity
```

**Dependencies with unmitigated concerns:**
```gql
MATCH (sc:SecurityConcern)-[:affects]->(d:dependency)
WHERE sc.project = $project AND sc.status = 'open'
RETURN d.name, d.version, collect(sc.summary) AS concerns,
  collect(sc.severity) AS severities
ORDER BY d.name
```

**Security posture summary (concerns by status):**
```gql
MATCH (sc:SecurityConcern)
WHERE sc.project = $project
RETURN sc.status, sc.severity, count(*) AS total
ORDER BY sc.status, sc.severity
```

**Concern mitigation trail:**
```gql
MATCH (sc:SecurityConcern)-[:mitigated_by]->(fix)
WHERE sc.project = $project
RETURN sc.summary, sc.severity, labels(fix) AS fix_type,
  fix.message AS commit_msg, fix.summary AS decision_summary
```

**Active conventions for code-standards enforcement:**
```gql
MATCH (c:Convention {active: true})
WHERE c.project = $project
  AND (c.scope = $language OR c.scope = 'all' OR c.scope = 'prose')
RETURN c.rule, c.severity, c.rationale, c.scope
ORDER BY c.severity
```

### Cross-project queries

Omit the `WHERE n.project = $project` filter to aggregate across projects.

**Activity across all projects:**
```gql
MATCH (s:Session)
WHERE s.summary IS NOT NULL
RETURN s.project, s.skill, s.scope, s.summary, s.date
ORDER BY s.date DESC
LIMIT 10
```

**Shared topics bridging projects:**
```gql
MATCH (doc:Document)-[:about]->(t:Topic)<-[:about]-(doc2:Document)
WHERE doc.project <> doc2.project
RETURN t.name, doc.project, doc2.project, doc.title, doc2.title
```

**Cross-project convention comparison:**
```gql
MATCH (c:Convention {active: true})
RETURN c.project, c.scope, c.rule, c.severity
ORDER BY c.project, c.scope
```
