---
name: skill-guide
description: >
  Find the right skill for a task. Routes via graph queries on skill and
  workflow_category nodes. Use when unsure which skill applies or to
  recommend skills the user may not know about.
---

## Purpose

Help discover and select the right skill for the current task. This plugin
has 24 graph-native skills — this guide routes by what you're trying to
accomplish. Every skill reads from and writes to SeleneDB.

Skills marked **(auto)** trigger automatically from their descriptions.
Skills marked **(manual)** require `/justin-tools:<name>` to invoke.
Skills marked **(background)** apply silently during all work.

**When NOT to use:** You already know which skill to use (just use it).
The user invoked a specific skill by name. The task doesn't match any
skill (not everything needs a skill — sometimes just write the code).

## Graph-Based Routing

When SeleneDB is available, query the skill catalog from the graph:

```gql
MATCH (s:skill)-[:belongs_to]->(wc:workflow_category)
RETURN wc.name AS category, collect(s.name) AS skills
ORDER BY wc.name
```

This ensures routing always reflects the current plugin state.

## Routing by Task

### Planning and design

| Task | Skill | Invocation |
|---|---|---|
| Plan a feature from idea to implementation | **feature-design** | manual |
| Research a technology, evaluate options | **research** | manual |
| Evaluate a decision with structured debate | **debate** | manual |
| Verify a plan against the actual codebase | **plan-verify** | auto |

### Building

| Task | Skill | Invocation |
|---|---|---|
| Restructure a codebase into well-organized modules | **modularize** | manual |
| Refactor code safely with verification at each step | **refactor** | manual |
| Apply language-specific coding standards + graph conventions | **code-standards** | auto |

### Debugging and performance

| Task | Skill | Invocation |
|---|---|---|
| Systematically debug a bug with hypotheses and root cause | **debug** | auto |
| Investigate performance: profile, hypothesize, optimize | **perf-profile** | manual |
| Triage a production incident with structured response | **incident-response** | manual |

### Review and security

| Task | Skill | Invocation |
|---|---|---|
| Deep review after completing a feature or phase | **deep-review** | auto |
| Security audit with graph-persisted concerns | **safety-checks** | auto |
| Audit a dependency before adoption (supply chain) | **dep-audit** | auto |

### Releasing

| Task | Skill | Invocation |
|---|---|---|
| Prepare a release: changelog, semver, version bump | **release-prep** | manual |
| Verify requirements have corresponding code and tests | **requirements-trace** | manual |

### Tracking

| Task | Skill | Invocation |
|---|---|---|
| Track development milestones across sessions | **milestone-tracking** | auto |
| Track deferred work items with gates | **deferred-tracking** | auto |
| Review session history and search past work | **session-tracker** | auto |
| Link commits to milestones and decisions | **commit-workflow** | background |

### Documentation

| Task | Skill | Invocation |
|---|---|---|
| Generate docs from graph traversal | **graph-docs** | manual |
| Onboard a new project for use with this plugin | **project-onboard** | manual |

### Background

| Rule | Skill |
|---|---|
| Auto-annotate with rationale, observations, TODOs | **notes** |
| Route tasks to the right skill | **skill-guide** |

## Choosing Between Similar Skills

| Situation | Use this | Not this |
|---|---|---|
| Restructure files and modules | **modularize** | refactor |
| Refactor within a file (extract function) | **refactor** | modularize |
| Review code after building a feature | **deep-review** | code-standards |
| Check coding style during development | **code-standards** | deep-review |
| Plan a new feature end-to-end | **feature-design** | research |
| Investigate a technology or compare options | **research** | feature-design |
| Debug a specific bug | **debug** | perf-profile |
| Investigate why something is slow | **perf-profile** | debug |
| Production is down, need triage now | **incident-response** | debug |
| Track a named initiative across sessions | **milestone-tracking** | deferred-tracking |
| Track individual deferred items with gates | **deferred-tracking** | milestone-tracking |
| Generate docs from graph data | **graph-docs** | project-onboard |

## Agents

Agents are specialized subprocesses with preloaded skills and tool restrictions.

| Agent | Purpose | Key skills |
|---|---|---|
| **deep-reviewer** | Code review (read-only) | deep-review |
| **security-auditor** | Security audit (read-only) | safety-checks |
| **code-analyzer** | Modularization analysis (read-only) | modularize, code-standards |
| **test-engineer** | Test planning and generation | test-strategy |
| **debugger** | Systematic debugging | debug, safety-checks |
| **researcher** | Technical research and evaluation | research |
| **release-manager** | Release preparation | release-prep, graph-docs |
| **onboarder** | Project onboarding | project-onboard |
| **debate-lead** | Multi-perspective debate | debate |

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "User didn't ask for a skill, don't suggest one" | Proactive recommendation is the point. Users don't know what 24 skills do — surface the right one. |
| "Close enough, recommend the similar skill" | Similar skills have different scopes. debug vs perf-profile, modularize vs refactor — wrong pick wastes setup time. |

## Verification

- [ ] Task correctly categorized by workflow phase
- [ ] Recommended skill matches the task (not a similar-sounding alternative)
- [ ] Disambiguation provided when multiple skills could apply
- [ ] Agent vs main-conversation recommendation appropriate for scope

## Guidance

**Recommend proactively.** When you see a user working on a task that matches
a manual skill, suggest it. The user may not know the skill exists.

**Auto skills handle themselves.** Don't invoke auto skills explicitly unless
the user asks.

**Background rules are always active.** Never invoke them as skills.

**When in doubt, start with feature-design.** For ambiguous feature work,
feature-design orchestrates the full workflow and invokes other skills
(research, plan-verify, deep-review) as needed.
