# Getting Started

## Prerequisites

- [Claude Code](https://code.claude.com) installed and authenticated
- This repository cloned locally

## Install

```bash
# Add the local marketplace (one-time)
claude plugin marketplace add /path/to/agent-skills

# Install the plugin (one-time)
claude plugin install justin-tools@justin-tools-marketplace
```

After installation, the plugin loads automatically in every session.

## Update

After making changes to skills, agents, or hooks:

1. Bump the version in `.claude-plugin/plugin.json`
2. Run: `claude plugin update justin-tools@justin-tools-marketplace`
3. In your session: `/reload-plugins`

## Onboard a Project

When using justin-tools on an existing project for the first time, run
the onboarding skill:

```
/justin-tools:project-onboard
```

Or delegate to the onboarding agent:

```
@onboarder set up this project for justin-tools
```

The onboarder will:
1. Explore the project (languages, build system, conventions, CI, tests)
2. Present an assessment of what is already in place and what is missing
3. Walk through setup one step at a time (gitignore, CLAUDE.md, etc.)
4. Highlight the 4-6 skills most relevant to the project
5. Suggest concrete next steps

This takes about 5-10 minutes and ensures the project is set up to get
the most from the plugin's skills and agents.

## Quick Tour

### Start a new feature

```
/justin-tools:feature-design add user authentication to the API
```

Claude explores the codebase, asks questions one at a time, designs the
feature, writes a phased implementation plan, verifies it, and hands off
to execution.

### Research a technology

```
/justin-tools:research how does HNSW vector search work
```

Choose from 4 modes: technical deep-dive, multi-perspective analysis,
competitive landscape, or documentation lookup.

### Evaluate a decision

```
/justin-tools:debate should we build HNSW in-house or use a library
```

3-5 perspectives argue from different angles with scoring and rulings.

### Run a security audit

```
/justin-tools:safety-checks auth module
```

STRIDE-based audit covering resource bounds, input validation, auth,
secrets, cryptography, supply chain, memory safety, and more.

### Scaffold a new Rust crate

```
/justin-tools:rust-scaffold my-new-crate
```

Creates Cargo.toml, lib.rs, error types, test structure, and optional
benchmarks following workspace conventions.

### Debug a failing test

```
/justin-tools:debug test_query_optimization is failing after the latest merge
```

Reproduces, forms hypotheses, isolates via git bisect, applies 5 Whys,
writes a regression test, and fixes.

### Prepare a release

```
/justin-tools:release-prep selene-graph
```

Generates changelog, checks for breaking changes, suggests version bump,
verifies docs, handles multi-crate ordering.

## Background Skills

These skills auto-trigger without invocation:

- **technical-writing** - style guide for all prose output
- **commit-workflow** - commit discipline and CI verification
- **safety-checks** - security awareness when writing handlers/auth/parsers
- **no-shortcuts** - ensures cross-cutting changes touch all sites
- **deferred-tracking** - captures deferred items as they arise
- **subagent-dispatch** - enforces sequential subagent rules
- **team-coordination** - agent team patterns when teams are available

## Agents

Agents are invoked with `@agent-name` or Claude delegates automatically:

- `@feature-architect` - feature design sessions
- `@researcher` - technical research
- `@debate-lead` - structured debates
- `@deep-reviewer` - post-phase code review
- `@security-auditor` - security audit
- `@debugger` - systematic debugging
- `@test-engineer` - test planning and generation
- `@release-manager` - release preparation

## Output

All document output goes to `_agentskills/` in the target project:

```
_agentskills/
├── plans/       # implementation plans
├── design/      # design documents
├── research/    # research findings
├── debates/     # debate findings
├── reviews/     # review and audit reports
└── DEFERRED.md  # deferred work tracking
```

Add `_agentskills/` to your project's `.gitignore`. Files are not
committed unless you explicitly ask.

## Next Steps

- [Skills Reference](skills-reference.md) - detailed documentation for all 27 skills
- [Agents Reference](agents-reference.md) - detailed documentation for all 8 agents
- [Hooks Reference](hooks-reference.md) - detailed documentation for all 8 hooks
- [CLAUDE.md](../CLAUDE.md) - development conventions for this plugin
