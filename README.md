# justin-tools

A Claude Code plugin providing a complete development lifecycle toolkit:
27 skills, 8 agents, and 8 hooks covering research, design, implementation,
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
| `feature-design` | `/justin-tools:feature-design [desc]` | Idea through research, design, and phased implementation planning |
| `research` | `/justin-tools:research [topic]` | Technical deep-dives, competitive analysis, doc lookup (4 modes) |
| `debate` | `/justin-tools:debate [question]` | Multi-perspective analysis with scoring and rulings |
| `plan-verify` | Auto or manual | Verify plan claims against the actual codebase |

### Implementation

| Skill | Invoke | Description |
|:--|:--|:--|
| `rust-scaffold` | `/justin-tools:rust-scaffold [name]` | New Rust crate with layered architecture and conventions |
| `error-catalog` | `/justin-tools:error-catalog [crate]` | Design error type hierarchies for Rust crates |
| `refactor` | `/justin-tools:refactor [target]` | Structured refactoring with verification at each step |
| `test-strategy` | Auto or manual | Test planning, coverage gap analysis, property-based testing |

### Quality and Safety

| Skill | Invoke | Description |
|:--|:--|:--|
| `deep-review` | Auto or manual | Post-phase code review (13 categories, 4 groups) |
| `safety-checks` | Auto or `/justin-tools:safety-checks` | Security, auth, memory safety (STRIDE audit in manual mode) |
| `dep-audit` | Auto or manual | Dependency health, license compatibility, supply chain signals |
| `rust-ci-check` | `/justin-tools:rust-ci-check` | Full Rust CI: fmt, clippy, test, deny |
| `sequential-bench` | Auto or manual | Sequential benchmarks with regression detection |

### Operations

| Skill | Invoke | Description |
|:--|:--|:--|
| `debug` | Auto or manual | Systematic debugging: reproduce, hypothesize, isolate, verify |
| `perf-profile` | `/justin-tools:perf-profile [target]` | Performance investigation with instrumentation guidance |
| `incident-response` | `/justin-tools:incident-response [issue]` | Production triage, mitigation, postmortem |
| `crate-health` | `/justin-tools:crate-health` | Rust workspace health dashboard |

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
| `feature-architect` | feature-design, plan-verify, technical-writing | Full | Feature design and planning |
| `researcher` | research, technical-writing | Full | Technical deep-dives and doc lookup |
| `debate-lead` | debate, technical-writing | Full | Multi-perspective decision evaluation |
| `code-reviewer` | deep-review | Read-only | Post-phase code review |
| `security-auditor` | safety-checks | Read-only | STRIDE security audit |
| `debugger` | debug, safety-checks | Full | Systematic debugging |
| `test-engineer` | test-strategy, technical-writing | Full | Test planning and generation |
| `release-manager` | release-prep, docs-sync, technical-writing | Full | Release preparation |
| `onboarder` | project-onboard, technical-writing | Full | New project onboarding |

Invoke with `@agent-name` in your prompt, or Claude delegates automatically
based on the task.

## Hooks

| Event | Hook | Description |
|:--|:--|:--|
| PreToolUse | Block `git push` | Only the user pushes to remote |
| PreToolUse | Block `git reset --hard` | Destructive, requires user consent |
| PreToolUse | Block `git checkout --` | Discards uncommitted changes |
| PreToolUse | Block `git clean -f` | Removes untracked files permanently |
| PreToolUse | Block `rm -rf` | Requires targeted rm or user consent |
| Stop | Verification check | Catches code edits without running tests |
| TeammateIdle | Task check | Redirects idle teammates to pending tasks |
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
└── DEFERRED.md     # deferred work tracking
```

This directory should be gitignored. Files are not committed unless
explicitly requested.

## Onboarding a New Project

When using justin-tools on an existing project for the first time:

```
/justin-tools:project-onboard
```

Or delegate to the onboarding agent:

```
@onboarder set up this project for justin-tools
```

The onboarder will:
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

**Rename the plugin:**

```bash
./scripts/rename-plugin.sh new-name
```

See [CLAUDE.md](CLAUDE.md) for full development conventions.
