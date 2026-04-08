---
name: project-onboard
description: >
  Guided onboarding for existing projects. Assesses project state, identifies
  gaps, and walks through setup one step at a time. Use when first using
  justin-tools on a new or existing repo.
disable-model-invocation: true
argument-hint: "[project path]"
---

## Purpose

When using justin-tools on a project for the first time, assess the current
state and guide the user through setting up conventions, configuration, and
practices that make the plugin's skills and agents most effective. One step
at a time, never overwhelming.

This is an interactive skill. Present each setup step individually, explain
why it matters, and wait for the user's approval before making changes.

## Instructions

### Stage 0: Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and check for prior onboarding:

1. **Create session** with `skill: 'project-onboard'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior onboarding sessions:
   - Prior `:Session {skill: 'project-onboard'}` for this project
   - Any `:Decision` nodes from prior onboarding (what was set up)
   - Any `:Insight` nodes about project conventions

3. If the project was previously onboarded:

> "This project was onboarded on [date]. Previous setup included:
> - [What was configured]
> - [Key conventions discovered]
>
> Running a refresh to check for changes since then."

A previously onboarded project gets a lighter touch — focus on what
changed since last onboarding rather than a full assessment.
If no prior context exists, skip silently.

### Stage 1: Explore the project

Before asking any questions, build a complete picture:

#### Language and ecosystem

- What languages are used? (Rust, Python, JavaScript/TypeScript, other)
- What build system? (Cargo, pip/uv, npm/pnpm, etc.)
- Is this a workspace/monorepo or single package?
- What frameworks? (Axum, FastAPI, Express, etc.)

#### Existing conventions

- Does CLAUDE.md exist? Read it. How comprehensive is it?
- Does .claude/ directory exist? What's in it? (settings, agents, skills, rules)
- What's the commit message convention? (check recent git log)
- Is there a CI configuration? What does it check?
- Is there a CHANGELOG? What format?
- Is there a DEFERRED.md or equivalent backlog?

#### Code health indicators

- Are there tests? How many? What pattern? (inline, separate, integration)
- Is there a linter configured? (clippy, ruff, eslint)
- Is there a formatter configured? (rustfmt, ruff format, prettier)
- Are dependencies locked? (Cargo.lock, package-lock.json, requirements.txt)
- Is there documentation? (README quality, doc comments, API docs)

### Stage 2: Present assessment

Summarize what you found in a brief, scannable report:

```
Project: [name]
Languages: [Rust, Python, etc.]
Build: [Cargo workspace, npm, etc.]
Tests: [N tests, pattern]
CI: [configured/missing]
CLAUDE.md: [comprehensive/basic/missing]

Ready for justin-tools:
  [check] .gitignore includes _agentskills/
  [check] CLAUDE.md exists with conventions
  [check] Commit convention established
  [gap] No CLAUDE.md
  [gap] _agentskills/ not in .gitignore
  [gap] No CI linting configured
```

### Stage 3: Prioritized setup

Walk through gaps **one at a time**, starting with the highest impact.
For each step, explain what it does, why it matters, and ask if the user
wants to proceed before making changes.

#### Priority 1: _agentskills/ in .gitignore

If `_agentskills/` is not in `.gitignore`, offer to add it:

> "_agentskills/ is where skills write working documents (plans, research,
> debates). It should be gitignored so these don't clutter your repo.
> Add it to .gitignore?"

#### Priority 2: CLAUDE.md

If CLAUDE.md is missing or thin, offer to create or enhance it. Read the
codebase to understand conventions and generate a CLAUDE.md that captures:

- Project purpose and architecture overview
- Language-specific conventions (detected from code)
- Build and test commands
- Important patterns and decisions
- Any restrictions or preferences

Use [claude-md-template.md](claude-md-template.md) as a starting structure.
Present the draft for review. Do not write without approval.

If CLAUDE.md already exists, scan for gaps:
- Are build/test commands documented?
- Are architectural conventions captured?
- Are there CI requirements mentioned?
- Is there guidance for contributing?

Offer to add missing sections.

#### Priority 3: Relevant skills introduction

Based on the detected languages and project type, highlight which
justin-tools skills are most relevant:

**For Rust projects:**
> "Your project will benefit most from: `rust-ci-check` for CI verification,
> `rust-scaffold` for new crates, `error-catalog` for error type design,
> `crate-health` for workspace maintenance, and `sequential-bench` for
> benchmarking."

**For Python projects:**
> "Key skills for your project: `safety-checks` (includes Python-specific
> patterns), `test-strategy` for test generation, `dep-audit` for dependency
> health, and `debug` for systematic debugging."

**For JavaScript/TypeScript projects:**
> "Most relevant skills: `safety-checks` (includes JS/TS patterns),
> `test-strategy` for test coverage, `dep-audit` for npm dependency audit,
> and `refactor` for structured refactoring."

**For all projects:**
> "Universal skills: `feature-design` for planning, `deep-review` after
> implementation phases, `docs-sync` for documentation freshness, and
> `deferred-tracking` for managing deferred work."

#### Priority 4: CI alignment

If CI exists, check that it aligns with the plugin's expectations:
- Does it run format checks? (skills assume format is enforced)
- Does it run linting? (skills assume zero-warning policy)
- Does it run tests? (skills assume full test suite on commit)

If CI is missing or incomplete, suggest additions but do not create CI
files without explicit permission.

#### Priority 5: Quick health check

Offer to run relevant health checks:

> "Want me to run a quick health check? I can:
> 1. Scan for documentation staleness (`docs-sync`)
> 2. Check dependency health (`dep-audit`)
> 3. [Rust] Run workspace health (`crate-health`)
> 4. [All] Check for hardcoded secrets (`safety-checks`)
>
> Which ones? Or skip for now."

### Stage 4: Save project profile

#### Graph write: project assessment (SeleneDB)

Write the project assessment and setup decisions to the graph:

```gql
INSERT (i:Insight {
  summary: 'Project assessment: ' + $project_name,
  sources: 'Detected from codebase exploration',
  confidence: 'high',
  actionable: true
})
RETURN id(i) AS insight_id

MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(i)
```

For each setup step the user approved, write a `:Decision`:

```gql
INSERT (d:Decision {
  summary: $setup_step,
  rationale: $why_it_matters,
  confidence: 'high'
})
```

This replaces flat-file memory for onboarding context. Future onboarding
sessions start with "this project was already set up with X, Y, Z."

If running as the `onboarder` agent, save key findings to persistent memory:

- Project name, languages, build system
- What was set up during onboarding
- Key conventions discovered
- Skills most relevant to this project
- Any project-specific notes

This makes future sessions in the same project more effective immediately.

### Stage 5: Next steps

Suggest concrete next steps based on the project's state:

> "Project is onboarded. Here are your next steps:
> 1. [If new feature work] Try `/justin-tools:feature-design` to plan it
> 2. [If tests are thin] Try `/justin-tools:test-strategy` to find gaps
> 3. [If release pending] Try `/justin-tools:release-prep` to prepare
> 4. [If tech debt] Try `/justin-tools:refactor` to structure cleanup
>
> All skills work in this project now. Run `/reload-plugins` if you
> add or change skills during this session."

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Present all 35 skills so the user knows what's available" | Information overload. Surface the 3-5 relevant skills based on the detected project type. |
| "Skip exploration, the user knows their project" | The user knows the project. The agent does not. Exploration builds the context needed for accurate recommendations. |
| "CLAUDE.md exists, skip assessment" | Existing doesn't mean complete. Scan for gaps — missing build commands, stale conventions, or missing CI guidance. |
| "Full setup required for every project" | Skip what's already done. A project with comprehensive CLAUDE.md and gitignore needs a lighter onboarding. |

## Red Flags

Stop and reassess if you observe:
- Making changes without explicit user approval
- Overriding existing project conventions with plugin defaults
- Presenting all skills at once instead of routing by project type
- Skipping the assessment and jumping to setup recommendations

## Verification

- [ ] Project explored (languages, build system, CI, tests, conventions)
- [ ] Assessment presented showing ready/gap status
- [ ] Each setup step approved by user before applying
- [ ] Project profile saved to persistent memory

## Guidance

**One step at a time.** Never present the full list of 35 skills and
9 agents. Introduce only what is relevant to this project. More can be
introduced as the user explores.

**Ask before changing.** Every modification (gitignore, CLAUDE.md, settings)
requires explicit approval. Show what you would add and ask first.

**Respect existing conventions.** If the project already has conventions
(commit format, test patterns, CI rules), adopt them. Do not impose the
plugin's defaults over working project practices.

**Skip what is already done.** If CLAUDE.md is comprehensive and gitignore
is set up, acknowledge that and move to the next relevant step. Do not
re-do what is already in place.

**Keep it fast.** Full onboarding should take 5-10 minutes of interaction,
not 30. The goal is "ready to use skills" not "perfect project setup."
