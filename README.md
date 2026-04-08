# justin-tools

A Claude Code plugin providing a complete development lifecycle toolkit:
38 skills, 9 agents, and 8 hooks covering research, design, implementation,
testing, review, debugging, release, and team coordination.

**Languages:** Rust, Python, JavaScript/TypeScript

## Installation

Add the local marketplace and install:

```bash
claude plugin marketplace add /path/to/agent-skills
claude plugin install justin-tools@justin-tools-marketplace
```

The plugin persists across all sessions. No flags needed after installation.

**Update after changes:**

```bash
claude plugin update justin-tools@justin-tools-marketplace
```

Then run `/reload-plugins` in your session.

## Skills

### Feature Lifecycle

| Skill | Invoke | Description |
|:--|:--|:--|
| `skill-guide` | Auto or manual | Find the right skill for a task — routes by workflow phase |
| `feature-design` | `/justin-tools:feature-design [desc]` | Idea through research, design, and phased implementation planning |
| `research` | `/justin-tools:research [topic]` | Technical deep-dives, competitive analysis, doc lookup (4 modes) |
| `debate` | `/justin-tools:debate [question]` | Multi-perspective analysis with scoring and rulings |
| `plan-verify` | Auto or manual | Verify plan claims against the actual codebase |
| `requirements-trace` | `/justin-tools:requirements-trace [plan]` | Post-implementation trace: requirements to code to tests |

### Implementation

| Skill | Invoke | Description |
|:--|:--|:--|
| `rust-scaffold` | `/justin-tools:rust-scaffold [name]` | New Rust crate with layered architecture and conventions |
| `error-catalog` | `/justin-tools:error-catalog [crate]` | Design error type hierarchies for Rust crates |
| `refactor` | `/justin-tools:refactor [target]` | Structured refactoring with verification at each step |
| `modularize` | `/justin-tools:modularize [scope]` | Codebase decomposition: file splitting, module hierarchy, dependency direction |
| `code-standards` | Auto or manual | Language-specific best practices, anti-patterns, and linting rules |
| `test-strategy` | Auto or manual | Test planning, coverage gap analysis, property-based testing |

### Quality and Safety

| Skill | Invoke | Description |
|:--|:--|:--|
| `deep-review` | Auto or manual | Post-phase code review (13 categories) with convention graduation |
| `safety-checks` | Auto or `/justin-tools:safety-checks` | Security, auth, memory safety (STRIDE audit in manual mode) |
| `dep-audit` | Auto or manual | Dependency health, license compatibility, supply chain signals |
| `rust-ci-check` | `/justin-tools:rust-ci-check` | Full Rust CI: fmt, clippy, test, deny |
| `sequential-bench` | Auto or manual | Sequential benchmarks with regression detection |
| `env-audit` | `/justin-tools:env-audit [scope]` | Audit env var usage against config files, find mismatches |
| `migration-safety` | `/justin-tools:migration-safety [file]` | Database migration risk analysis and rollback planning |

### Operations

| Skill | Invoke | Description |
|:--|:--|:--|
| `debug` | Auto or manual | Systematic debugging: reproduce, hypothesize, isolate, verify |
| `perf-profile` | `/justin-tools:perf-profile [target]` | Performance investigation with instrumentation guidance |
| `incident-response` | `/justin-tools:incident-response [issue]` | Production triage, mitigation, postmortem |
| `crate-health` | `/justin-tools:crate-health` | Rust workspace health dashboard |
| `milestone-tracking` | Auto or manual | Track development milestones — groups of commits into named initiatives |
| `notes` | Auto or manual | Attach TODOs, rationale, observations, and bookmarks to any graph node |
| `session-tracker` | Auto or manual | Track and recall context across sessions for continuity |
| `ci-pipeline` | `/justin-tools:ci-pipeline [mode]` | Generate, audit, and diagnose CI/CD pipelines |
| `project-onboard` | `/justin-tools:project-onboard` | Guided project setup for justin-tools |

### Release and Documentation

| Skill | Invoke | Description |
|:--|:--|:--|
| `release-prep` | `/justin-tools:release-prep [crate]` | Changelog, semver-checks, version bump, multi-crate ordering |
| `migration-guide` | `/justin-tools:migration-guide [change]` | Breaking change management and deprecation planning |
| `api-doc-gen` | `/justin-tools:api-doc-gen [module]` | Generate API documentation from code |
| `docs-sync` | Auto or manual | Full documentation staleness scan |

### Workflow Discipline (Background)

These skills auto-trigger as background knowledge:

| Skill | Description |
|:--|:--|
| `technical-writing` | Style guide for all prose (36 rules + docstring conventions) |
| `commit-workflow` | Milestone commits, verify before committing, never push unless asked |
| `no-shortcuts` | Cross-cutting changes must touch all affected sites |
| `deferred-tracking` | Track deferred work in structured DEFERRED.md |
| `subagent-dispatch` | Sequential subagent rules, team-aware |
| `team-coordination` | Agent team patterns and utilization guidance |

## Agents

Agents are specialized subagents with skills preloaded and persistent
memory. They accumulate knowledge across sessions.

| Agent | Skills Preloaded | Tools | Purpose |
|:--|:--|:--|:--|
| `researcher` | research, technical-writing | Full | Technical deep-dives and doc lookup |
| `debate-lead` | debate, technical-writing | Full | Multi-perspective decision evaluation |
| `code-analyzer` | modularize, code-standards | Reports-only | Codebase structure and complexity analysis |
| `deep-reviewer` | deep-review | Reports-only | Post-phase code review |
| `security-auditor` | safety-checks | Reports-only | STRIDE security audit |
| `debugger` | debug, safety-checks | Full | Systematic debugging |
| `test-engineer` | test-strategy | Full | Test planning and generation |
| `release-manager` | release-prep, docs-sync, technical-writing | Full | Release preparation |
| `onboarder` | project-onboard, technical-writing | Full | New project onboarding |

Invoke with `@agent-name` in your prompt, or Claude delegates automatically
based on the task.

## Hooks

| Event | Hook | Description |
|:--|:--|:--|
| SessionStart | Skill routing + session context | Injects skill routing table and loads prior session context from SeleneDB |
| PreToolUse | Block `git push` | Only the user pushes to remote |
| PreToolUse | Block `git reset --hard` | Destructive, requires user consent |
| PreToolUse | Block `git checkout --` | Discards uncommitted changes |
| PreToolUse | Block `git clean -f` | Removes untracked files permanently |
| PreToolUse | Block `rm -rf` | Requires targeted rm or user consent |
| TeammateIdle | Task check | Reminds idle teammates to check for pending tasks |
| Notification | Desktop alert | macOS notification when Claude needs input |

## Output Directory

Skills write documents to `_agentskills/` in the target project:

```
_agentskills/
├── plans/          # implementation plans
├── design/         # design documents
├── research/       # technical deep-dives, landscape analyses
├── debates/        # multi-perspective debate findings
├── reviews/        # code review and security audit reports
├── DEFERRED.md     # deferred work tracking
├── NOTES.md        # free-form annotations (fallback)
├── SESSION_LOG.md  # session continuity log (fallback)
└── milestones.md   # milestone tracking (fallback)
```

This directory should be gitignored. Files are not committed unless
explicitly requested.

## SeleneDB Integration

18 skills can optionally persist structured reasoning to
[SeleneDB](https://selenedb.com), an AI-first property graph database.
This enables cross-session knowledge accumulation — prior debugging
sessions inform future ones, review findings surface in test planning,
deferred items carry forward to release prep, and recurring patterns
graduate to project conventions.

**Setup:** Configure the SeleneDB MCP server in your project or user settings.
Skills auto-detect `gql_query` tool availability at runtime and fall back to
normal behavior when SeleneDB is not available.

**Key capabilities:**

| Feature | What it does |
|:--|:--|
| **Session continuity** | Rolling summaries captured at skill completion, loaded at session start |
| **Topic discovery** | `:Topic` nodes connect research, deferred items, and milestones by domain |
| **Provenance chains** | `:informs` edges trace research → plan → implementation |
| **Convention graduation** | Recurring deep-review findings auto-promote to project conventions |
| **Milestone tracking** | Named initiatives group commits, documents, and decisions |
| **Universal notes** | Free-form annotations attached to any graph node |

**Migrated skills:** research, deep-review, debug, plan-verify, release-prep,
deferred-tracking, test-strategy, feature-design, debate, incident-response,
refactor, perf-profile, modularize, project-onboard, requirements-trace,
milestone-tracking, notes, session-tracker.

See `skills/_selene/` for schema, integration patterns, and setup scripts.

## Onboarding a New Project

When using justin-tools on an existing project for the first time:

```
/justin-tools:project-onboard
```

The skill will guide you through setup interactively:
1. Explore the project (languages, build system, conventions, CI)
2. Assess what is already in place
3. Walk through gaps one step at a time (gitignore, CLAUDE.md, etc.)
4. Highlight the most relevant skills for the project
5. Suggest concrete next steps

## Development

**Add a new skill:**

```bash
cp -r skills/_template skills/my-new-skill
# Edit skills/my-new-skill/SKILL.md
claude --plugin-dir .  # test locally
```

**CI:** A GitHub Actions workflow validates the plugin on push to `main` and
on pull requests.

**Rename the plugin:**

```bash
./scripts/rename-plugin.sh new-name
```

See [CLAUDE.md](CLAUDE.md) for full development conventions.
