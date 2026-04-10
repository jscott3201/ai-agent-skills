---
name: notes
description: >
  Background annotation discipline. All skills auto-annotate graph nodes
  with rationale, observations, TODOs, and bookmarks as they work.
  Captures context that feeds into graph-docs documentation generation.
user-invocable: false
---

## Purpose

Background annotation discipline for all skills. Every skill should
auto-annotate graph nodes with context as it works. Notes are the
lightweight counterpart to structured reasoning nodes — they don't
require severity, gates, or categories.

**When to annotate:**
- Making a judgment call or close decision → `rationale` note
- Spotting a pattern or something interesting → `observation` note
- Identifying future work lighter than a DeferredItem → `todo` note
- Noting something to revisit next session → `bookmark` note

**When NOT to use notes:** The item has a verifiable gate condition (use
deferred-tracking). The item is a code review finding with severity
(use deep-review). The item is a full research question (use research).

## Instructions

### Adding notes

When invoked with `add` or when another skill offers a note prompt:

1. **Capture the note content** from `$ARGUMENTS` or the user's input
2. **Classify the kind:**

| Kind | Signal | Example |
|---|---|---|
| `todo` | Action item, "should do", "need to" | "TODO: add retry logic after transport layer is stable" |
| `rationale` | "Because", "chose this since", "reason:" | "Chose BTreeMap over HashMap because keys need ordering for range scans" |
| `observation` | "Noticed", "interesting", "seems like" | "Module B has the same pattern as module A — possible shared abstraction" |
| `bookmark` | "Come back to", "revisit", "check later" | "Revisit this optimization after benchmarks on real workload" |

3. **Identify the target** — what is this note about?
   - A specific file/function → `:CodeLocation`
   - A decision made earlier → `:Decision`
   - A milestone → `:Milestone`
   - A deferred item → `:DeferredItem`
   - The current session (no specific target) → `:Session`
   - A topic area → `:Topic`

4. **Determine author:** `user` if the user wrote the note content,
   `agent` if the agent generated it during a skill workflow.

#### Graph write: new note (SeleneDB)

```gql
INSERT (n:Note {
  content: $content,
  kind: $kind,
  author: $author
})
RETURN id(n) AS note_id

MATCH (n:Note) WHERE id(n) = $note_id
MATCH (target) WHERE id(target) = $target_id
INSERT (n)-[:annotates]->(target)

MATCH (s:Session) WHERE id(s) = $session_id
MATCH (n:Note) WHERE id(n) = $note_id
INSERT (s)-[:produced]->(n)
```

If the target is a code location, use MERGE to reuse existing nodes:

```gql
MERGE (loc:CodeLocation {file: $file, function: $function})
MATCH (n:Note) WHERE id(n) = $note_id
INSERT (n)-[:annotates]->(loc)
```

### Context bridge: share cross-agent notes

When the author is `agent` and the kind is `observation` or `warning`,
check if other agents are active on the project. If so, share the note
via the context bridge so peers benefit from the observation:

```
list_agents(project: "<project>")
```

If active peers exist:

```
share_context(
  author: "<my agent id>",
  context_type: "<'discovery' for observations, 'warning' for warnings>",
  scope: "<project>",
  targets: ["<target file or module if applicable>"],
  content: "<note content>",
  visibility: "project",
  ttl_ms: 86400000
)
```

Do NOT share `todo`, `bookmark`, or `rationale` notes — these are
session-private context that doesn't help other agents. Only share
observations and warnings that affect concurrent work.


### Listing notes

When invoked with `list` or without arguments:

Query notes for the current project, grouped by kind:

```gql
MATCH (n:Note)<-[:produced]-(s:Session)
WHERE s.project = $project
OPTIONAL MATCH (n)-[:annotates]->(target)
RETURN n.content, n.kind, n.author, labels(target) AS target_type,
  s.date
ORDER BY n.kind, s.date DESC
```

Present grouped by kind:

> **TODOs** (N items):
> - [content] — [target] ([date])
>
> **Bookmarks** (N items):
> - [content] — [target] ([date])
>
> **Observations** (N items):
> - [content] — [target] ([date])

Filter options: by kind (`list todos`), by topic (`list notes about auth`),
by target (`list notes on src/query/mod.rs`).

### Triaging notes

When invoked with `triage`:

Review notes one at a time, starting with TODOs:

> **[Kind]:** [content]
> Target: [target] | Added: [date] | Author: [author]
>
> Options:
> 1. **Keep** — still relevant
> 2. **Done** — completed or no longer needed (remove)
> 3. **Promote** — upgrade to a DeferredItem (has a gate) or Finding
> 4. **Update** — change the content

Wait for the user's decision before presenting the next note.

Notes older than 90 days are flagged as potentially stale.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB detection, sessions, auto-recall

## Guidance

**Notes are cheap. Use them.** The cost of a note is one sentence. The
cost of lost context is re-investigating why a decision was made.

**TODOs should graduate or die.** A TODO that survives 2+ triage cycles
should become a DeferredItem with a proper gate. A TODO that's been
done should be removed. Stale TODOs are noise.

**Rationale notes are the most valuable long-term.** "Why we chose X" is
the question that comes up months later. Decisions capture what was chosen;
rationale notes capture the context that made that choice make sense at
the time.

**Agents should annotate, not just decide.** When a skill makes a judgment
call (e.g., "this finding is S3 not S2"), attaching a rationale note
explains the reasoning for future sessions. This is especially valuable
for close calls.

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "I'll remember why we chose this" | You won't. Write the rationale note now. |
| "Too trivial to note" | Trivial observations compound. Three "trivial" notes become the pattern that deep-review promotes to a convention. |
| "Notes are just noise" | Unmanaged notes are noise. Triaged notes are context. The triage command exists for a reason. |

## Verification

- [ ] Note has a clear kind classification
- [ ] Note is attached to a specific target (not floating)
- [ ] Author correctly identified (user vs agent)
- [ ] TODOs reviewed within 90 days
