---
name: milestone-tracking
description: >
  Track development milestones that group commits, documents, and decisions
  into named initiatives. Auto-suggests linking commits to active milestones.
  Use to create, review, or close milestones.
argument-hint: "[create | review | close]"
---

## Purpose

Bridge the gap between individual commits and the project roadmap. Milestones
group 5-25 commits into a named initiative with start/end dates, crates or
modules touched, and documents produced. This is the right abstraction level
for cross-session context: "What happened in the auth rewrite?" is a milestone
query, not a git log.

**When NOT to use:** Tracking a single bug fix or small change (that's just
a commit). Tracking the entire project roadmap (use project planning tools).
Tracking deferred work items (use deferred-tracking).

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and load active milestones:

1. **Create session** with `skill: 'milestone-tracking'` and `scope: $ARGUMENTS`
2. **Load active milestones:**

```gql
MATCH (m:Milestone)
WHERE m.status IN ['planned', 'in_progress']
OPTIONAL MATCH (c:GitCommit)-[:part_of]->(m)
OPTIONAL MATCH (doc:Document)-[:part_of]->(m)
RETURN m, count(DISTINCT c) AS commits, count(DISTINCT doc) AS documents
ORDER BY m.started_on DESC
```

3. Present active milestones as context before proceeding.


### Auto-detection: commit linking

This skill auto-triggers when commits are made while milestones are active.
Watch for:

- A commit was just created (commit-workflow context)
- There is at least one milestone with `status: 'in_progress'`
- The commit touches files in areas related to the milestone

When detected, suggest linking:

> "Active milestone: **[milestone name]** ([N] commits so far).
> This commit touches [files/modules]. Link it to this milestone?
>
> 1. **Yes** — link this commit
> 2. **No** — not part of this milestone
> 3. **Different milestone** — link to [other active milestone]"

Wait for the user's decision. Do not auto-link without confirmation.

#### Graph write: commit linking (SeleneDB)

```gql
MERGE (c:GitCommit {sha: $full_sha})
ON CREATE SET c.short_sha = $short_sha, c.message = $commit_message,
  c.author = $author, c.date = date(), c.branch = $branch,
  c.files_changed = $file_count

MATCH (m:Milestone) WHERE id(m) = $milestone_id
INSERT (c)-[:part_of]->(m)
```

### Creating milestones (manual or from feature-design)

When invoked with `create` or when feature-design produces a plan:

1. **Gather metadata:**
   - **Name:** short initiative name (e.g., "Auth middleware rewrite")
   - **Description:** 1-2 sentences on scope
   - **Target date:** expected completion (optional)
   - **Topics:** domain areas this milestone covers

2. **Create the milestone:**

#### Graph write: new milestone (SeleneDB)

```gql
INSERT (m:Milestone {
  name: $name,
  description: $description,
  status: 'planned',
  target_date: $target_date
})
RETURN id(m) AS milestone_id
```

Link to session and topics:

```gql
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (m:Milestone) WHERE id(m) = $milestone_id
INSERT (s)-[:produced]->(m)

MERGE (t:Topic {name: $topic_name})
ON CREATE SET t.domain = $domain
MATCH (m:Milestone) WHERE id(m) = $milestone_id
MATCH (t:Topic {name: $topic_name})
INSERT (m)-[:about]->(t)
```

If a plan document exists, link it:

```gql
MATCH (doc:Document) WHERE id(doc) = $plan_doc_id
MATCH (m:Milestone) WHERE id(m) = $milestone_id
INSERT (doc)-[:part_of]->(m)
```

3. **Start the milestone** when work begins:

```gql
MATCH (m:Milestone) WHERE id(m) = $milestone_id
SET m.status = 'in_progress', m.started_on = date()
```

### Reviewing milestones

When invoked with `review` or without arguments:

#### 1. Load milestone state

Query all milestones with their linked artifacts:

```gql
MATCH (m:Milestone)
WHERE m.status IN ['planned', 'in_progress']
OPTIONAL MATCH (c:GitCommit)-[:part_of]->(m)
OPTIONAL MATCH (doc:Document)-[:part_of]->(m)
OPTIONAL MATCH (d:Decision)-[:part_of]->(m)
OPTIONAL MATCH (m)-[:about]->(t:Topic)
RETURN m, collect(DISTINCT c) AS commits,
  collect(DISTINCT doc) AS documents,
  collect(DISTINCT d) AS decisions,
  collect(DISTINCT t.name) AS topics
ORDER BY m.status, m.started_on DESC
```

#### 2. Present each milestone

For each active milestone, present:
- Name, status, dates (started, target, elapsed)
- Commit count and recent commit messages
- Documents produced
- Decisions made
- Topics covered

Present one milestone at a time. For each:

> "**[Milestone name]** — [status] since [date]
> [N] commits, [N] documents, [N] decisions
> Topics: [topic list]
>
> Recent commits:
> - [short_sha] [message]
> - [short_sha] [message]
>
> Options:
> 1. **Continue** — milestone is on track
> 2. **Close** — work is complete
> 3. **Abandon** — work was dropped or superseded
> 4. **Update** — change target date or description"

Wait for the user's decision before presenting the next milestone.

#### 3. Check for stale milestones

Flag milestones as potentially stale if:
- `in_progress` with no commits in the last 30 days
- Past `target_date` with no completion
- `planned` for more than 60 days without starting

### Closing milestones

When invoked with `close` or when the user chooses "Close" during review:

1. **Summarize the milestone:**
   - Date range (started → completed)
   - Total commits, documents, decisions
   - Topics covered
   - Key outcomes (from linked decisions and documents)

2. **Link any unlinked recent commits** — check recent git history for
   commits that should have been linked but weren't.

3. **Check for deferred items** — query `:DeferredItem` nodes linked to
   the same topics. Present any that were created during this milestone
   but not resolved.

#### Graph write: close milestone (SeleneDB)

```gql
MATCH (m:Milestone) WHERE id(m) = $milestone_id
SET m.status = 'completed', m.completed_on = date()
```

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB detection, sessions, auto-recall

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Too small for a milestone" | If it spans 5+ commits and multiple sessions, it's a milestone. The cost of tracking is low; the cost of losing cross-session context is high. |
| "Skip commit linking, we can figure it out from git log" | Git log shows what changed, not why or what initiative it belonged to. The milestone context is what makes commits meaningful. |
| "Don't close it yet, there might be more work" | Close it. If more work comes, create a new milestone. Open milestones that never close become meaningless. |
| "Just one big milestone for the whole project" | That's a project, not a milestone. Milestones are 5-25 commits. If it's bigger, decompose. |

## Red Flags

Stop and reassess if you observe:
- Milestones with 50+ commits (too coarse — should be split)
- Milestones open for 3+ months (stale or too broad)
- Auto-linking commits without user confirmation
- Creating milestones for single-commit changes

## Verification

- [ ] Milestone has a clear name and description
- [ ] Target date set when applicable
- [ ] Topics tagged for cross-skill discovery
- [ ] Commits linked with user confirmation
- [ ] Milestone closed with summary when work completes

## Guidance

**Milestones are the cross-session unit.** A commit is too small to carry
context across sessions. A project is too large. Milestones are the sweet
spot: they answer "what was I working on?" when you return after a week.

**Close milestones aggressively.** An open milestone with no activity is
noise. Close it when the initiative is done, even if tangential work
continues. New work gets a new milestone.

**Topic linking is the multiplier.** A milestone tagged with topics becomes
discoverable from research ("What milestones touched auth?"), deferred
tracking ("What milestones relate to this deferred item?"), and future
feature design ("What past milestones covered this area?").

**SeleneDB makes milestone queries instant.** "What's the blast radius of
changing module X?" becomes: find milestones about X, find their commits,
find what other modules those commits touched. This is a graph traversal,
not a git archaeology expedition.
