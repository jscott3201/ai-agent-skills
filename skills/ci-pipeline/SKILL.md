---
name: ci-pipeline
description: >
  Generate, audit, and diagnose CI/CD pipeline configurations. Covers
  GitHub Actions, GitLab CI, and common patterns for Rust, Python, and
  JS/TS. Use when creating pipelines, debugging failures, or optimizing
  build times.
disable-model-invocation: true
argument-hint: "[generate | audit | diagnose <url or log>]"
---

## Purpose

CI/CD pipelines are critical infrastructure written in error-prone YAML.
This skill handles three workflows: generating new pipelines from project
structure, auditing existing pipelines for correctness and efficiency,
and diagnosing pipeline failures from log output.

This is an interactive skill. Present pipeline design choices and
diagnostic findings one at a time for user decision.

## Instructions

Parse `$ARGUMENTS` to determine the mode:

- **generate** (or no args on a project without CI) — create a new pipeline
- **audit** (or no args on a project with CI) — review existing pipeline
- **diagnose** (with a URL, run ID, or pasted log) — debug a failure

### Mode 1: Generate pipeline

#### 1a. Detect project characteristics

Scan the project to determine:

| Characteristic | How to detect |
|:--|:--|
| Languages | File extensions, `Cargo.toml`, `pyproject.toml`, `package.json` |
| Test framework | Test config files, test directories, scripts in package.json |
| Build system | `Cargo.toml`, `Makefile`, `setup.py`, `tsconfig.json`, bundler configs |
| Linter/formatter | `.rustfmt.toml`, `ruff.toml`, `.eslintrc`, `.prettierrc` |
| Monorepo | Workspace members, multiple packages, Nx/Turborepo config |
| Deployment target | `Dockerfile`, `serverless.yml`, `fly.toml`, `vercel.json`, k8s manifests |
| CI platform | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile` |

Present findings:

> "Detected: [language] project with [test framework], [build system],
> targeting [platform]. No existing CI configuration found.
>
> I'll generate a [GitHub Actions / GitLab CI] pipeline. Which platform?"

Wait for confirmation.

#### 1b. Design the pipeline

Present the pipeline structure as a set of choices:

**Trigger strategy:**

> "When should the pipeline run?
>
> 1. **PR + main** (recommended) — run on pull requests and pushes to main
> 2. **All pushes** — run on every push to any branch
> 3. **PR only** — run only on pull requests
>
> I recommend option 1. It catches issues before merge and verifies main
> after merge."

Wait for decision. Then present job structure:

**Job design:**

> "Pipeline jobs:
>
> 1. **Lint and format** — fast feedback, catches style issues early
> 2. **Test** — unit and integration tests
> 3. **Build** — compile/bundle the project
> 4. **Security** — dependency audit (cargo-deny, pip-audit, npm audit)
>
> Optional:
> 5. **Coverage** — generate and upload coverage reports
> 6. **Deploy** — deploy to staging/production
>
> Which jobs to include? I recommend 1-4 as the baseline."

Wait for decision before generating.

#### 1c. Generate the pipeline file

Write the pipeline config with:

- Correct YAML syntax and structure for the chosen platform
- Appropriate caching (dependencies, build artifacts)
- Matrix testing if multiple versions or platforms are needed
- Concurrency control to cancel superseded runs

**Rust (GitHub Actions) baseline jobs:**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: "rustfmt, clippy" }
      - uses: Swatinem/rust-cache@v2
      - run: cargo fmt --all -- --check
      - run: cargo clippy --workspace --all-features --all-targets -- -D warnings

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test --workspace --all-features

  deny:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: EmbarkStudios/cargo-deny-action@v2
```

**Python (GitHub Actions) baseline jobs:**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --dev
      - run: uv run ruff format --check .
      - run: uv run ruff check .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --dev
      - run: uv run pytest

  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv run pip-audit
```

**JavaScript/TypeScript (GitHub Actions) baseline jobs:**

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "22", cache: "npm" }
      - run: npm ci
      - run: npx prettier --check .
      - run: npx eslint .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "22", cache: "npm" }
      - run: npm ci
      - run: npm test

  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=moderate
```

Present the generated file for review before writing.

### Mode 2: Audit existing pipeline

#### 2a. Read and parse

Read the existing CI configuration files. Identify the platform, jobs,
triggers, and caching strategy.

#### 2b. Check against common issues

| Issue | What to check | Impact |
|:--|:--|:--|
| **Missing cache** | No dependency caching configured | Slow builds |
| **No concurrency control** | Superseded runs not cancelled | Wasted compute |
| **Unpinned actions** | `uses: action@main` instead of `@v4` | Supply chain risk |
| **Missing format step** | Tests run but formatting not checked | Style drift |
| **No security audit** | No dependency vulnerability check | Unpatched CVEs |
| **Broad triggers** | `on: push` to all branches | Unnecessary runs |
| **Missing timeout** | No `timeout-minutes` on jobs | Hung jobs run forever |
| **No matrix** | Single OS/version when multi needed | False confidence |
| **Sequential jobs** | Jobs that could run in parallel are serialized | Slow pipeline |
| **Large checkout** | `fetch-depth: 0` when shallow clone suffices | Slow checkout |

#### 2c. Present findings one at a time

> **Missing cache:** No dependency caching in the `test` job.
> **Impact:** Each run re-downloads and compiles all dependencies.
> **Estimated savings:** 2-5 minutes per run.
>
> **Suggested fix:** Add `Swatinem/rust-cache@v2` / `actions/cache` step.
>
> Options:
> 1. **Fix** — add caching now
> 2. **Skip** — caching not worth the complexity
>
> I recommend fixing. [Show the specific YAML to add.]

Wait for decision before next finding.

### Mode 3: Diagnose pipeline failure

#### 3a. Get the failure context

If `$ARGUMENTS` includes a GitHub Actions URL or run ID:

```bash
gh run view <run-id> --log-failed
```

If the user pastes log output, work from that directly.

#### 3b. Classify the failure

| Category | Signals | Common fix |
|:--|:--|:--|
| **Dependency resolution** | "could not resolve", "version conflict", lockfile mismatch | Update lockfile, pin version |
| **Compilation error** | "error[E", "SyntaxError", type errors | Fix the code (often works locally but fails in CI due to missing feature flag or env) |
| **Test failure** | "FAILED", "AssertionError", test name in output | Fix the test or the code |
| **Flaky test** | Passes locally, fails intermittently in CI | Quarantine and investigate timing/ordering |
| **Permission error** | "Permission denied", "EACCES", token errors | Check secrets, file permissions, action permissions |
| **Timeout** | "exceeded the maximum", "timed out" | Increase timeout or optimize the slow step |
| **Cache miss** | "Cache not found", full rebuild every time | Fix cache key, check restore-keys |
| **Resource exhaustion** | "out of memory", "no space left", OOM killed | Use larger runner or optimize memory usage |
| **Action version** | "Unable to resolve action", deprecated warnings | Update action version |

#### 3c. Present diagnosis

> **Failure category:** [category]
> **Root cause:** [specific issue]
> **Evidence:** [relevant log lines]
>
> **Suggested fix:** [concrete change]
>
> Options:
> 1. **Apply fix** — make the change now
> 2. **Investigate further** — need more context
>
> I recommend [option] because [reason].

Wait for decision.

## Guidance

**Cache aggressively.** Dependency caching alone cuts most Rust builds
from 10+ minutes to 2-3. Python and Node benefit less but still save
30-60 seconds per run. The complexity cost is one `uses:` line.

**Pin action versions to SHAs for production.** `uses: actions/checkout@v4`
is convenient but vulnerable to supply chain attacks. For production
pipelines, pin to a specific commit SHA and use Dependabot to update.

**Cancel superseded runs.** Without concurrency control, pushing 3
commits in quick succession runs 3 full pipelines. Only the last one
matters. Use `concurrency: { group: ${{ github.ref }}, cancel-in-progress: true }`.

**Separate fast feedback from thorough checks.** Lint and format should
run first and fast (under 1 minute). Tests can run in parallel. Security
audits and coverage can be separate jobs that do not block merge if they
are informational.

**CI should mirror local development.** If developers run `cargo fmt &&
cargo clippy && cargo test` locally, CI should run the exact same
commands. Divergence between local and CI causes "works on my machine"
failures.
