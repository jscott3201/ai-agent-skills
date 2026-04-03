# Plan Document Template

Use this structure when writing implementation plans in Stage 4.

## Plan header

```markdown
# [Feature] Implementation Plan

**Goal:** [One sentence - what this builds]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies/dependencies]
**Complexity:** [Small / Medium / Large]
**Estimated phases:** [N phases, ~N tasks total]

## Non-Goals

- [What this plan explicitly does NOT address]
- [Adjacent features that are out of scope]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [What could go wrong] | Low/Med/High | [What happens] | [How to handle it] |

## Rollback Strategy

[If this feature needs to be reverted, how? Is it a single revert commit,
or does it require data migration? Note any points of no return.]
```

## Dependency graph

```markdown
## Dependency Graph

[ASCII graph showing task dependencies and execution waves]

Wave 1 (parallel):  [T1: data model]  [T2: config schema]
                          |                 |
Wave 2:             [T3: core logic (depends on T1)]
                          |
Wave 3:             [T4: API endpoint (depends on T3)]
                          |
Wave 4:             [T5: integration tests (depends on T3, T4)]
```

## Phase structure

```markdown
## Phase N: [Phase Name]

**Exit criteria:**
- [ ] [Specific, mechanically verifiable condition]
- [ ] [All tests in this phase pass]
- [ ] [Feature X is callable from Y with correct results]

**Test strategy:**
- Unit tests: [What gets unit tested and where]
- Integration tests: [What integration scenarios to cover]
- Verification commands: [Exact commands to confirm phase is complete]

### Sub-phase NA: [Name]

**Depends on:** [What must be complete first]
**Produces:** [What this delivers - a function, a module, an endpoint]
```

## Task structure

```markdown
#### Task N: [Task Name]

**Blocks:** [Tasks that depend on this]
**Blocked by:** [Tasks that must finish first]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing/file`

- [ ] **Step 1: [Action]**

[Complete code block - actual implementation, not pseudocode]

- [ ] **Step 2: [Action]**

[More complete code]

- [ ] **Step 3: Verify**

[Exact commands with expected output]

- [ ] **Step 4: Commit**

[Exact commit message in conventional format]
```

## Plan requirements

### Code completeness

- **Every task has complete code** - no pseudocode, no placeholders, no
  "implement similar to Task N"
- **Every file path is exact** - absolute within the project, not relative
- **Verification steps have exact commands** with expected output so success
  is mechanically verifiable

### Task sizing

Keep each task to a **single logical unit**: one function, one component, one
API endpoint. Research shows:
- Single-function tasks: ~87% accuracy
- Multi-file tasks (4+ files, ~100+ lines): drops below 25%

When a change is inherently cross-cutting, structure it as a sequence of
focused tasks rather than one large task.

### Dependencies

- **blocks/blocked-by on every task** - no implicit ordering
- **Waves indicate parallelization** - tasks in the same wave have no shared
  state and can run concurrently
- **No circular dependencies** - the dependency graph is a DAG

### Execution style adaptation

- **Primary agent:** tasks can be larger, grouped by logical unit. Can
  reference earlier conversation context.
- **Subagent-driven:** tasks must be fully self-contained with ALL context
  a fresh agent needs: file paths, API signatures, data shapes, conventions,
  exact verification commands. A subagent starts with zero knowledge of
  prior tasks.
- **Parallel agents:** tasks must specify exactly which files are touched.
  No two parallel tasks can modify the same file.

### Commit discipline

- **Commit messages use conventional format** - `feat(scope): description`
- **One commit per task** (default) or per sub-phase if tasks are very small
- **Each commit produces a working state** - no "WIP" commits that break
  the build

### Exit criteria

Every phase must have exit criteria that are:
- **Specific** - "search returns results ranked by relevance" not "search works"
- **Verifiable** - can be checked with a command, test, or inspection
- **Complete** - cover all the phase's deliverables, not just the happy path
