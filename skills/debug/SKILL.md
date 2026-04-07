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

This is an interactive skill. Present hypotheses one at a time, let the
user guide investigation priority, and confirm fixes before moving on.

For production incidents, start with `incident-response` for triage and
mitigation before diving into root-cause debugging here.

## Instructions

### 1. Understand the bug

From `$ARGUMENTS` and context, establish:

- **What is happening?** Exact error message, unexpected behavior, test failure
- **What should happen?** Expected behavior
- **When did it start?** Always, recently, after a specific change
- **Is it reproducible?** Always, intermittent, environment-specific

### 2. Reproduce

Before investigating, confirm you can reproduce the bug:

**Rust:**
```bash
cargo test <test_name> -- --nocapture
```

**Python:**
```bash
pytest <test_file>::<test_name> -xvs
```

**JavaScript/TypeScript:**
```bash
npm test -- --testNamePattern="<test_name>"
# or: npx jest <test_file> -t "<test_name>"
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

Present hypotheses to the user **one at a time**, starting with the most
likely:

1. For each hypothesis, present:
   - The hypothesis and what you would observe if it is correct
   - The test you would run to check it
   - Why you rank it here: "I think this is most likely because [evidence]"
   - Ask: **test this**, **skip to next**, or **reorder**
2. Wait for the user's approval before running each test
3. After each test, report the result and ask whether to continue:
   - If confirmed: proceed to root cause analysis
   - If eliminated: present the next hypothesis
   - If inconclusive: recommend a refinement and ask the user
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

**Rust:**
- ThreadSanitizer for data races, Miri for undefined behavior in unsafe code
- `tokio::time::pause()` and `advance()` for deterministic time control
- `tokio-console` for async runtime inspection
- Check for `.await` across lock boundaries

**Python:**
- `asyncio.run()` with `debug=True` for verbose async logging
- `threading.settrace()` for thread execution tracing
- `pytest-asyncio` with `asyncio_mode="strict"` for async test discipline
- `freezegun` or `time-machine` for deterministic time control

**JavaScript/TypeScript:**
- `--inspect-brk` flag for Node.js debugger with async stack traces
- `jest.useFakeTimers()` for deterministic time in tests
- `AbortController` timeout patterns for async operations

**All languages:**
- Reduce concurrency to isolate (single thread, single task)
- Stress test to reproduce intermittent issues (run 100x in a loop)
- Check lock ordering across all code paths
- Inject random delays at synchronization points to explore interleavings

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Error is clear, I can fix without reproducing" | You're fixing your mental model, not the bug. Reproduction confirms you understand the actual failure. |
| "Obvious bug, no need for hypotheses" | Obvious bugs have obvious fixes that mask the real cause. Form hypotheses to avoid confirmation bias. |
| "Found one cause, implement and move on" | First hypothesis, not confirmed hypothesis. Test it before committing to a fix. |
| "Git history shows when it changed, skip bisect" | History shows what changed, not which change caused the bug. Bisect isolates the exact commit. |
| "Fix works, don't need 5 Whys depth" | Symptoms recur. Stopping at the proximate cause means fixing the same class of bug next month. |

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
