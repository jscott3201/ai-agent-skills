---
name: rust-ci-check
description: >
  Run the full Rust CI verification sequence: fmt, clippy, test, deny.
  Always uses --all-features. Manual invocation only.
disable-model-invocation: true
---

## Purpose

Run the complete Rust CI verification sequence before committing. Catches
formatting issues, lint warnings, test failures, and dependency problems
in a single pass. If any step fails, attempt to fix and retry.

## Instructions

Run these steps in order. Stop at the first failure and attempt to fix it.

### Step 1: Format

```bash
cargo fmt --all
```

This applies formatting, not just checks. If files change, they need to be
staged before committing.

### Step 2: Clippy

```bash
cargo clippy --workspace --all-features --all-targets -- -D warnings
```

Always `--all-features`. Feature-gated code accumulates lint errors that are
invisible with default features. Always `--all-targets` to cover tests and
benchmarks.

### Step 3: Test

```bash
cargo test --workspace --all-features
```

Always `--all-features` for the same reason as clippy.

### Step 4: Dependency audit

```bash
cargo deny check
```

Skip gracefully if `deny.toml` does not exist in the workspace root. If it
exists, run the check. Failures here indicate license violations or known
security advisories in dependencies.

### On failure

If any step fails:

1. Attempt to fix the issue
2. Re-run the full sequence from Step 1 (not just the failed step)
3. If still failing after 2 full retry cycles, stop and report:
   - Which step is failing
   - What was tried
   - The exact error output

### After all steps pass

Report: "CI check passed - fmt, clippy, test, deny all clean."
Files are ready to stage and commit.

## Guidance

Never skip `--all-features`. This is the single most common source of CI
failures across projects. Feature-gated code that compiles fine under default
features can have 40+ clippy errors or test failures when all features are
enabled.

The full sequence matters even for small changes. A one-line fix can break
a test in another crate or trigger a new clippy lint under a different feature
combination.
