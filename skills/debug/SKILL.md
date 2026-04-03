---
name: debug
description: >
  Systematic debugging: reproduce, hypothesize, isolate, verify. Includes
  git bisect for regressions, 5 Whys root cause, and hypothesis tracking.
  Use when encountering bugs, test failures, or unexpected behavior.
argument-hint: "[bug description]"
---

## Purpose

Apply the scientific method to debugging rather than thrashing with blind
fixes. Reproduce the bug, form hypotheses, isolate the cause through
systematic elimination, verify the fix, and confirm no regressions.

**Preferred invocation:** Delegate to the `debugger` agent, which has this
skill and `safety-checks` preloaded with persistent memory for tracking
recurring failure patterns.

## Instructions

### 1. Understand the bug

From `$ARGUMENTS` and context, establish:

- **What is happening?** Exact error message, unexpected behavior, test failure
- **What should happen?** Expected behavior
- **When did it start?** Always, recently, after a specific change
- **Is it reproducible?** Always, intermittent, environment-specific

### 2. Reproduce

Before investigating, confirm you can reproduce the bug:

```bash
# Run the failing test or operation
cargo test <test_name> -- --nocapture
```

If you cannot reproduce, gather more information. Do not guess at fixes
for bugs you cannot trigger.

If the bug is intermittent, note the conditions under which it appears
and try to find a reliable trigger (load, timing, specific input).

### 3. Isolate with hypotheses

Form 2-4 hypotheses about the cause, ranked by likelihood:

| # | Hypothesis | Prediction | Test | Result | Conclusion |
|---|-----------|-----------|------|--------|-----------|
| 1 | [Most likely] | [What you'd observe if true] | [How to check] | | |
| 2 | [Second] | [What you'd observe if true] | [How to check] | | |
| 3 | [Third] | [What you'd observe if true] | [How to check] | | |

Test hypotheses in order of likelihood. For each:
1. Predict what you would observe if this hypothesis is correct
2. Run the test
3. Record the result: confirmed, eliminated, or inconclusive
4. **Eliminating a hypothesis is progress** - it narrows the search space.
   Disproving is more valuable than confirming because it removes
   multiple possibilities at once.

Structure hypotheses as **binary divisions** that bisect the problem space:
"The bug is in the client, not the server" rather than "maybe something
is wrong with serialization."

**Do not skip to fixing.** Confirm the cause before writing a fix. A fix
based on an unconfirmed hypothesis is a guess.

### 4. Regression? Use git bisect

If the bug worked before and broke recently:

```bash
git bisect start
git bisect bad                    # current commit is broken
git bisect good <known-good-sha> # last known working commit
# Git checks out a middle commit
# Run the test:
cargo test <test_name>
git bisect good  # or git bisect bad
# Repeat until the first bad commit is found
git bisect reset
```

`git bisect` finds the exact commit that introduced the bug in O(log n)
commits. This is faster and more reliable than reading commit history.

### 5. Root cause: 5 Whys

Once you know what changed, ask why it broke:

1. **Why** did the test fail? [Because X returned None]
2. **Why** did X return None? [Because the cache was empty]
3. **Why** was the cache empty? [Because invalidation runs before population]
4. **Why** does invalidation run first? [Because the ordering was changed in commit Y]
5. **Why** was the ordering changed? [Because it was not documented as load-bearing]

The root cause is usually 3-5 levels deep. Stop when you reach a systemic
cause (missing documentation, missing test, design flaw) rather than a
surface symptom.

### 6. Fix and verify

1. Write a regression test that fails without the fix and passes with it
2. Implement the minimal fix for the root cause (not the symptom)
3. Run the regression test to confirm it passes
4. Run the full test suite to confirm no new failures
5. Run CI verification per `rust-ci-check` (or equivalent)

### 7. Track and learn

Record the debugging session results:

| Field | Value |
|-------|-------|
| Bug | [Brief description] |
| Root cause | [What actually went wrong] |
| Fix | [What was changed] |
| Time to fix | [Duration] |
| Hypotheses tested | [Count tested / count formed] |
| First hypothesis correct? | [Yes/No] |

If running as the `debugger` agent, save patterns to persistent memory
for future sessions.

## Debugging anti-patterns

Avoid these common traps:

- **Shotgun debugging:** making random changes and hoping one works
- **Blind fix:** committing a fix without confirming the root cause
- **Print-statement fishing:** adding prints everywhere instead of
  forming a hypothesis first
- **Confirmation bias:** only testing the hypothesis you want to be true
- **Fix the symptom:** suppressing the error instead of fixing the cause
- **Scope creep:** refactoring unrelated code while debugging

## Debugging concurrent/async code

Concurrency bugs require special techniques:

- **Use sanitizers first:** ThreadSanitizer detects data races. Miri detects
  undefined behavior in unsafe Rust code.
- **Reduce concurrency** to isolate (single thread, single task)
- **Deterministic testing:** Use `tokio::time::pause()` and `advance()` to
  control time. Provide `RngSeed` for deterministic scheduler in `select!`.
- **Stress test** to reproduce intermittent issues (run 100x in a loop)
- **Check lock ordering** across all code paths
- **Check for `.await` across lock boundaries**
- **Use `tokio-console`** for async Rust runtime inspection
- **Noise injection:** insert random delays at synchronization points to
  explore novel thread interleavings

## Guidance

**Reproduce first.** If you cannot trigger the bug, you cannot verify a fix.
Invest time in reproduction before investigation.

**Hypothesize, don't explore.** Form a theory about what is wrong, predict
what you would observe, then check. This is faster than reading all the
code hoping something jumps out.

**The fix should address the root cause, not the symptom.** Adding a null
check at the crash site prevents the crash but does not fix why the value
was null.

**After 3 failed fix attempts, step back.** If three hypotheses have been
eliminated, the mental model of the code is probably wrong. Re-read the
code from scratch or get a fresh perspective.
