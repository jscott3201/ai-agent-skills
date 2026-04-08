---
name: session-tracker
description: >
  Track and recall context across sessions. Auto-captures rolling summaries
  as skills complete. Invoke to review session history, search past work,
  or see what happened recently.
argument-hint: "[history | search <query> | timeline]"
---

## Purpose

Maintain continuity across sessions so agents and users can pick up
where they left off. When a session ends (user closes terminal, context
expires), the context is lost — but the graph remembers. This skill
ensures that context is captured incrementally and loaded automatically
when a new session starts.

**When NOT to use:** Looking for a specific finding or decision (use
SeleneDB search directly). Tracking a specific initiative (use
milestone-tracking). The session just started and context was already
loaded by the SessionStart hook.

## How It Works

### Automatic capture (rolling checkpoints)

Every SeleneDB-integrated skill writes a checkpoint when it completes
(see [selene-integration.md](../_selene/selene-integration.md)):

```gql
MATCH (s:Session) WHERE id(s) = $session_id
SET s.outcome = $outcome,
    s.summary = $summary,
    s.next_steps = $next_steps
```

This happens automatically — no user action needed. Each skill writes
what it accomplished and what should happen next. Because checkpoints
are rolling, context is always current even if the session ends abruptly.

### Automatic loading (SessionStart hook)

When a new session starts, the SessionStart hook queries SeleneDB for
recent session context and injects it alongside the skill routing table.
This gives the agent immediate awareness of:
- What was worked on recently (last 3 sessions with summaries)
- Active milestones and their progress
- Approaching deferred item gates
- Open high-severity findings from recent reviews

No user action needed. The agent starts informed.

## Instructions

### Viewing session history

When invoked with `history` or without arguments:

```gql
MATCH (s:Session)
WHERE s.project = $project AND s.summary IS NOT NULL
OPTIONAL MATCH (s)-[:produced]->(n)
RETURN s.date, s.skill, s.scope, s.summary, s.next_steps,
  s.outcome, count(n) AS artifacts_produced
ORDER BY s.date DESC
LIMIT 10
```

Present as a timeline:

> **Session history** (last 10 sessions):
>
> **[date] [skill]** — [outcome]
> [summary]
> Next: [next_steps]
> ([N] artifacts produced)
>
> ---

### Searching past sessions

When invoked with `search <query>`:

```gql
CALL graph.hybridSearch('Session', $query, 10)
YIELD node_id, score
MATCH (s:Session) WHERE id(s) = node_id
WHERE s.project = $project
RETURN s.date, s.skill, s.summary, s.next_steps, score
ORDER BY score DESC
```

This searches across session summaries, scopes, and next_steps. Useful
for "when did we last work on auth?" or "what sessions touched the
query engine?"

### Viewing a session timeline

When invoked with `timeline`:

Query sessions with their linked artifacts to show the full reasoning
chain:

```gql
MATCH (s:Session)
WHERE s.project = $project
MATCH (s)-[:produced]->(n)
RETURN s.date, s.skill, s.summary, labels(n) AS artifact_type,
  CASE
    WHEN n:Decision THEN n.summary
    WHEN n:Finding THEN n.summary
    WHEN n:Insight THEN n.summary
    WHEN n:Hypothesis THEN n.statement
    WHEN n:Note THEN n.content
    ELSE 'artifact'
  END AS artifact_summary
ORDER BY s.date DESC, labels(n)
LIMIT 50
```

Present grouped by session:

> **[date] [skill]:** [summary]
> - Decision: [summary]
> - Finding: [summary]
> - Note: [content]
> Next: [next_steps]

### Cross-session context query

For skills that need to understand what happened recently across all
skills (not just their own):

```gql
MATCH (s:Session)
WHERE s.project = $project AND s.date >= date() - duration('P7D')
OPTIONAL MATCH (s)-[:produced]->(d:Decision)
OPTIONAL MATCH (s)-[:produced]->(f:Finding {severity: 'S1_critical'})
OPTIONAL MATCH (s)-[:produced]->(f2:Finding {severity: 'S2_high'})
RETURN s.date, s.skill, s.summary, s.next_steps,
  collect(DISTINCT d.summary) AS decisions,
  collect(DISTINCT f.summary) AS critical_findings,
  collect(DISTINCT f2.summary) AS high_findings
ORDER BY s.date DESC
```

## Flat-file fallback

When SeleneDB is not available, maintain `_agentskills/SESSION_LOG.md`:

```markdown
# Session Log

## YYYY-MM-DD HH:MM — [skill]
**Scope:** [what was worked on]
**Summary:** [what was accomplished]
**Next steps:** [what to do next]
**Outcome:** [completed | partial | aborted | deferred]

---
```

Append new entries at the top. Keep last 20 entries. The SessionStart
hook reads the top entry when SeleneDB is not available.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB detection, sessions, rolling checkpoints

## Guidance

**Summaries should be specific and actionable.** "Did some work" is
useless. "Researched query optimization, evaluated BTreeMap vs HashMap
vs skip list, recommended BTreeMap for ordered range scans" gives the
next session everything it needs.

**Next steps should be the first thing the next agent reads.** Write
them as if briefing a colleague who just walked in. Include enough
context to start working without re-reading the entire session.

**Don't over-capture.** The graph already stores decisions, findings,
hypotheses, and notes. The session summary is a narrative thread that
connects them — not a duplicate of every artifact.

**Cross-session queries are the multiplier.** A single skill's auto-recall
shows "what debug found before." Cross-session context shows "debug found
a race condition, deep-review flagged the same module, and there's a
deferred item about concurrency." That's the full picture.

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "The graph already captures everything" | Nodes capture what happened. Summaries capture the narrative — what it means and what's next. |
| "I'll remember what I was working on" | You might. The agent won't. Session summaries are for agent continuity, not human memory. |
| "Summary is too vague to be useful" | Then write a better one. Specific summaries are the highest-leverage thing a session can produce. |

## Verification

- [ ] Session summary is specific (mentions concrete artifacts, not vague descriptions)
- [ ] Next steps are actionable (a new agent could start from them)
- [ ] History query returns recent sessions with summaries
- [ ] SessionStart hook injects context when SeleneDB is available
