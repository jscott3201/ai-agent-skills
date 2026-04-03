# Plan Verification Checklist

Complete checklist organized by automation level. Run mechanical checks
first (fast, deterministic), then semi-automated checks (tooling + review),
then human judgment checks.

## Mechanical checks (fully automatable)

These can be verified with grep, stat, and git commands. Run all of them.

### File system

- [ ] All "modify" file paths exist (`test -f <path>`)
- [ ] All "create" file paths do NOT already exist
- [ ] Parent directories for new files exist or are created in earlier tasks
- [ ] No file paths use relative references that could resolve ambiguously

### Symbols

- [ ] All function/method names referenced in the plan exist in the codebase
  (`grep -rn "fn <name>\|def <name>\|function <name>"`)
- [ ] All type/struct/trait/class names exist
  (`grep -rn "struct <name>\|class <name>\|trait <name>\|interface <name>"`)
- [ ] All module/crate/package names exist and can be imported

### Dependencies

- [ ] Every task ID in a "blocked-by" field exists in the plan
- [ ] Every task ID in a "blocks" field exists in the plan
- [ ] Dependency edges are symmetric (if A blocks B, B's blocked-by lists A)
- [ ] Topological sort succeeds (no circular dependencies)
- [ ] Every "blocked-by" task appears in an earlier wave than the blocked task

### Parallel safety

- [ ] No two tasks in the same wave modify the same file
- [ ] No dependency edges exist between tasks in the same wave
- [ ] Parallel tasks do not register conflicting resources (routes, types, etc.)

### Content completeness

- [ ] No "TBD", "TODO", "implement later" in plan text
- [ ] No "similar to Task N" (each task must be self-contained)
- [ ] No vague instructions without code ("add appropriate error handling")
- [ ] Every task has at least one verification step with an exact command
- [ ] Every task has a commit message in conventional format

### Staleness

- [ ] Referenced files have not changed since plan creation
  (`git log --oneline <plan-date>..HEAD -- <file>`)
- [ ] Working tree is clean (no uncommitted changes that could conflict)
- [ ] Referenced branches exist

## Semi-automated checks (tooling + human review)

These benefit from tooling but need human judgment for edge cases.

### Signatures

- [ ] Function parameter counts match actual definitions
- [ ] Parameter types match (watch for type aliases and lifetime differences)
- [ ] Return types match (watch for `Result<T, E>` vs `Option<T>` confusion)
- [ ] Generic constraints match
- [ ] No referenced functions have been deprecated since plan creation

### Data flow

- [ ] Call chain from entry point to modification site matches plan's claims
- [ ] Intermediate types at each step are compatible
- [ ] Ownership/mutability assumptions are correct (Rust: `&T` vs `&mut T`
  vs `T`, Python: mutable vs immutable)
- [ ] Import paths are valid for the module structure

### Test infrastructure

- [ ] Test files and directories referenced in the plan exist
- [ ] Test utilities, fixtures, or factories referenced exist
- [ ] Test commands in verification steps are correct for the project

## Human judgment checks

These require understanding of the project's context and cannot be automated.

- [ ] Plan's architectural approach matches the project's existing patterns
- [ ] Non-goals are reasonable and complete
- [ ] Risk mitigations are adequate for the identified risks
- [ ] Task granularity matches the execution style (subagent tasks are fully
  self-contained, primary agent tasks have appropriate scope)
- [ ] No missing side effects (database migrations, config changes,
  dependency additions, CI updates)
- [ ] No scope creep (tasks that implement things not in the requirements)
- [ ] No under-scoping (requirements that have no corresponding task)
