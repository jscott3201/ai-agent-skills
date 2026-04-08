---
name: crate-health
description: >
  Analyze Rust workspace health: compile times, dependency depth, circular
  deps, feature flag audit, dead code, test coverage. Use for periodic
  workspace maintenance.
disable-model-invocation: true
argument-hint: "[workspace path]"
---

## Purpose

Evaluate the health of a Rust workspace and produce a prioritized list of
maintenance tasks. Covers compile time analysis, dependency graph health,
feature flag audit, dead code detection, and test coverage assessment.

For evaluating specific dependency candidates, see `dep-audit`.

## Instructions

### 1. Dependency graph analysis

```bash
cargo tree --workspace
cargo tree -d  # duplicate crate versions
```

Check:
- **Depth:** aim for 4 or fewer levels. Deep chains are hard to audit.
- **Duplicates:** multiple versions of the same crate increase compile
  time and binary size. Flag any duplicates with major version differences.
- **Circular dependencies:** should not exist in a well-structured workspace.
  Verify with `cargo tree` or topological sort of internal crates.
- **Layering violations:** do bottom-layer crates (types, encoding) depend
  on top-layer crates (server, CLI)? This indicates an architectural issue.

### 2. Compile time analysis

```bash
cargo build --workspace --timings
```

Review the timing report:
- Which crates are the slowest to compile?
- Are any crates pulling in heavy dependencies unnecessarily?
- Could slow crates benefit from feature-gating heavy dependencies?
- Are procedural macros adding significant compile time?

### 3. Feature flag audit

For each crate in the workspace:

1. List all defined features in `Cargo.toml`
2. Check which features are actually used by downstream crates
3. Flag unused features (defined but never enabled)
4. Flag features that are always enabled (should they be default?)
5. Check for conflicting features (enabling both causes issues)
6. Verify `default` features are the minimal useful set

```bash
cargo tree -e features --workspace
```

### 4. Dead code detection

```bash
cargo clippy --workspace --all-features --all-targets -- -W dead_code
```

Look for:
- Unused public items (functions, types, traits never imported outside crate)
- Unused internal items flagged by the compiler
- Modules that are imported but whose contents are not used
- Test utilities that are no longer referenced

### 5. Test coverage assessment

```bash
cargo test --workspace --all-features -- --list 2>&1 | grep -c "test "
```

For each crate:
- Count tests (unit + integration)
- Identify crates with zero tests
- Check for modules with complex logic but no test coverage
- Note test patterns (are there integration tests? property tests?)

If `cargo-tarpaulin` or `cargo-llvm-cov` is available:
```bash
cargo tarpaulin --workspace --all-features --out Html
```

### 6. Unsafe code inventory

```bash
cargo geiger --all-features
```

If `cargo-geiger` is available, report:
- Which crates use unsafe code
- Whether unsafe blocks have safety comments
- Whether any unsafe usage could be replaced with safe alternatives

### 7. Produce health report

Save to `_agentskills/reviews/YYYY-MM-DD-workspace-health.md`:

```markdown
# Workspace Health Report

**Date:** YYYY-MM-DD
**Workspace:** [name]
**Crates:** [count]
**Total tests:** [count]

## Summary

| Metric | Status | Detail |
|--------|--------|--------|
| Dependency depth | OK/WARN/FAIL | Max depth: N |
| Duplicate crates | OK/WARN | N duplicates |
| Circular deps | OK/FAIL | None/Found |
| Compile time | OK/WARN | Slowest: Ns |
| Unused features | OK/WARN | N unused |
| Dead code | OK/WARN | N items |
| Test coverage | OK/WARN | N crates with 0 tests |
| Unsafe code | OK/WARN | N blocks |

## Prioritized Maintenance Tasks

1. [Highest priority task - what and why]
2. [Second priority - what and why]
...

## Detailed Findings

[Per-crate breakdown with specific findings]
```

Do not commit files in `_agentskills/` unless the user explicitly asks.

### 8. Triage maintenance tasks

After presenting the health report, walk through the prioritized
maintenance tasks **one at a time**:

1. For each task, present:
   - What the task involves and estimated effort (small/medium/large)
   - Expected impact (compile time, binary size, correctness, DX)
   - Your recommendation: **tackle now**, **defer**, or **skip**
2. Wait for the user's decision before presenting the next task
3. After all tasks are triaged, summarize the approved work:
   > "Approved N tasks. Start with [first task], or adjust the order?"

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Only check the crate I changed" | Workspace health is systemic. A dependency change in one crate affects compile times and audit surface across all crates. |
| "Duplicate crate versions are fine" | Each duplicate adds compile time and binary size. Two versions of `syn` can add 30+ seconds to a clean build. |
| "Feature flags are correct by construction" | Feature combinations grow exponentially. Unintended feature interactions cause the bugs that single-feature testing misses. |
| "Dead code will be cleaned up later" | Dead code accumulates. It increases grep noise, confuses onboarding, and masks actual usage patterns. |

## Red Flags

Stop and reassess if you observe:
- Skipping dependency depth analysis
- Ignoring duplicate crate versions without checking compile time impact
- Not running with `--all-features` for completeness
- Reporting findings without prioritization

## Verification

- [ ] Dependency graph analyzed (duplicates, depth, single-maintainer)
- [ ] Compile time profiled
- [ ] Feature flags audited
- [ ] Health report produced with prioritized maintenance tasks

## Guidance

**Run periodically, not once.** Workspace health drifts. A quarterly health
check catches issues before they compound.

**Prioritize by developer impact.** A 30-second compile time improvement
that saves every developer time daily is higher priority than removing
one unused function.

**Duplicate crates are the most common workspace issue.** When two crates
depend on different major versions of the same dependency, both versions
compile and ship. This is often fixable by aligning version requirements.
