---
name: agent-bridge
description: >
  Multi-agent coordination via SeleneDB context bridge. Check active peers,
  read shared context, declare work intents, and avoid conflicts when
  multiple agents work simultaneously.
argument-hint: "[peers | context | claim <path> | release | conflicts <path>]"
---

## Purpose

Coordinate with other agents working on the same or related projects via
SeleneDB's context bridge. This skill provides explicit commands for agent
awareness, context sharing, and intent-based conflict avoidance.

**When to use:**
- Starting a session and want to see who else is active
- About to modify files that another agent might be working on
- Discovered something other agents should know about
- Need to check if your planned changes conflict with another agent's work

**When NOT to use:** Normal single-agent work with no concurrent agents.
The session-tracker skill handles auto-registration and heartbeat — this
skill is for explicit coordination actions.

## Prerequisites

Requires the SeleneDB MCP connection with context bridge tools:
`register_agent`, `heartbeat`, `deregister_agent`, `list_agents`,
`share_context`, `get_shared_context`, `claim_intent`, `release_intent`,
`check_conflicts`.

## Instructions

### Checking active peers

When invoked with `peers` or without arguments:

Call the `list_agents` MCP tool to see who's active:

```
list_agents(project: "<current project>")
```

Present results as:

> **Active agents on [project]:**
>
> **[agent_id]** — [working_on]
> Status: [status] | Last heartbeat: [relative time]
> Files: [files_touched]

If no agents are active, report "No other agents currently active on this project."

Also query for recent shared context:

```
get_shared_context(scope: "<current project>", since_ms: <30 minutes ago>)
```

If context exists, summarize:

> **Recent shared context:**
> - [author] ([context_type]): [content summary]

### Reading shared context

When invoked with `context` or `context <scope>`:

```
get_shared_context(
  scope: "<scope or current project>",
  limit: 20
)
```

For targeted queries:

```
get_shared_context(
  scope: "<project>",
  target_prefix: "<path>",
  context_type: "<type>"
)
```

Group by context_type and present chronologically.

### Claiming work intent

When invoked with `claim <path>` or when starting significant file modifications:

1. **Check for conflicts first:**

```
check_conflicts(
  agent_id: "<my agent id>",
  targets: ["<path>"]
)
```

2. **If clear, claim:**

```
claim_intent(
  agent_id: "<my agent id>",
  action: "<description of what I'm doing>",
  targets: ["<path1>", "<path2>"],
  level: "exclusive",
  reason: "<why>"
)
```

3. **Report conflicts** if any exist. If a `locked` intent exists on the
   target, surface this to the user:

> **Conflict detected:** Agent [other_id] has a **locked** claim on
> [path] for: [action]. Recommend waiting or coordinating.

**Intent levels:**
- `advisory` — "I'm working in this area" (default for broad areas)
- `exclusive` — "I'm actively editing these files" (use for specific files)
- `locked` — "Do not touch, migration in progress" (rare, use for destructive ops)

### Releasing intents

When invoked with `release` or when finishing work on claimed files:

```
release_intent(agent_id: "<my agent id>")
```

This releases all claimed intents. To release a specific one:

```
release_intent(agent_id: "<my agent id>", intent_id: <id>)
```

### Sharing discoveries

When you learn something that other agents should know, share it:

```
share_context(
  author: "<my agent id>",
  context_type: "discovery",
  scope: "<project>",
  targets: ["<relevant paths>"],
  content: "<what I learned>",
  visibility: "project"
)
```

**Context types and when to use them:**

| Type | When | Example |
|---|---|---|
| `discovery` | Learned something about the codebase | "The auth module uses Cedar policies, not custom RBAC" |
| `decision` | Made a design choice that affects others | "Using BTreeMap for ordered range scans in the index" |
| `warning` | Found a potential issue | "The test suite takes 5min — avoid running full suite in hot loop" |
| `request` | Need help or input from another agent | "Need someone to review the migration before I commit" |
| `blocker` | Blocked and need resolution | "CI is failing on main — do not merge until fixed" |

### Checking for conflicts before work

When invoked with `conflicts <path>`:

```
check_conflicts(
  agent_id: "<my agent id>",
  targets: ["<path>"]
)
```

Report results clearly. If conflicts exist at `exclusive` or `locked` level,
recommend the user coordinate before proceeding.

## Auto-Behaviors

These happen automatically when context bridge tools are available:

### Session start (handled by session-tracker)
- `register_agent` is called with project and initial working_on
- Recent shared context and active peers are queried

### Periodic heartbeat (handled by session-tracker)
- `heartbeat` is called every ~60s during long-running skills
- Updates working_on and files_touched

### Session end (handled by session-tracker)
- `deregister_agent` releases all intents and marks session done

### On commit (handled by commit-workflow)
- `share_context(type: "decision")` announces the commit to peers

### On notes (handled by notes skill)
- Agent-authored `observation` and `warning` notes are shared via
  `share_context` when they have cross-agent relevance

## Guidance

**Check peers before claiming.** Don't blindly claim intents — first see
who's active and what they're working on. Most of the time a quick `peers`
check is enough.

**Claim narrow, not broad.** Claim the specific files you're editing, not
the entire crate. `crates/selene-gql/src/optimizer/rules/predicate_pushdown.rs`
is better than `crates/selene-gql/`.

**Share discoveries generously.** When you learn something non-obvious about
the codebase, share it. Future agents benefit from your work even after
your session ends (context has TTL but defaults to 24h).

**Don't over-coordinate.** If you're the only active agent, skip the intent
dance. Context bridge adds value with 2+ concurrent agents.

## Agent Identity

Your agent_id should be stable across the session and descriptive:
- Format: `claude-<project>-<instance>` (e.g., `claude-selene-1`, `claude-artemis-2`)
- If working in a team with assigned names, use your team name
- The session-tracker auto-generates this from project + session info

## Verification

- [ ] Checked for active peers before starting significant work
- [ ] Claimed intent before modifying shared files (when peers are active)
- [ ] Released intents after completing claimed work
- [ ] Shared discoveries that affect other agents' work
- [ ] Reported conflicts to user rather than silently proceeding
