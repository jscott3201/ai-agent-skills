---
name: refactor
description: >
  Structured refactoring: identify smell, plan transformation, execute with
  verification at each step, confirm no behavioral changes. Includes a
  Rust-specific refactoring catalog.
disable-model-invocation: true
argument-hint: "[what to refactor]"
---

## Purpose

Guide safe refactoring through a structured process: identify the problem,
plan the transformation, execute incrementally with verification at each
step, and confirm no behavioral changes via tests.

For structural changes at file or module level (splitting, reorganizing,
crate extraction), see `modularize` instead.

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior refactoring context:

1. **Create session** with `skill: 'refactor'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior refactoring work on this code:
   - Prior `:Decision` nodes from refactor sessions on same `:CodeLocation`
   - Prior smell identifications and transformation outcomes
   - Any `:DeferredItem` nodes related to tech debt in this area

3. If prior refactoring context exists:

> "Prior refactor context:
> - [This module was refactored N times — last on date for smell]
> - [Any deferred refactoring items in this area]
>
> Recurring refactoring in the same module may indicate a deeper structural
> issue (consider `modularize` instead)."

If no prior context exists, skip silently.

### 1. Identify the smell

From `$ARGUMENTS` or by analyzing the code, identify what needs refactoring:

| Smell | Symptoms | Typical Fix |
|:--|:--|:--|
| **Long function** | >50 lines, multiple concerns | Extract functions |
| **God module** | Module does too many things | Split into focused modules |
| **Duplicate logic** | Same pattern in 3+ places | Extract shared function/trait |
| **Leaky abstraction** | Internal details exposed to consumers | Introduce interface/trait |
| **Primitive obsession** | Strings/ints used instead of types | Introduce domain types |
| **Deep nesting** | 4+ levels of if/match/for | Early returns, extract helpers |
| **Large crate** | Crate has too many responsibilities | Split into workspace crates |
| **Overly coupled** | Changes in A always require changes in B | Introduce abstraction boundary |

### 2. Write characterization tests

Before changing anything, ensure the current behavior is captured:

1. Check existing test coverage for the code being refactored
2. If coverage is thin, write characterization tests that capture
   the current behavior (even if that behavior is wrong)
3. Run all tests to establish a green baseline

**Characterization tests protect against accidental behavior changes.**
They can be updated after the refactoring if the behavior should change,
but during the refactoring they must stay green.

**Technique:** Write tests with guessed assertions, run to see actual
outputs, update assertions to match observed behavior. In Rust, `insta`
snapshot tests are effective for capturing complex output. The goal is to
lock current behavior, whether correct or not.

### 3. Plan the transformation

Describe the refactoring as a sequence of small, independently verifiable
steps. Each step should:

- Make one logical change
- Keep the code compiling at each step
- Keep all tests passing at each step
- Be small enough to revert if it goes wrong

Example plan:
```
1. Extract helper function `validate_input()` from `process()`
2. Move `validate_input()` to its own module `validation.rs`
3. Replace duplicate validation in `process_batch()` with `validate_input()`
4. Update tests to use `validate_input()` directly for edge cases
```

Get the user's approval on the plan before executing.

#### Graph write: refactoring decision (SeleneDB)

After the user approves the transformation plan:

```gql
INSERT (d:Decision {
  summary: $smell_type + ': ' + $transformation_summary,
  rationale: $why_this_approach,
  alternatives: $other_approaches_considered,
  confidence: 'high'
})
RETURN id(d) AS decision_id

MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(d)

MERGE (loc:CodeLocation {file: $file, function: $function})
INSERT (d)-[:affects]->(loc)
```

### 4. Execute incrementally

For each step:

1. Make the change
2. Run `cargo check` (or equivalent) to verify compilation
3. Run the full test suite to verify no behavioral changes
4. Commit the step with a descriptive message:
   `refactor(module): extract validate_input from process`

**If a step breaks tests:** revert immediately and re-examine the plan.
Do not try to fix forward during a refactoring step.

### 5. Verify the result

After all steps are complete:

1. Run the full CI verification sequence
2. Compare the public API: has it changed? If so, was that intentional?
3. Verify the code reads better: is the smell resolved?
4. Check that no new smells were introduced

### Rust refactoring patterns

| Pattern | From | To | Key Concern |
|:--|:--|:--|:--|
| **Extract module** | Large `lib.rs` | `mod x;` in separate file | Re-export public items |
| **Split crate** | One crate with many concerns | Workspace with focused crates | Dependency direction |
| **Sync to async** | `fn process()` | `async fn process()` | All callers must be updated |
| **Concrete to trait** | `fn process(db: &Database)` | `fn process(db: &impl Storage)` | Define trait, impl for concrete |
| **Error type redesign** | Scattered error types | Unified `Error` enum | Conversion chains, see `error-catalog` |
| **String to newtype** | `fn process(id: String)` | `fn process(id: UserId)` | Validation, Display, From impls |
| **Remove wildcard arms** | `_ => ...` in match | Explicit handling per variant | Use `no-shortcuts` skill |

### Python refactoring patterns

| Pattern | From | To | Key Concern |
|:--|:--|:--|:--|
| **Extract function** | Long function with comments | Named functions per section | Keep parameter count low |
| **Replace dict with dataclass** | `config["timeout"]` | `config.timeout` | Type safety, IDE support |
| **Sync to async** | `def process()` | `async def process()` | All callers need `await` |
| **Protocol instead of ABC** | `class Base(ABC)` | `class Proto(Protocol)` | Structural typing, no inheritance |
| **Replace inheritance with composition** | Deep class hierarchy | Composed objects with protocols | Reduce coupling |
| **Move to package** | Single `module.py` | `module/__init__.py` + files | Re-export from `__init__` |
| **Type annotations** | Untyped code | Full type hints + `py.typed` | Gradual typing, run `mypy` |

### JavaScript/TypeScript refactoring patterns

| Pattern | From | To | Key Concern |
|:--|:--|:--|:--|
| **Extract module** | Large file | Named exports in separate files | Barrel file re-exports |
| **JS to TypeScript** | `.js` files | `.ts` with type annotations | Gradual migration with `allowJs` |
| **Callback to async/await** | Nested callbacks | `async/await` chain | Error handling with try/catch |
| **Class to function** | `class Service` | Module with exported functions | Simpler testing, tree-shaking |
| **Replace any with types** | `any` everywhere | Specific types and generics | Use `unknown` as intermediate |
| **Monolith to packages** | Single package.json | Workspace with packages | Internal dependencies |
| **Replace lodash with native** | `_.map`, `_.filter` | Array methods, `Object.entries` | Bundle size reduction |

### Refactor vs rewrite

| Factor | Refactor | Rewrite |
|:--|:--|:--|
| Tests exist for current behavior | Refactor | Either |
| No tests exist | Write tests, then refactor | Rewrite may be faster |
| Fundamental architecture is wrong | Cannot refactor around it | Rewrite |
| 70%+ of the code is fine | Refactor the rest | Do not rewrite |
| External API must be preserved | Refactor internals | Rewrite with same API |

**Default to refactoring.** Rewrites look attractive but take 2-3x longer
than expected and introduce new bugs. Refactoring preserves working code
and existing tests.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "I understand the code, skip characterization tests" | Understanding is not verification. Characterization tests catch the behaviors you didn't notice. |
| "Multiple smells, fix them all in one pass" | Interleaved changes mask which refactoring broke what. One smell at a time keeps each step verifiable. |
| "Straightforward change, skip the plan" | "Straightforward" is where overconfidence hides. A 2-minute plan catches cascading impacts. |
| "Refactor while adding the feature to save time" | Mixed commits are unrevertable. If the feature is reverted, the refactoring goes with it. |
| "Cleaner code, skip full test suite rerun" | Cleaner ≠ correct. Refactoring changes structure; tests verify behavior survived. |

## Red Flags

Stop and reassess if you observe:
- Making changes without characterization tests in place
- A refactoring step that doesn't compile or breaks tests
- Fixing multiple smells in a single pass
- Adding new features while refactoring
- Skipping user approval on the transformation plan

## Verification

- [ ] Characterization tests written before any changes
- [ ] Each step compiles and passes tests before the next step
- [ ] Public API unchanged (or changes are intentional and documented)
- [ ] Original smell resolved
- [ ] Full CI verification passes

## Guidance

**Never refactor without tests.** If tests do not exist, write
characterization tests first. The cost of writing tests is less than the
cost of introducing a subtle behavioral change during refactoring.

**Small steps that compile.** Each step must leave the code in a
compilable, test-passing state. If a step cannot be made small enough,
the refactoring plan needs to be decomposed further.

**Chesterton's Fence.** Before removing or rewriting code, understand why
it was written that way. Code that looks unnecessary may be handling an
edge case, working around a dependency bug, or satisfying a requirement
that isn't obvious. Characterization tests help reveal these hidden reasons.

**One smell at a time.** Resist the urge to fix everything at once.
Fix the identified smell, commit, and then decide if another pass is
needed.

**Refactoring is not the time to add features.** If a feature idea
surfaces during refactoring, defer it (use `deferred-tracking`).
Mixing refactoring and feature work makes it impossible to verify
"no behavioral change."

**SeleneDB reveals refactoring patterns.** If the same module is
refactored repeatedly, the graph shows it. Recurring refactoring points
to a structural issue that `modularize` should address, not another
incremental fix.
