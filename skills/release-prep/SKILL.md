---
name: release-prep
description: >
  Release readiness: changelog generation, semver-checks, version bump
  suggestion, doc verification, multi-crate ordering. Use when preparing
  a crate or project for release.
disable-model-invocation: true
argument-hint: "[crate or version]"
---

## Purpose

Prepare a crate or project for release with a structured checklist:
generate a changelog, detect breaking API changes, suggest the correct
version bump, verify documentation is current, and handle multi-crate
workspace release ordering.

**Preferred invocation:** Delegate to the `release-manager` agent, which
has this skill plus `docs-sync` and `technical-writing` preloaded.

## Instructions

### 1. Determine scope

From `$ARGUMENTS`:
- Single crate release or workspace-wide?
- What was the last released version? (`git tag --list 'v*' --sort=-v:refname | head -5`)
- What has changed since then? (`git log --oneline <last-tag>..HEAD`)

### 2. Detect breaking changes

**Rust (cargo-semver-checks):**
```bash
cargo semver-checks check-release -p <crate>
```

If `cargo-semver-checks` is not available, manually check:
- Removed or renamed public items
- Changed function signatures (parameters, return types, generics)
- Changed trait bounds on public generics
- Removed trait implementations
- Changed default values or behavior

### 3. Suggest version bump

Based on the changes since last release:

| Change Type | Bump | Example |
|:--|:--|:--|
| Bug fixes only | Patch (0.0.X) | 1.2.3 -> 1.2.4 |
| New features, no breaking changes | Minor (0.X.0) | 1.2.3 -> 1.3.0 |
| Breaking API changes | Major (X.0.0) | 1.2.3 -> 2.0.0 |
| Pre-1.0 breaking changes | Minor (0.X.0) | 0.3.1 -> 0.4.0 |

Present the suggestion with rationale and get user confirmation.

### 4. Generate changelog

Compile changes from conventional commits since last release:

```bash
git log --oneline <last-tag>..HEAD --format="%s"
```

Organize by Keep a Changelog categories:
- **Added** - `feat:` commits
- **Changed** - commits that modify behavior
- **Fixed** - `fix:` commits
- **Deprecated** - changes marking items for removal
- **Removed** - items removed in this release
- **Security** - security-related fixes

Write human-readable descriptions, not raw commit messages. The changelog
is for users, not contributors.

### 5. Verify documentation

Delegate to the `docs-sync` skill methodology:
- README reflects current capabilities
- API documentation is current (`cargo doc --no-deps`)
- CHANGELOG.md is updated with new entries
- Version numbers in docs match the release version
- Migration guide exists if there are breaking changes (use `migration-guide`)

### 6. Multi-crate workspace ordering

For workspace releases, determine release order from the dependency graph:

```bash
cargo tree --workspace --depth 1
```

Release crates in dependency order (leaves first, root last):
1. Crates with no internal dependencies
2. Crates that depend only on already-released crates
3. Repeat until all crates are released

For each crate:
- Update version in `Cargo.toml`
- Update internal dependency versions pointing to it
- Run full CI check
- Tag (but do not push until all crates are ready)

### 7. Pre-release checklist

Before tagging:

- [ ] Version bumped in Cargo.toml (or package.json, pyproject.toml)
- [ ] Internal dependency versions updated
- [ ] CHANGELOG.md updated with new version section
- [ ] `cargo-semver-checks` passes (or manual check complete)
- [ ] Documentation is current (README, API docs, migration guide)
- [ ] All tests pass (`cargo test --workspace --all-features`)
- [ ] All lints pass (`cargo clippy --workspace --all-features -- -D warnings`)
- [ ] No known unfixed security vulnerabilities
- [ ] Breaking changes have a migration guide
- [ ] Git tag format: `v{version}` (e.g., `v1.3.0`)

### 8. Tag (do not push)

```bash
git tag -a v<version> -m "Release v<version>"
```

Report: "Release v<version> tagged and ready. Review the changelog and
tag, then push when ready."

Do not push tags or publish. The user handles that.

## Guidance

**Changelogs are for users, not developers.** "Refactored internal
module structure" is not a changelog entry. "Improved query performance
by 30%" is.

**When in doubt, bump major.** An unnecessary major bump is inconvenient.
A breaking change shipped as a minor bump breaks downstream consumers.

**Pre-1.0 Cargo convention:** For `0.y.z`, changes in `y` are breaking
(like major), changes in `z` are non-breaking (like minor). All `0.0.z`
releases are treated as incompatible with each other.

**Multi-crate releases are atomic.** Either all crates in the release
succeed or none do. Tag all, then push all.

**Test the release build.** Run `cargo package --list -p <crate>` to see
what would be published. Check for accidentally included files (test
fixtures, build artifacts, secrets).

**Push tags before publishing.** Tags can be deleted if `cargo publish`
fails. Published crates cannot be unpublished. Tag first, publish second.

**Mitigation strategies for future releases:** Use `#[non_exhaustive]`
early on enums and structs. Deprecate before removing. Use sealed traits
to prevent external implementations. Provide builder patterns instead of
struct literals.
