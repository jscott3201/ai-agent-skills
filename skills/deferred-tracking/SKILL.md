---
name: deferred-tracking
description: >
  Track deferred work items in a structured DEFERRED.md. Auto-triggers when
  work is deferred during planning or implementation. Invoke manually to
  review and triage the deferred list.
argument-hint: "[review or add]"
---

## Purpose

Prevent deferred work from being forgotten. When a decision is made to defer
something, capture it in a structured format with a verifiable gate condition
so it can be revisited when circumstances change. When invoked manually,
triage the list: identify items ready to tackle, items that are stale, and
items that should be re-prioritized.

**When NOT to use:** The decision is to not do something permanently
(that's a design decision, not deferred work). The item has a tracking
ticket elsewhere (don't duplicate). The user explicitly says to drop it.

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and load current deferred state from the graph:

1. **Create session** with `skill: 'deferred-tracking'` and `scope: $ARGUMENTS`
2. **Load deferred state** — query all active deferred items:

```gql
MATCH (d:DeferredItem)-[:gated_by]->(g:Gate)
WHERE d.stale = false
MATCH (d)<-[:produced]-(s:Session)
WHERE s.project = $project
RETURN d, g, s.date AS added_date
ORDER BY d.priority, s.date
```

3. **Check gate proximity** — for items with temporal or milestone gates,
   evaluate whether conditions are approaching or met.

When SeleneDB is available, it becomes the primary store for deferred items.
`_agentskills/DEFERRED.md` is still written as a human-readable snapshot
but the graph is the source of truth.

If SeleneDB is not available, fall back to `_agentskills/DEFERRED.md` as
the sole store (current behavior).

### Auto-detection: when to capture

This skill auto-triggers when deferral language appears during planning or
implementation. Watch for:

- "out of scope for now", "defer to Phase N", "do that later"
- "not in this release", "future enhancement", "nice to have"
- "blocked on X", "waiting for Y to be resolved first"
- Feature-design non-goals that represent real work deferred (not just
  scope boundaries)
- Items explicitly deprioritized during plan reviews or debates

When detected, capture immediately. Do not wait for the user to ask.

### Adding deferred items

1. Look for `_agentskills/DEFERRED.md`. If it does not exist, create the
   directory and file with this structure:

```markdown
# Deferred Work

**Last updated:** YYYY-MM-DD
**Project:** [project name]

---

## [Category Name]

| # | Item | Priority | Gate | Description | Source | Added |
|---|------|----------|------|-------------|--------|-------|

---

## Summary

| Category | Count | Ready | Stale |
|----------|-------|-------|-------|
| **Total** | **0** | **0** | **0** |
```

2. Add the item to the appropriate category table (create the category
   if it does not exist):

   - **Item:** short name for the deferred work
   - **Priority:** High / Medium / Low based on the classification below
   - **Gate:** what must be true before this is worth doing
   - **Description:** 1-2 sentences on what the work involves
   - **Source:** where this came from (plan name, phase, conversation date)
   - **Added:** date the item was deferred (YYYY-MM-DD)

3. Assign priority using this framework:

   | Priority | Criteria |
   |----------|----------|
   | **High** | Blocks future features, affects correctness, or users have asked for it |
   | **Medium** | Improves performance, DX, or maintainability but nothing blocks on it |
   | **Low** | Nice-to-have, speculative, or only relevant at much larger scale |

4. Update the **Last updated** date and the **Summary** counts.

5. Do not commit files in `_agentskills/` unless the user explicitly asks.

#### Graph write: new item (SeleneDB)

When adding a deferred item and SeleneDB is available:

```gql
INSERT (d:DeferredItem {
  item: $name,
  description: $description,
  priority: $priority,
  category: $category,
  kind: $kind,
  status: 'open',
  source: $source,
  stale: false
})
RETURN id(d) AS item_id

INSERT (g:Gate {
  condition: $gate_condition,
  met: false
})
RETURN id(g) AS gate_id
```

**Kind** classifies the nature of the deferred work:

| Kind | When to use |
|---|---|
| `feature` | Deferred functionality or user-facing capability |
| `bug` | Known issue deferred to a later phase |
| `tech_debt` | Cleanup, refactoring, or structural improvement |
| `research` | Investigation needed before a decision can be made |
| `optimization` | Performance or efficiency improvement |

Link item to gate, session, and any related code or other items:

```gql
MATCH (d:DeferredItem) WHERE id(d) = $item_id
MATCH (g:Gate) WHERE id(g) = $gate_id
INSERT (d)-[:gated_by]->(g)

MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(d)
```

**Tag with topics.** If the deferred item relates to identifiable domain
areas, link to `:Topic` nodes so it surfaces in topic-scoped queries
(e.g., "What's deferred in the query engine?"):

```gql
MERGE (t:Topic {name: $topic_name})
ON CREATE SET t.domain = $domain, t.description = $topic_description

MATCH (d:DeferredItem) WHERE id(d) = $item_id
MATCH (t:Topic {name: $topic_name})
INSERT (d)-[:about]->(t)
```

For relationship tracking (blocks, related to, superseded by), create
edges between `:DeferredItem` nodes:

```gql
MATCH (d:DeferredItem) WHERE id(d) = $item_id
MATCH (other:DeferredItem) WHERE id(other) = $related_id
INSERT (d)-[:blocks]->(other)
```

Still write to `_agentskills/DEFERRED.md` as a human-readable snapshot.

### Gate quality

The gate field is what makes deferred tracking useful. **"Later" is not a
gate.** Gates must be specific and verifiable:

**Good gates:**
- "After Phase 3 (alarms) is complete"
- "When query latency exceeds 10ms at 100K nodes"
- "If a second protocol driver is needed"
- "High effort - requires vectorized execution engine first"
- "When user demand is validated (3+ requests)"
- "Blocked by: upstream API must support pagination"

**Bad gates:**
- "Later", "Eventually", "When we have time"
- "If needed" (needed by whom? under what conditions?)
- "Low priority" (that is a priority, not a gate)

If the deferral reason does not have a clear gate, ask the user to specify
one before recording the item.

### Reviewing deferred items (manual invocation)

When invoked manually (e.g., `/justin-tools:deferred-tracking review`
or `/justin-tools:deferred-tracking`):

#### 1. Load and assess

Read `_agentskills/DEFERRED.md` and assess each item against current
project state.

#### 2. Check gates

For each item, evaluate whether the gate condition has been met:
- **Dependencies:** has the blocking work been completed? Check recent
  commits and project state.
- **Effort:** has the prerequisite capability been built?
- **Demand:** have users or requirements materialized?
- **Scale:** has the threshold been reached?

#### 3. Check staleness

Flag items as stale if:
- Added more than 6 months ago with no gate progress
- The feature or component they relate to has been removed or redesigned
- The gate condition is no longer meaningful (context changed)
- A different approach has superseded the deferred work

#### 4. Triage with user

Present each category **one at a time**, starting with Ready:

**Ready items (gate met):**
For each ready item, present:
- The item, its gate, and why the gate is now met
- Recommended action: tackle now, re-defer with new gate, or remove
- Wait for the user's decision before presenting the next item

#### Graph write: gate evaluation (SeleneDB)

When a gate is evaluated as met:

```gql
MATCH (g:Gate) WHERE id(g) = $gate_id
SET g.met = true, g.met_on = date(), g.evidence = $evidence
```

When the user decides to tackle a ready item, update its status:

```gql
MATCH (d:DeferredItem) WHERE id(d) = $item_id
SET d.status = 'in_progress'
```

**Stale items (recommend removal):**
For each stale item, present:
- The item and why it is stale
- Options: **keep** (with updated gate), **update** (revise scope/gate),
  or **remove**
- Wait for the user's decision before presenting the next item

#### Graph write: staleness triage (SeleneDB)

After each stale item triage decision:

- **keep**: update the gate condition on the `:Gate` node
- **update**: update both `:DeferredItem` and `:Gate` properties
- **remove**: set `d.stale = true` and `d.status = 'wont_do'` on the
  `:DeferredItem` (preserve for history, do not delete from graph)

After Ready and Stale items are triaged, summarize Approaching and Still
Deferred items as a group (these require no immediate decision).

#### 5. Update the file

After review:
- Update the Summary table with current Ready and Stale counts
- Mark stale items (strikethrough or move to a "Removed" section with
  the removal date and reason)
- Update the **Last updated** date

### Relationship tracking

When adding items, note relationships:

- **Blocks:** if this deferred item blocks other deferred items
- **Related to:** if multiple deferred items address the same area
- **Superseded by:** if a newer item replaces an older one

Add these as annotations in the Description field:
`"Add vector search. Related to: #12 (HNSW index). Blocks: #15 (hybrid search)."`

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Categories

Categories should match the project's natural grouping. Common patterns:

- **By phase:** "Phase 3: Alarms", "Phase 4: Analytics"
- **By subsystem:** "Query Engine", "Storage", "Networking"
- **By concern:** "Performance", "Security", "DX", "Infrastructure"
- **By type:** "Features", "Tech Debt", "Research", "Optimization"

Pick one grouping style per project and use it consistently.

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "We'll remember to come back to this" | You won't. The cost of recording is seconds. The cost of forgetting is weeks of re-discovery. |
| "'Later' is a good enough gate" | "Later" is not verifiable. Without a specific condition, the item is a wish, not a plan. |
| "Too many deferred items, stop tracking" | That's a signal to triage, not stop. A long list means decisions are being deferred without review. |
| "This is too small to track" | Small items compound. Three "too small" items become one blocked feature next quarter. |

## Verification

- [ ] Every deferred item has a specific, verifiable gate condition
- [ ] Priority assigned using the High/Medium/Low framework
- [ ] Summary counts updated after changes
- [ ] Relationships noted (blocks, related to, superseded by)

## Red Flags

Stop and reassess if you observe:
- Recording items with vague gates ("later", "eventually", "when we have time")
- Not updating the Summary counts after changes
- Skipping staleness review during manual triage
- Adding items without asking the user for a gate condition

## Guidance

**Capture immediately.** The cost of recording a deferred item is seconds.
The cost of forgetting one is re-discovery weeks or months later.

**Gates are the value.** Without a gate, a deferred item is just a wish
list entry. With a gate, it is a conditional plan that activates when
the condition is met.

**Regular triage keeps the list honest.** Review deferred items at the
start of each major phase. A list that is never reviewed becomes a
graveyard. A list that is reviewed becomes a backlog.

**Stale items should be removed, not ignored.** A deferred item that has
been stale for 6+ months is noise. Remove it or update its gate to
reflect current reality.

**SeleneDB makes gates queryable across skills.** When deep-review defers
a finding, it creates a `:DeferredItem` in the graph. When release-prep
runs, it can check for items gated on "next release." This cross-skill
visibility is impossible with flat-file tracking.
