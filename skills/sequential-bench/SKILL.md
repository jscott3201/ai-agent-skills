---
name: sequential-bench
description: >
  Run benchmarks sequentially (never parallel), track results, and flag
  regressions. Use when running cargo bench or any benchmarking task.
argument-hint: "[crate names]"
---

## Purpose

Enforce sequential benchmark execution to produce reliable numbers. Parallel
benchmark runs cause CPU/cache contention that inflates times by 15-40% and
produces high outlier rates. After running, compare against existing baselines
and flag regressions.

## Instructions

### 1. Discover benchmark targets

If `$ARGUMENTS` specifies crate names, use those directly. Otherwise, list
available benchmark crates:

```bash
cargo bench --workspace --no-run 2>&1 | grep -i compiling
```

Or check `Cargo.toml` workspace members for crates with `benches/` directories.

Present the list and confirm execution order with the user.

### 2. Run sequentially

Run one crate at a time. Never run `cargo bench --workspace` or launch
multiple benchmark processes simultaneously.

```bash
cargo bench -p crate-one
cargo bench -p crate-two
```

Chain with `&&` if running unattended. Report results after each crate
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
