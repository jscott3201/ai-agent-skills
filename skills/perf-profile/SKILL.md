---
name: perf-profile
description: >
  Performance investigation: establish baseline, identify hot spots, form
  hypotheses, optimize, verify no regression. Includes instrumentation
  guidance. Use when investigating why something is slow.
disable-model-invocation: true
argument-hint: "[what is slow]"
---

## Purpose

Guide systematic performance investigation rather than guesswork. Define
the performance question, establish a baseline, identify hot spots, form
hypotheses, implement targeted optimizations, and verify no regressions.
Also supports adding observability instrumentation to code.

Use `sequential-bench` to run benchmarks reliably. For broader
investigation including profiling and optimization, use this skill.

## Instructions

### 1. Define the question

From `$ARGUMENTS`, clarify:
- **What is slow?** Specific operation, endpoint, or workload
- **How slow?** Current measurement (or "we don't know yet")
- **Target?** What performance is acceptable?
- **Environment?** Hardware, data size, concurrency level

If no baseline measurement exists, establish one first.

### 2. Establish baseline

Run the relevant benchmark or timing measurement. Record:

```
Baseline: [operation] at [data size] on [hardware]
  Latency: p50=[X], p99=[Y]
  Throughput: [N] ops/sec
  Memory: [N] MB peak
  Date: YYYY-MM-DD
```

Use the `sequential-bench` skill for Criterion benchmarks. For ad-hoc
measurements, use `std::time::Instant` (Rust), `time.perf_counter()`
(Python), or `performance.now()` (JavaScript).

### 3. Profile and identify hot spots

**Rust profiling:**
```bash
# Flamegraph (requires cargo-flamegraph)
cargo flamegraph --bench <bench_name> -- --bench

# Allocation profiling (requires DHAT)
# Add dhat = "0.3" to dev-dependencies, instrument with #[global_allocator]

# Criterion detailed report
cargo bench -p <crate> -- --profile-time 10
```

**Python profiling:**
```bash
python -m cProfile -o profile.out script.py
python -m py-spy record -o flame.svg -- python script.py
```

**JavaScript profiling:**
```bash
node --prof script.js
node --prof-process isolate-*.log > profile.txt
```

Look for:
- Functions consuming >10% of total time
- Unexpected allocation patterns (allocation in hot loops)
- I/O blocking async code
- Cache misses in data-heavy operations

### 4. Form hypotheses

For each hot spot, hypothesize why it is slow:

| Hot Spot | Hypothesis | Expected Impact |
|----------|-----------|-----------------|
| `expand_nodes()` | HashMap lookup per node, O(n) | Batch lookup: 2-3x faster |
| `serialize()` | Allocates String per field | Pre-allocated buffer: 30% faster |

Rank by expected impact. Start with the highest.

### 4b. Confirm test order with user

Present hypotheses to the user **one at a time**, starting with the highest
expected impact:

1. For each hypothesis, present:
   - The hot spot and hypothesis
   - Expected impact if confirmed
   - What the test involves (effort, risk)
2. Ask: **test this**, **skip**, or **reorder**
3. Wait for the user's decision before proceeding

> "I have N hypotheses ranked by expected impact. Starting with the highest:
>
> **Hypothesis 1:** [hot spot] - [hypothesis]
> Expected impact: [estimate]
> Test: [what you would do]
>
> Test this one first, skip, or reorder?"

### 5. Optimize and measure

For each optimization:

1. Implement the change
2. Run the same benchmark as baseline
3. Compare: did it improve? By how much?
4. Check for regressions in related benchmarks

```
Optimization: [description]
  Before: p50=[X], p99=[Y], [N] ops/sec
  After:  p50=[X'], p99=[Y'], [N'] ops/sec
  Change: [+/-]N% latency, [+/-]N% throughput
```

If an optimization did not help, revert it. Do not keep speculative
optimizations.

### 6. Verify no regressions

After all optimizations:

1. Run the full benchmark suite via `sequential-bench`
2. Compare all metrics against pre-optimization baselines
3. Flag any regressions >10% in unrelated benchmarks

### Instrumentation mode

When asked to add observability rather than investigate a specific issue:

**Rust (tracing + OpenTelemetry):**
```rust
use tracing::{info, instrument, warn};

#[instrument(skip(graph), fields(node_count = graph.len()))]
pub fn execute_query(graph: &Graph, query: &str) -> Result<Vec<Row>> {
    info!("executing query");
    // ...
}
```

**Guidelines for instrumentation:**
- Add `#[instrument]` to public functions at API boundaries
- Skip large arguments with `skip(data)`, record summary fields
- Use `info!` for business events, `debug!` for technical details
- Add timing spans around I/O operations and external calls
- Include context fields: request_id, user_id, operation name
- Do not log sensitive data (use the `safety-checks` skill's rules)

Save performance investigation results to
`_agentskills/reviews/YYYY-MM-DD-perf-<topic>.md`.
Do not commit files in `_agentskills/` unless the user explicitly asks.

## Guidance

**Measure before optimizing.** Intuition about what is slow is frequently
wrong. Profile first, then optimize the measured hot spot.

**One change at a time.** If you make three optimizations simultaneously,
you cannot attribute the improvement (or regression) to any specific change.

**Optimize the algorithm before the implementation.** An O(n^2) algorithm
with optimized inner loop is still slower than an O(n log n) algorithm
with a naive inner loop at sufficient scale.

**Know when to stop.** If the target performance is met, stop. Further
optimization is speculative and may reduce readability.
