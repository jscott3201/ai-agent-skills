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

**Preferred invocation:** Delegate to the `test-engineer` agent, which has
this skill and `technical-writing` preloaded with persistent memory.

## Instructions

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

### 5. Generate test code

Write complete, runnable test code. Follow the project's existing test
patterns (check how existing tests are structured before writing new ones).

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

**Python test structure:**
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
])
def test_parse_variants(input, expected):
    assert parse(input) == expected
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

### 8. Mutation testing (advanced)

Use mutation testing to find tests that pass even when code is wrong:

**Rust:** `cargo mutants` - finds functions whose body could be replaced
without failing any test. No setup or nightly compiler needed.

**Python:** `mutmut` - mutates code and checks if tests catch it.

Run on changed files incrementally in CI, not on the full codebase.
Focus on functions with complex logic, not getters or simple wrappers.

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

**Follow existing test patterns.** Read how the project structures its
tests (inline `#[cfg(test)]` vs separate files, fixtures, helpers) and
match the convention.

**Quarantine flaky tests immediately.** A flaky test that is normalized
wastes developer hours and erodes trust in the entire suite. Fix or
remove it.
