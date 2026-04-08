---
name: modularize
description: >
  Analyze and restructure codebases into well-organized modules. Identifies
  splitting candidates, complexity hotspots, and circular dependencies.
  Scales from conservative (extract functions) to aggressive (full reorg).
disable-model-invocation: true
argument-hint: "[scope or file path]"
---

## Purpose

Guide the decomposition of large, monolithic files and poorly organized
codebases into well-structured, maintainable modules. Operates at the
structural level: file splitting, module hierarchy, package/crate boundaries,
and dependency direction. Complements the `refactor` skill, which handles
individual code transformations.

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior structural analysis:

1. **Create session** with `skill: 'modularize'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior modularization work:
   - Prior `:Decision` nodes from modularize or refactor sessions on same scope
   - Prior findings triaged as "defer" or "skip" that may now be relevant
   - Recurring refactoring patterns from the refactor skill on these modules

3. If prior structural context exists:

> "Prior structural context:
> - [This area was analyzed N times — last aggressiveness level used]
> - [N deferred findings from prior analysis]
> - [Refactor skill has touched this module N times — may indicate deeper issue]
>
> Prior deferred items may be ready to address."

If SeleneDB is not available or no prior context exists, skip silently.

### 1. Assess aggressiveness

Before analyzing code, determine the refactoring scope. Ask the user:

> **How aggressive should this restructuring be?**
>
> - **Conservative** - Extract functions/methods, reduce complexity within
>   existing files. No file moves, no API changes. Safe for production
>   codebases with many consumers.
> - **Moderate** - Split large files into modules, introduce internal
>   boundaries. May create new files but preserves all public APIs.
>   Good for active development with some stability expectations.
> - **Aggressive** - Full restructuring allowed: new module hierarchies,
>   crate/package splitting, API surface redesign. Appropriate for
>   greenfield, early-stage, or dedicated refactoring initiatives.

If the user provides aggressiveness in `$ARGUMENTS` (e.g., "moderate: src/lib.rs"),
skip the question.

Record the choice. It gates every recommendation that follows.

### 2. Delegate analysis to code-analyzer

Delegate to the `code-analyzer` agent using the Agent tool.

Include in the delegation prompt:
- The aggressiveness level chosen
- The scope from `$ARGUMENTS` (specific files, directories, or full codebase)
- The primary language (detect from file extensions if not specified)

The agent scans read-only and produces a structured report covering:
- File size violations (lines of code per file)
- Complexity hotspots (functions/methods exceeding thresholds)
- Circular dependency chains
- God classes/structs with too many responsibilities
- Visibility over-exposure (public items that should be internal)
- Coupling metrics (files that change together)

### 3. Review findings and prioritize

When the code-analyzer report returns:

1. Filter findings by aggressiveness level:
   - **Conservative**: only within-file issues (long functions, deep nesting,
     complexity violations)
   - **Moderate**: within-file issues + file splitting candidates + internal
     boundary improvements
   - **Aggressive**: all findings including structural reorganization

2. Prioritize by impact:
   - **P1**: Circular dependencies, files >1000 lines, functions >100 lines
   - **P2**: Files 500-1000 lines, god classes, visibility over-exposure
   - **P3**: Files 300-500 lines, coupling issues, naming problems

3. Present findings to the user **one at a time**, starting with P1.
   For each finding:

   > "[Finding]: [brief description]
   > **Priority:** P1/P2/P3 | **Effort:** small/medium/large
   > **What it improves:** [specific benefit]
   > **What it costs:** [risk, disruption, effort]
   >
   > Options:
   > 1. **Include** - add to the refactoring plan
   > 2. **Skip** - not worth addressing now
   > 3. **Defer** - track for later (add to DEFERRED.md)
   >
   > I recommend [option] because [reason]."

   Wait for the user's decision before presenting the next finding.
   After all findings are triaged, summarize the approved set and
   confirm before proceeding to planning.

#### Graph write: finding triage (SeleneDB)

After each finding triage decision:

```gql
INSERT (d:Decision {
  summary: $finding_description,
  rationale: $user_choice + ': ' + $reason,
  alternatives: $other_options,
  confidence: 'high'
})
RETURN id(d) AS decision_id

MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(d)

MERGE (loc:CodeLocation {file: $file, module: $module})
INSERT (d)-[:affects]->(loc)
```

If the user chooses **defer**, also create a `:DeferredItem` to bridge
to deferred-tracking.

### 4. Create refactoring plan

For the approved set of findings, produce a step-by-step refactoring
plan. Detect the
project's primary language from file extensions. Load ONLY the single
patterns file for that language:

- [rust-patterns.md](rust-patterns.md) - Module splitting, crate extraction,
  compose structs, visibility tightening
- [python-patterns.md](python-patterns.md) - Package restructuring, circular
  import resolution, Protocol extraction
- [javascript-patterns.md](javascript-patterns.md) - File splitting, barrel
  file removal, feature-based reorganization

Each plan step must:
- Make one structural change
- Keep the codebase compiling/passing at each step
- Include the verification command (`cargo check`, `tsc --noEmit`, `ruff check`)
- Be independently committable

### 5. Execute incrementally

For each approved step:

1. Make the structural change (move code, create files, update imports)
2. Run the verification command
3. Run the test suite
4. Commit with a descriptive message: `refactor(scope): description`

If tests break, revert the step and reassess. Do not fix forward during
structural moves.

For moderate and aggressive refactorings, pause after every 3-5 steps to
check in with the user. Structural changes compound — early course corrections
prevent wasted work.

### 6. Verify the result

After all steps complete:

1. Run full test suite and linter
2. Compare public API surface: has it changed? Was that intentional?
3. Verify the original problems are resolved (re-run complexity checks)
4. Check that no new circular dependencies were introduced
5. Summarize what changed: files created, files removed, modules reorganized

## Size thresholds

Reference thresholds that trigger recommendations. These apply across
aggressiveness levels (the level determines what *actions* to take, not
what to *detect*).

| Metric | Rust | Python | JS/TS |
|:--|:--|:--|:--|
| File soft limit | 300 lines | 300 lines | 200 lines |
| File warning | 500 lines | 500 lines | 300 lines |
| File hard ceiling | 1,000 lines | 1,000 lines | 500 lines |
| Function length | 60 lines | 40 statements | 50 lines |
| Max parameters | 5 | 4 | 3 |
| Cyclomatic complexity | 15 (cognitive) | 8 (McCabe) | 10 (cyclomatic) |
| Max nesting depth | 4 levels | 4 levels | 3 levels |
| Max struct/class fields | 7 | 7 attributes | 8 props |

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Skip code-analyzer, read code directly" | You miss what you don't look for. The analyzer checks systematically across the full codebase. |
| "Only address P1 findings" | P2/P3 compound. Small structural issues become large ones when deferred together. |
| "Skip verification between steps" | Each modularization step can break imports and references. Verify incrementally. |
| "Conservative mode is fine, skip execution" | Analysis without action is a report, not a refactoring. Execute the approved changes. |

## Red Flags

Stop and reassess if you observe:
- Splitting files by line count instead of responsibility
- Skipping the code-analyzer step and reading code directly
- Not verifying compilation and tests after each structural move
- Creating circular dependencies through the restructuring

## Verification

- [ ] Code-analyzer report produced with prioritized findings
- [ ] Aggressiveness level confirmed with user
- [ ] Each transformation verified (compiles, tests pass) before the next
- [ ] No circular dependencies introduced
- [ ] Existing tests still pass without rewrites

## Guidance

**Aggressiveness is a ceiling, not a floor.** Conservative mode does not
mean "do nothing." It means every recommendation fits within existing file
boundaries.

**Structure follows responsibility.** Split by what code *does*, not by
how many lines it has. A 400-line file with one cohesive responsibility
is better than four 100-line files with tangled dependencies.

**Preserve existing tests.** Structural moves should not require test
rewrites. If moving a function to a new module breaks its tests, the test
was testing internal structure rather than behavior — fix the test to use
the public API.

**Individual transformations.** For micro-level refactoring steps (extract
function, introduce trait/protocol, replace inheritance with composition),
the user can invoke `/justin-tools:refactor` which provides a structured
methodology with characterization tests.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns
- [rust-patterns.md](rust-patterns.md) - Rust module splitting, crate
  extraction, compose structs, visibility
- [python-patterns.md](python-patterns.md) - Python package restructuring,
  circular import fixes, Protocol extraction
- [javascript-patterns.md](javascript-patterns.md) - JS/TS file splitting,
  barrel file removal, feature-based reorg

Load ONLY the file matching the detected project language. Never load
all three. For polyglot projects, load one file per analysis pass.
