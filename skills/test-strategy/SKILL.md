---
name: test-strategy
description: >
  Test planning and generation: analyze code, identify untested paths,
  generate test cases with boundary analysis. Includes coverage gap
  detection and property-based testing guidance.
argument-hint: "[module or feature to test]"
---

## Purpose

Analyze code and produce a comprehensive test plan: what to test, which
test types to use, and concrete test code. Includes coverage gap analysis
for existing tests and property-based testing strategies.

This is an interactive skill. Present the test plan for approval, then
generate tests incrementally per function group with user review at each
step.

**When NOT to use:** The user is asking you to run existing tests (just
run them). The user wants a quick one-off test for something they're
exploring (just write it). The code under test is being actively
refactored (wait until the refactoring stabilizes).

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior test coverage context:

1. **Create session** with `skill: 'test-strategy'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior analysis of this module:
   - Prior `:CoverageGap` nodes linked to `:CodeLocation` nodes in scope
   - Whether previously identified gaps were addressed (`addressed: true`)
   - Any `:Finding` nodes from deep-review in this module (review findings
     often indicate where tests should exist)

3. If prior coverage data exists, present it:

> "Prior test context for this module:
> - [N] coverage gaps previously identified, [N] addressed
> - Recurring gap types: [top categories]
> - [Any deep-review findings suggesting missing tests]
>
> I'll factor these into the test plan."

If no prior context exists, skip silently.

### 1. Analyze the target

For the target module or feature (`$ARGUMENTS`):

1. Read the code and identify all public functions and methods
2. For each, identify: input types, output types, error conditions,
   side effects, invariants
3. Read existing tests and note what is already covered

### 2. Identify test categories

For each function/behavior, determine which test categories apply:

| Category | What it tests | When to use |
|:--|:--|:--|
| **Happy path** | Normal inputs produce expected output | Always |
| **Edge cases** | Boundary values (0, 1, max, empty, null) | Always |
| **Error paths** | Invalid input produces correct error | For functions returning Result/Option |
| **Boundary values** | At limits of valid ranges | For numeric inputs, collections |
| **State transitions** | Before/after state changes | For stateful operations |
| **Concurrency** | Thread safety, race conditions | For shared mutable state |
| **Property-based** | Invariants hold for random inputs | For pure functions, codecs, parsers |
| **Integration** | Components work together correctly | For cross-module interactions |
| **Visual regression** | UI renders correctly after changes | For components with visual output |
| **Component** | UI components in isolation | For React/Vue/Svelte components |
| **Accessibility** | WCAG compliance, screen reader support | For user-facing UI |

### 3. Apply boundary value analysis

For each input parameter, test at these points:

- **Minimum valid value** (0, empty string, empty vec)
- **Just above minimum** (1, single char, single element)
- **Typical value** (representative normal input)
- **Just below maximum** (max - 1)
- **Maximum valid value** (u32::MAX, capacity limit)
- **Just above maximum** (overflow, over capacity)
- **Invalid values** (negative for unsigned, null, wrong type)

### 4. Generate test plan

For each untested or under-tested area:

```markdown
### [Function/Behavior Name]

**Current coverage:** [what existing tests cover]
**Gaps:** [what is not tested]

**New tests:**
1. `test_[name]_[scenario]` - [what it verifies]
2. `test_[name]_[edge_case]` - [what it catches]
3. `test_[name]_[error_path]` - [what error it expects]
```

### 4b. Present plan for approval

Present the test plan to the user before writing any test code:

> "Test plan ready. Summary:
> - N new tests across M functions
> - Covers: [categories included]
> - Estimated: [rough count] lines of test code
>
> Options:
> 1. **Proceed** - generate all test code as planned
> 2. **Adjust** - modify the plan (add/remove tests, change priorities)
> 3. **Subset** - focus on a specific function or category first
>
> I recommend proceeding with the full plan. Your call."

Wait for the user's decision before generating test code.

### 5. Generate test code incrementally

Generate tests one function or behavior group at a time. Do not batch
generate all tests at once.

For each group in the approved plan:

1. Write the tests for that function/behavior
2. Present the generated tests to the user:

> "[Function name]: N tests covering [categories].
> [Show the test code]
>
> Options:
> 1. **Accept** - keep these tests, move to next group
> 2. **Adjust** - modify approach for this group (explain what to change)
> 3. **Skip** - drop this group, move to next
>
> I recommend accepting. [Brief rationale if relevant.]"

3. Wait for user decision before generating the next group
4. Run each accepted group immediately to verify it passes

#### Graph write: test group decision (SeleneDB)

After each user decision on a test group:

For **accepted** groups, record the coverage gaps that were addressed:

```gql
MATCH (g:CoverageGap)-[:covers]->(loc:CodeLocation {function: $function})
WHERE g.addressed = false
SET g.addressed = true
```

For **skipped** groups, the `:CoverageGap` nodes remain with
`addressed: false` — they persist for future sessions.

This incremental approach catches mismatches early. If the first group's
style or approach is wrong, the user corrects before N more groups are
generated the same way.

Follow the project's existing test patterns (check how existing tests are
structured before writing new ones).

**Rust test structure:**
```rust
#[test]
fn test_parse_valid_input() {
    let result = parse("valid input");
    assert_eq!(result, Ok(Expected { ... }));
}

#[test]
fn test_parse_empty_input() {
    let result = parse("");
    assert!(matches!(result, Err(Error::EmptyInput)));
}
```

**Property-based tests (Rust/proptest):**
```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn roundtrip_encode_decode(input in any::<Vec<u8>>()) {
        let encoded = encode(&input);
        let decoded = decode(&encoded).unwrap();
        prop_assert_eq!(input, decoded);
    }
}
```

**Python test structure (pytest):**
```python
def test_parse_valid_input():
    result = parse("valid input")
    assert result == Expected(...)

def test_parse_empty_input():
    with pytest.raises(ValueError, match="empty"):
        parse("")

@pytest.mark.parametrize("input,expected", [
    ("a", Result.A),
    ("b", Result.B),
], ids=["variant_a", "variant_b"])
def test_parse_variants(input, expected):
    assert parse(input) == expected
```

**JavaScript/TypeScript test structure (Jest/Vitest):**
```typescript
test('parse valid input', () => {
  const result = parse('valid input');
  expect(result).toEqual({ ... });
});

test('parse empty input throws', () => {
  expect(() => parse('')).toThrow('empty');
});

test.each([
  ['a', Result.A],
  ['b', Result.B],
])('parse variant %s', (input, expected) => {
  expect(parse(input)).toBe(expected);
});
```

### 6. Property-based testing guidance

Use property-based tests when:
- A function has an inverse (encode/decode, serialize/deserialize)
- An invariant should hold for all valid inputs
- Edge cases are hard to enumerate manually

**Common properties:**
- **Roundtrip:** `decode(encode(x)) == x`
- **Idempotence:** `f(f(x)) == f(x)`
- **Commutativity:** `f(a, b) == f(b, a)` (when expected)
- **Invariant preservation:** `invariant(x)` implies `invariant(f(x))`
- **No crash:** `f(random_input)` does not panic
- **Oracle comparison:** compare fast implementation against known-correct slow one

**Python (Hypothesis):**
```python
from hypothesis import given, strategies as st

@given(data=st.binary())
def test_roundtrip(data):
    assert decode(encode(data)) == data
```

**JavaScript (fast-check):**
```typescript
import fc from 'fast-check';

test('roundtrip', () => {
  fc.assert(fc.property(fc.uint8Array(), (data) => {
    expect(decode(encode(data))).toEqual(data);
  }));
});
```

### 7. Coverage gap analysis

When asked to analyze existing test coverage:

1. List all public functions in the module
2. For each, check if at least one test exercises it
3. For tested functions, check if edge cases and error paths are covered
4. Report gaps:

```
Coverage Gaps:
- parse(): no test for empty input
- validate(): no test for unicode input
- process(): error path for timeout not tested
- batch(): no test for concurrent access
```

#### Graph write: coverage gaps (SeleneDB)

When coverage gaps are identified, write each to the graph:

```gql
INSERT (g:CoverageGap {
  function: $function_name,
  gap_type: $category,
  description: $gap_description,
  addressed: false
})
RETURN id(g) AS gap_id

MERGE (loc:CodeLocation {file: $file, function: $function_name})
MATCH (g:CoverageGap) WHERE id(g) = $gap_id
INSERT (g)-[:covers]->(loc)

MATCH (s:Session) WHERE id(s) = $session_id
INSERT (s)-[:produced]->(g)
```

These gaps persist across sessions. When `test-strategy` runs again
on the same module, auto-recall shows which gaps remain unaddressed.

### 8. Mutation testing (advanced)

Use mutation testing to find tests that pass even when code is wrong:

**Rust:** `cargo mutants` - finds functions whose body could be replaced
without failing any test. No setup or nightly compiler needed.

**Python:** `mutmut` - mutates code and checks if tests catch it.

Run on changed files incrementally in CI, not on the full codebase.
Focus on functions with complex logic, not getters or simple wrappers.

### 9. Visual and UI testing (frontend)

Apply these categories when the target includes user-facing UI. Skip
this section for backend-only code.

#### Visual regression testing

Capture screenshots and compare against baselines to catch unintended
visual changes.

**Playwright screenshot comparison:**
```typescript
test('dashboard renders correctly', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixelRatio: 0.01,
  });
});
```

**When to use:** after CSS changes, component library upgrades, layout
refactors, or responsive design work. Not useful for logic-only changes.

**Update baselines deliberately:** failing visual tests mean either a bug
or an intentional change. Review the diff, then update the baseline with
`--update-snapshots` if the change is correct.

#### Component testing

Test UI components in isolation with realistic props and user interaction.

**React Testing Library:**
```typescript
import { render, screen, fireEvent } from '@testing-library/react';

test('search filters results on input', async () => {
  render(<SearchPanel items={mockItems} />);
  await fireEvent.change(screen.getByRole('searchbox'), {
    target: { value: 'query' },
  });
  expect(screen.getAllByRole('listitem')).toHaveLength(2);
});
```

**Storybook + interaction tests:**
```typescript
export const WithError: Story = {
  args: { error: 'Invalid input' },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole('alert')).toBeVisible();
  },
};
```

**When to use:** for components with conditional rendering, user
interaction, or complex state. Not needed for pure display components
with no logic.

#### Accessibility testing

Automated WCAG compliance checks catch common issues (missing labels,
insufficient contrast, keyboard traps). They do not replace manual
testing but catch the low-hanging fruit.

**Playwright + axe-core:**
```typescript
import AxeBuilder from '@axe-core/playwright';

test('login page has no a11y violations', async ({ page }) => {
  await page.goto('/login');
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

**Jest + jest-axe:**
```typescript
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

test('form is accessible', async () => {
  const { container } = render(<LoginForm />);
  expect(await axe(container)).toHaveNoViolations();
});
```

**When to use:** for all user-facing pages and interactive components.
Run in CI on every PR that touches frontend code. Focus on: forms,
navigation, modals/dialogs, and dynamic content.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "First group passed, I can batch the rest" | Pattern match ≠ correctness. Each group tests different logic; incremental review catches mismatches early. |
| "Boundary value analysis is exhaustive — just test critical cases" | Boundaries are where bugs cluster. Skipping min/max/off-by-one misses the defects unit tests exist to catch. |
| "Property-based testing is for math, not domain logic" | Property tests find the edge cases you didn't think to write. Domain logic has invariants too. |
| "Existing tests cover happy path, focus on errors only" | Happy-path tests may assert the wrong thing. Verify what exists before extending. |

## Red Flags

Stop and reassess if you observe:
- Generating all tests at once instead of incrementally
- No boundary value analysis for numeric inputs
- Tests that assert on implementation details (private methods, internal state)
- Skipping property-based tests for functions with clear invariants

## Verification

- [ ] Test plan approved by user before code generation
- [ ] Each test group reviewed and accepted incrementally
- [ ] All accepted tests pass when run
- [ ] Coverage gaps identified and documented

## Guidance

**Test behavior, not implementation.** Tests that verify public behavior
survive refactoring. Tests that verify private implementation details
break on every change.

**One assertion per test (where practical).** When a test fails, the name
and assertion should tell you exactly what broke without reading the test.

**Property tests complement unit tests.** Unit tests cover known edge
cases. Property tests discover unknown ones. Use both.

**Mutation testing finds what coverage misses.** 85% statement coverage
can have 60% branch coverage. Mutation testing reveals whether tests
actually detect changes to behavior.

**The Beyonce Rule.** If you liked it, you should have put a test on it.
Any behavior worth relying on is worth testing. If a behavior isn't
tested, it will eventually be broken by someone who doesn't know it
matters.

**Follow existing test patterns.** Read how the project structures its
tests (inline `#[cfg(test)]` vs separate files, fixtures, helpers) and
match the convention.

**Quarantine flaky tests immediately.** A flaky test that is normalized
wastes developer hours and erodes trust in the entire suite. Fix or
remove it.

**SeleneDB creates a coverage memory.** Gaps identified but not addressed
persist in the graph. Future test-strategy sessions start with "these gaps
are still open" instead of rediscovering them. Deep-review findings also
feed in — if a reviewer flagged "missing error path test," that appears
in the next test-strategy session for that module.
