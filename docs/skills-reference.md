# Skills Reference

Complete reference for all 34 skills in the justin-tools plugin.

## Skill Categories

### Onboarding (1 skill)

#### project-onboard

**Invocation:** Manual (`/justin-tools:project-onboard`)
**Agent:** `onboarder`

Guided onboarding for existing projects. 5 stages:

1. **Explore** - reads the project: languages, build system, conventions,
   CI, tests, documentation, existing CLAUDE.md
2. **Assess** - presents a ready/gap checklist showing what is in place
   and what is missing
3. **Setup** - walks through gaps one step at a time, highest impact first:
   `_agentskills/` in .gitignore, CLAUDE.md creation/enhancement, relevant
   skills introduction per language, CI alignment, optional health checks
4. **Save** - stores project profile in agent persistent memory
5. **Next steps** - suggests 3-4 concrete skills to try based on project state

One step at a time, asks before changing, respects existing conventions.
Targets 5-10 minutes, not a lengthy setup wizard.

Supporting files: `claude-md-template.md`

---

### Feature Lifecycle (4 skills)

#### feature-design

**Invocation:** Manual (`/justin-tools:feature-design [description]`)

Guided interactive skill that runs in the main conversation through 5 stages:

1. **Explore and understand** - structured codebase exploration using
   `exploration-checklist.md`, then one-at-a-time clarifying questions
   with options and recommendations
2. **Capture preferences** - greenfield/brownfield, execution style
   (primary/subagent/mixed/team), commit strategy, complexity estimate
3. **Research and design** - conversational or formal (user chooses).
   Formal produces a design doc using `research-template.md`
4. **Write plan** - phased implementation plan using `plan-template.md`
   with complete code, dependency graphs, exit criteria per phase.
   Self-review catches placeholders and inconsistencies.
5. **Verify and hand off** - invokes `plan-verify`, user review cycle,
   execution handoff

Supporting files: `exploration-checklist.md`, `research-template.md`,
`plan-template.md`

#### research

**Invocation:** Manual (`/justin-tools:research [topic]`)
**Agent:** `researcher`

4 research modes:
- **Technical deep-dive** - how does X work? Uses web search, Consensus,
  Context7. Output: `deep-dive-template.md`
- **Multi-perspective analysis** - evaluate from multiple angles. Output:
  `multi-perspective-template.md`
- **Competitive/landscape analysis** - what alternatives exist? Output:
  `landscape-template.md`
- **Documentation research** - quick API/library lookup via Context7.
  Output directly in conversation.

Supporting files: `deep-dive-template.md`, `multi-perspective-template.md`,
`landscape-template.md`

#### debate

**Invocation:** Manual (`/justin-tools:debate [question]`)
**Agent:** `debate-lead`

3-phase structured debate:
1. **Independent generation** - each perspective produces Toulmin-structured
   arguments (claim, grounds, warrant, qualifier, rebuttal) before seeing others
2. **Adversarial exchange** - 2-3 rounds with decreasing contentiousness.
   Anti-conformity rule prevents false consensus
3. **Synthesis** - scoring matrix (evidence, relevance, rebuttal quality,
   reversibility, calibration), bias check, ADR-formatted output

Team-aware: spawns real teammates when agent teams are available.

Supporting files: `debate-output-template.md`

#### plan-verify

**Invocation:** Auto-triggers before plan execution, or manual
**Agent:** None (runs inline)

Verifies implementation plans against the codebase:
- Staleness detection via git diff
- File existence checks
- API signature verification (highest-value check)
- Data flow accuracy tracing
- Dependency ordering and parallel task safety
- Placeholder scanning
- Quality gate: Go / Fix-and-go / Rewrite / Kill

Supporting files: `verification-checklist.md`

---

### Implementation (6 skills)

#### rust-scaffold

**Invocation:** Manual (`/justin-tools:rust-scaffold [name]`)

Scaffolds a new Rust crate: Cargo.toml, lib.rs with `forbid(unsafe_code)`,
thiserror error types, test structure, optional Criterion benchmarks.
Respects layered architecture (foundation/middle/top) and workspace
conventions.

#### error-catalog

**Invocation:** Manual (`/justin-tools:error-catalog [crate]`)

Designs error type hierarchies for Rust crates. Analyzes failure modes,
proposes thiserror enums, verifies From conversion chains, checks context
propagation, and validates consumer handling. Prevents error handling
problems that deep-review catches after the fact.

#### modularize

**Invocation:** Manual (`/justin-tools:modularize [scope]`)
**Agent:** `code-analyzer`

Analyzes and restructures codebases into well-organized modules. Three
aggressiveness levels: conservative (within-file only), moderate (file
splitting, internal boundaries), aggressive (full restructuring). Delegates
read-only analysis to the code-analyzer agent, then guides incremental
execution with verification at each step.

Supporting files: `rust-patterns.md`, `python-patterns.md`,
`javascript-patterns.md`

#### code-standards

**Invocation:** Auto (background) or manual for audit
**Agent:** None (runs inline)

Language-specific best practices, anti-patterns, and linting rules. Auto-
applies as background knowledge during development. Manual mode audits
a file or scope against the full checklist, reporting naming violations,
complexity hotspots, structural anti-patterns, and non-idiomatic code.

Supporting files: `rust-standards.md`, `python-standards.md`,
`javascript-standards.md`

#### refactor

**Invocation:** Manual (`/justin-tools:refactor [target]`)

Structured refactoring: identify smell, write characterization tests,
plan transformation, execute incrementally with verification at each step.
Includes refactoring catalogs for Rust, Python, and JavaScript/TypeScript.
Refactor-vs-rewrite decision framework included.

#### test-strategy

**Invocation:** Auto or manual
**Agent:** `test-engineer`

Test planning and generation: boundary value analysis, coverage gap
detection, property-based testing (proptest, Hypothesis, fast-check),
mutation testing guidance. Generates complete test code following project
conventions. Supports Rust, Python, and JavaScript/TypeScript.

---

### Quality and Safety (5 skills)

#### deep-review

**Invocation:** Auto after phases/features
**Agent:** `deep-reviewer`

Post-implementation code review with 13 categories across 4 groups:
structural completeness, correctness, concurrency/performance, integration.
Follows Google's review navigation order. Structured finding format with
severity scoring. Explicit noise reduction guidance.

Supporting files: `review-patterns.md`

#### safety-checks

**Invocation:** Auto (background) or manual for full audit
**Agent:** `security-auditor`

6 principles, 9-category checklist, STRIDE-based manual audit mode.
Covers resource bounds, input validation, auth/authz, secret handling,
cryptography, supply chain, memory safety, container/infra, error handling.

Supporting files: `python-safety.md`, `rust-safety.md`,
`javascript-safety.md`, `secrets-patterns.md`, `crypto-guidelines.md`

#### dep-audit

**Invocation:** Auto when recommending dependencies

Build-vs-depend decision framework, health metrics per ecosystem (Rust/npm/
Python), license compatibility checking, supply chain red flag detection,
transitive dependency analysis. Side-by-side comparison format.

Supporting files: `ecosystem-audit.md`, `license-compatibility.md`

#### rust-ci-check

**Invocation:** Manual (`/justin-tools:rust-ci-check`)

Full Rust CI sequence: `cargo fmt --all`, `cargo clippy --workspace
--all-features --all-targets -- -D warnings`, `cargo test --workspace
--all-features`, `cargo deny check`. Auto-retry on failure (2 cycles max).

#### sequential-bench

**Invocation:** Auto or manual (`/justin-tools:sequential-bench [crates]`)

Sequential benchmark execution (never parallel), baseline comparison,
regression detection (>10% threshold), Benchmarks.md update.

---

### Operations (4 skills)

#### debug

**Invocation:** Auto or manual
**Agent:** `debugger`

Scientific debugging: reproduce, hypothesize (with tracking table),
isolate, verify. Includes git bisect for regressions, 5 Whys root cause
analysis, anti-pattern avoidance, concurrent/async debugging patterns.
Multi-language: Rust, Python, JavaScript/TypeScript.

#### perf-profile

**Invocation:** Manual (`/justin-tools:perf-profile [target]`)

Performance investigation: define question, establish baseline, profile
(flamegraph, Criterion, cProfile, Node --prof), form hypotheses, optimize
one change at a time, verify no regressions. Instrumentation mode adds
tracing/OpenTelemetry spans.

#### incident-response

**Invocation:** Manual (`/justin-tools:incident-response [issue]`)

Production triage: gather symptoms, correlate with recent changes, assess
severity/blast radius, immediate mitigation (revert/flag/scale), root
cause investigation (delegates to debug), postmortem template.

#### crate-health

**Invocation:** Manual (`/justin-tools:crate-health`)

Rust workspace health: dependency graph analysis, compile time profiling,
feature flag audit, dead code detection, test coverage assessment, unsafe
code inventory. Produces prioritized maintenance task list.

---

### Release and Documentation (4 skills)

#### release-prep

**Invocation:** Manual (`/justin-tools:release-prep [crate]`)
**Agent:** `release-manager`

Release readiness: changelog generation from conventional commits,
cargo-semver-checks for breaking API detection, version bump suggestion,
documentation verification, multi-crate workspace ordering, pre-release
checklist. Supports Rust, Python, JavaScript/TypeScript.

#### migration-guide

**Invocation:** Manual (`/justin-tools:migration-guide [change]`)

Breaking change management: catalog changes, generate migration guide
with before/after examples, deprecation-first rollout planning,
transformation aids. Multi-language deprecation patterns.

#### api-doc-gen

**Invocation:** Manual (`/justin-tools:api-doc-gen [module]`)

Generate API documentation from code: scan public items, generate doc
comments following language conventions, module overviews, verify
doc-tests compile. Supports Rust, Python, TypeScript.

#### docs-sync

**Invocation:** Auto or manual (`/justin-tools:docs-sync [focus]`)

Full documentation scan: checks README, docs/, Benchmarks.md, CLAUDE.md,
CHANGELOG.md, .pyi stubs, Dockerfile against the current codebase. Finds
stale references, outdated examples, stale metrics, structural gaps.

---

### Workflow Discipline (6 background skills)

These auto-trigger as background knowledge. Not user-invocable
(except `deferred-tracking`).

#### technical-writing

36 rules covering voice, conciseness, punctuation, AI-ism avoidance, code
comments, docstrings, commit messages, and scannability. Language-specific
docstring conventions for Rust, Python, TypeScript.

#### commit-workflow

Milestone commits, CI verification before committing (Rust/Python/JS
commands), never push unless asked, conventional commit format, never
commit `_agentskills/`.

#### no-shortcuts

Cross-cutting changes must touch all affected sites. Compiler-driven
discovery, explicit handling (no wildcards), full test verification.

#### deferred-tracking

**Also user-invocable:** `/justin-tools:deferred-tracking [review]`

Structured DEFERRED.md management: auto-captures deferred items with
priority, gate, source, and date. Manual review mode triages items into
Ready/Approaching/Still deferred/Stale. Staleness detection, relationship
tracking.

#### subagent-dispatch

Sequential dispatch only, review between tasks, CI verification in every
subagent prompt. Team-aware: recommends agent teams when available for
parallel work.

#### team-coordination

Agent team patterns: parallel review, parallel research, multi-perspective
debate, wave-based implementation. Lead and teammate utilization guidance.
Available agent types reference.
