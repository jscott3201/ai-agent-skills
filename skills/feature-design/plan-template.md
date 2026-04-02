# Plan Document Template

Use this structure when writing implementation plans in Stage 4.

```markdown
# [Feature] Implementation Plan

**Goal:** [One sentence - what this builds]
**Architecture:** [2-3 sentences about approach]
**Tech Stack:** [Key technologies/dependencies]

---

## Dependency Graph

[ASCII graph showing task dependencies and execution waves]

---

## Phase N: [Phase Name]

### Sub-phase NA: [Name]

**Depends on:** [What must be complete first]
**Produces:** [What this delivers]

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

- **Every task has complete code** - no pseudocode, no placeholders, no "implement similar to Task N"
- **Every file path is exact** - absolute within the project, not relative
- **Dependencies are explicit** - blocks/blocked-by on every task
- **Waves indicate parallelization** - tasks in the same wave have no shared state
- **Commit messages use conventional format** - `feat(scope): description`
- **Task granularity matches execution style:**
  - Primary agent: tasks can be larger, grouped by logical unit
  - Subagent-driven: tasks must be fully self-contained with all context a fresh agent needs to execute them independently
