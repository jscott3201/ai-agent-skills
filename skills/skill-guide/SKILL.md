---
name: skill-guide
description: >
  Find the right skill for a task. Routes tasks to the appropriate skill
  by workflow phase. Use when unsure which skill applies or to recommend
  skills the user may not know about.
---

## Purpose

Help discover and select the right skill for the current task. This plugin
has 35 skills — this guide routes by what you're trying to accomplish.

Skills marked **(auto)** trigger automatically from their descriptions.
Skills marked **(manual)** require `/justin-tools:<name>` to invoke.
Skills marked **(background)** apply silently during all work.

**When NOT to use:** You already know which skill to use (just use it).
The user invoked a specific skill by name. The task doesn't match any
skill (not everything needs a skill — sometimes just write the code).

## Routing by Task

### Planning and design

| Task | Skill | Invocation |
|---|---|---|
| Plan a feature from idea to implementation | **feature-design** | manual |
| Research a technology, evaluate options, or investigate alternatives | **research** | manual |
| Evaluate a decision with structured multi-perspective debate | **debate** | manual |

### Building

| Task | Skill | Invocation |
|---|---|---|
| Scaffold a new Rust crate with architecture and tests | **rust-scaffold** | manual |
| Design error type hierarchies for Rust crates | **error-catalog** | manual |
| Restructure a codebase into well-organized modules | **modularize** | manual |
| Refactor code safely with verification at each step | **refactor** | manual |
| Generate, audit, or diagnose CI/CD pipelines | **ci-pipeline** | manual |

### Testing and verification

| Task | Skill | Invocation |
|---|---|---|
| Generate test plan and test code with coverage analysis | **test-strategy** | auto |
| Run the full Rust CI sequence (fmt, clippy, test, deny) | **rust-ci-check** | manual |
| Verify an implementation plan against the actual codebase | **plan-verify** | auto |
| Verify requirements have corresponding code and tests | **requirements-trace** | manual |
| Run benchmarks sequentially and track results | **sequential-bench** | auto |

### Debugging and performance

| Task | Skill | Invocation |
|---|---|---|
| Systematically debug a bug with hypotheses and root cause | **debug** | auto |
| Investigate performance: profile, hypothesize, optimize, verify | **perf-profile** | manual |
| Triage a production incident with structured response | **incident-response** | manual |

### Code review and security

| Task | Skill | Invocation |
|---|---|---|
| Deep review after completing a feature or phase | **deep-review** | auto |
| Security audit using STRIDE threat analysis | **safety-checks** | auto |
| Apply language-specific coding standards | **code-standards** | auto |
| Audit a dependency before adoption | **dep-audit** | auto |

### Releasing and migration

| Task | Skill | Invocation |
|---|---|---|
| Prepare a release: changelog, semver, version bump, docs | **release-prep** | manual |
| Manage breaking API changes with migration guides | **migration-guide** | manual |
| Analyze database migrations for unsafe operations | **migration-safety** | manual |

### Documentation and maintenance

| Task | Skill | Invocation |
|---|---|---|
| Scan docs for stale references after code changes | **docs-sync** | auto |
| Generate or update API documentation from code | **api-doc-gen** | manual |
| Audit environment variables against config files | **env-audit** | manual |
| Analyze Rust workspace health (deps, compile times, coverage) | **crate-health** | manual |
| Onboard a new project for use with this plugin | **project-onboard** | manual |
| Track deferred work items in DEFERRED.md | **deferred-tracking** | auto |

### Process (background rules)

These apply automatically during all implementation work:

| Rule | Skill |
|---|---|
| Commit at milestones, verify before commit, never push | **commit-workflow** |
| Sequential subagent dispatch with review between tasks | **subagent-dispatch** |
| Team coordination patterns and wave boundaries | **team-coordination** |
| Technical writing style for all prose | **technical-writing** |
| All affected sites must be updated, no partial changes | **no-shortcuts** |

## Choosing Between Similar Skills

| Situation | Use this | Not this |
|---|---|---|
| Restructure files and modules | **modularize** | refactor |
| Refactor within a file (extract function, reduce complexity) | **refactor** | modularize |
| Review code after building a feature | **deep-review** | code-standards |
| Check coding style during development | **code-standards** | deep-review |
| Plan a new feature end-to-end | **feature-design** | research |
| Investigate a technology or compare options | **research** | feature-design |
| Debug a specific bug | **debug** | perf-profile |
| Investigate why something is slow | **perf-profile** | debug |
| Check a new dependency before adding it | **dep-audit** | crate-health |
| Assess overall workspace health | **crate-health** | dep-audit |
| Production is down, need triage now | **incident-response** | debug |
| Bug found in development, need root cause | **debug** | incident-response |

## Agents

Agents are specialized subprocesses with preloaded skills and tool restrictions.
Use agents when the task benefits from isolation, parallelism, or specialized
focus.

| Agent | Purpose | Key skills |
|---|---|---|
| **deep-reviewer** | Code review (read-only) | deep-review |
| **security-auditor** | Security audit (read-only) | safety-checks |
| **code-analyzer** | Modularization analysis (read-only) | modularize, code-standards |
| **test-engineer** | Test planning and generation | test-strategy |
| **debugger** | Systematic debugging | debug, safety-checks |
| **researcher** | Technical research and evaluation | research |
| **release-manager** | Release preparation | release-prep, docs-sync |
| **onboarder** | Project onboarding | project-onboard |
| **debate-lead** | Multi-perspective debate | debate |

## Guidance

**Recommend proactively.** When you see a user working on a task that matches
a manual skill, suggest it. The user may not know the skill exists.

**Auto skills handle themselves.** Don't invoke auto skills explicitly unless
the user asks. Their descriptions tell the model when to activate.

**Background rules are always active.** Never invoke them as skills. They
apply to all implementation work automatically.

**When in doubt, start with feature-design.** For ambiguous feature work,
feature-design orchestrates the full workflow and invokes other skills
(research, plan-verify, deep-review) as needed.
