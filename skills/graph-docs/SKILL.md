---
name: graph-docs
description: >
  Generate documentation by traversing the SeleneDB graph: milestones,
  design decisions, security concerns, and deferred work. Assembles
  structured docs from graph annotations and relationships.
argument-hint: "[document type: milestone-report | architecture | security-posture | decision-log | deferred-status | full-project]"
disable-model-invocation: true
---

## Purpose

Generate documentation by traversing the property graph rather than
scanning files. The graph contains design decisions with rationale notes,
security concerns with mitigation trails, milestones with commit histories,
and deferred work with gate conditions. This skill assembles those into
structured documents.

**When NOT to use:** Generating API docs from code (no dedicated skill for
this — use standard tooling). Writing new docs from scratch (just write them).

## Instructions

### 0. Context recall

Create a session per [selene-integration.md](../_selene/selene-integration.md).

Query graph stats for the project to understand available data:

```gql
MATCH (n)
WHERE n.project = $project
RETURN labels(n) AS type, count(*) AS total
ORDER BY total DESC
```

### 1. Scope selection

Determine document type from `$ARGUMENTS`. If not specified, ask the user:

| Type | What it generates | Key traversals |
|---|---|---|
| `milestone-report` | Status report for a milestone | milestone→commits→decisions→notes |
| `architecture` | Architecture overview | crates→modules→dependencies→conventions |
| `security-posture` | Security audit summary | security_concerns→affected deps→mitigations |
| `decision-log` | Chronological decision record | design_decisions by date with rationale notes |
| `deferred-status` | Outstanding deferred work | deferred_work with gates and blocking relationships |
| `full-project` | All of the above combined | Full graph traversal for the project |

### 2. Graph traversal

Execute the traversal for the selected document type:

**milestone-report:**
```gql
MATCH (m:Milestone)
WHERE m.project = $project AND m.name = $milestone_name
OPTIONAL MATCH (c:GitCommit)-[:part_of]->(m)
OPTIONAL MATCH (doc:Document)-[:part_of]->(m)
OPTIONAL MATCH (d:Decision)-[:part_of]->(m)
OPTIONAL MATCH (n:Note)-[:annotates]->(m)
RETURN m, collect(DISTINCT c) AS commits,
  collect(DISTINCT doc) AS documents,
  collect(DISTINCT d) AS decisions,
  collect(DISTINCT n) AS notes
```

**architecture:**
```gql
MATCH (cr:crate)-[:belongs_to_project]->(p:project {name: $project})
OPTIONAL MATCH (cr)-[:contains]->(mod:module)
OPTIONAL MATCH (cr)-[:depends_on]->(dep)
OPTIONAL MATCH (conv:Convention {active: true})
WHERE conv.project = $project
RETURN cr, collect(DISTINCT mod) AS modules,
  collect(DISTINCT dep) AS dependencies,
  collect(DISTINCT conv) AS conventions
```

**security-posture:**
```gql
MATCH (sc:SecurityConcern)
WHERE sc.project = $project
OPTIONAL MATCH (sc)-[:affects]->(target)
OPTIONAL MATCH (sc)-[:mitigated_by]->(fix)
RETURN sc.summary, sc.severity, sc.status, sc.category,
  labels(target) AS affected_type, target.name AS affected_name,
  labels(fix) AS fix_type
ORDER BY sc.severity, sc.status
```

**decision-log:**
```gql
MATCH (d:Decision)<-[:produced]-(s:Session)
WHERE s.project = $project
OPTIONAL MATCH (n:Note {kind: 'rationale'})-[:annotates]->(d)
RETURN d.summary, d.rationale, d.alternatives, d.confidence,
  s.date, s.skill, n.content AS extra_rationale
ORDER BY s.date DESC
```

**deferred-status:**
```gql
MATCH (di:DeferredItem)
WHERE di.project = $project AND di.status = 'open'
OPTIONAL MATCH (di)-[:gated_by]->(g:Gate)
OPTIONAL MATCH (di)-[:blocks]->(blocked:DeferredItem)
RETURN di.item, di.description, di.priority, di.kind,
  g.condition, g.met,
  collect(blocked.item) AS blocks
ORDER BY di.priority
```

### 3. Document generation

Render traversal results as structured markdown. Include:

- **Summary section** with key metrics (count of items, completion %)
- **Detail sections** organized by the document type's natural grouping
- **Cross-references** to related graph entities (decisions that led to
  commits, security concerns linked to dependencies)
- **Annotations** from Note nodes (rationale, observations) inline with
  the items they annotate

Present the draft to the user for review before writing.

### 4. Graph write: document node

After the user approves the generated document:

```gql
INSERT (doc:Document {
  project: $project,
  title: $title,
  doc_type: $doc_type,
  content: $markdown_content
})
RETURN id(doc) AS doc_id

MATCH (s:Session) WHERE id(s) = $session_id
MATCH (doc:Document) WHERE id(doc) = $doc_id
INSERT (s)-[:produced]->(doc)
```

Optionally write to a file if the user requests it.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) — SeleneDB detection, sessions, auto-recall
- [selene-patterns.md](../_selene/selene-patterns.md) — write/read patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Just query the graph manually" | Structured docs need assembly logic — traversal, grouping, and cross-referencing. Raw queries dump data, not documentation. |
| "Docs are better written from scratch" | Graph-sourced docs capture what actually happened (decisions, findings, commits). Hand-written docs drift from reality. |

## Verification

- [ ] Correct document type selected
- [ ] All relevant graph data included in traversal
- [ ] Cross-references between entities preserved
- [ ] Annotations (notes) included inline
- [ ] Document node written to graph after user approval
