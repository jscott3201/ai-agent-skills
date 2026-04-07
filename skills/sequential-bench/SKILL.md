---
name: sequential-bench
description: >
  Run benchmarks sequentially (never parallel), track results, and flag
  regressions. Use when running benchmarks for Rust, Python, or JavaScript
  projects.
argument-hint: "[package names]"
---

## Purpose

Enforce sequential benchmark execution to produce reliable numbers. Parallel
benchmark runs cause CPU/cache contention that inflates times by 15-40% and
produces high outlier rates. After running, compare against existing baselines
and flag regressions.

**When NOT to use:** The user wants quick timing of a single operation
(just use `time` or `std::time::Instant`). The project has no benchmark
suite. The user is profiling for hot spots (use `perf-profile`).

## Instructions

### 1. Discover benchmark targets

If `$ARGUMENTS` specifies package names, use those directly. Otherwise,
discover available benchmarks for the project language.

**Rust:**
```bash
cargo bench --workspace --no-run 2>&1 | grep -i compiling
```
Or check `Cargo.toml` workspace members for crates with `benches/` directories.

**Python:**
```bash
# pytest-benchmark
pytest --collect-only -q **/test_*bench*.py **/bench_*.py 2>/dev/null
# Or check for benchmark files:
find . -name "*bench*" -name "*.py" -not -path "*/node_modules/*"
```

**JavaScript/TypeScript:**
```bash
# vitest bench
npx vitest bench --run --reporter=verbose 2>/dev/null || true
# Or check for benchmark files:
find . -name "*.bench.*" -not -path "*/node_modules/*"
```

Present the list and confirm execution order with the user.

### 2. Run sequentially

Run one package/suite at a time. Never run all benchmarks simultaneously.

**Rust:**
```bash
cargo bench -p crate-one
cargo bench -p crate-two
```

**Python (pytest-benchmark):**
```bash
pytest tests/bench_module_one.py --benchmark-only
pytest tests/bench_module_two.py --benchmark-only
```

**JavaScript/TypeScript (vitest):**
```bash
npx vitest bench src/module-one.bench.ts --run
npx vitest bench src/module-two.bench.ts --run
```

Chain with `&&` if running unattended. Report results after each suite
completes before proceeding to the next.

### 3. Compare against baselines

After all benchmarks complete:

1. Read the existing `Benchmarks.md` (or equivalent results file)
2. Diff each metric against the previous baseline
3. Flag any regression greater than 10% with a clear comparison:

```
REGRESSION: expand_two_hop
  Previous: 142 us
  Current:  198 us
  Change:   +39.4%
```

4. Also note significant improvements (>10% faster) for visibility

### 3b. Triage regressions with user

If regressions were found, present each one **one at a time**:

1. For each regression, present:
   - The benchmark, previous value, current value, and percentage change
   - Possible causes (recent changes, environmental factors)
   - Options: **investigate** (dig into the cause), **accept** (intentional
     tradeoff), or **re-run** (confirm it is not noise)
2. Wait for the user's decision before presenting the next regression
3. After all regressions are triaged, proceed to update the results file
   with annotations for accepted regressions

### 4. Update results file

Update `Benchmarks.md` with the new numbers from this sequential run.
Include:

- Date of the run
- Hardware/environment if different from previous
- All metrics with current values
- Flag any regressions inline

Only use numbers from this sequential run. Never mix numbers from different
runs or parallel executions.

## Guidance

The 10% regression threshold accounts for normal run-to-run variance on
consumer hardware. If a benchmark shows 8-12% variance between clean runs,
the threshold may need adjusting for that specific benchmark - note this
when reporting.

If a regression is flagged, do not automatically assume it needs fixing.
Report it and let the user decide. Some regressions are acceptable tradeoffs
for correctness or new functionality.
