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

This is an interactive skill. Present each release decision (version bump,
changelog entries, documentation gaps) for user approval before acting.

## Instructions

### 0. Context recall (SeleneDB)

If SeleneDB is available (see [selene-integration.md](../_selene/selene-integration.md)),
create a session and recall prior release context:

1. **Create session** with `skill: 'release-prep'` and `scope: $ARGUMENTS`
2. **Scoped auto-recall** — query for prior releases:
   - Prior `:Release` nodes for this project, ordered by date
   - Any breaking changes from past releases
   - Any `:DeferredItem` nodes gated on "next release"

3. If release history exists, present it:

> "Prior release context:
> - Last release: v[version] on [date] ([bump type])
> - [N] breaking changes in last [N] releases
> - [Any deferred items gated on this release]
>
> Proceeding with release scope analysis."

If SeleneDB is not available or no prior context exists, skip silently.

### 1. Determine scope

From `$ARGUMENTS`:
- Single crate release or workspace-wide?
- What was the last released version? (`git tag --list 'v*' --sort=-v:refname | head -5`)
- What has changed since then? (`git log --oneline <last-tag>..HEAD`)

### 2. Detect breaking changes

**Rust:**
```bash
cargo semver-checks check-release -p <crate>
```

If `cargo-semver-checks` is not available, manually check:
- Removed or renamed public items
- Changed function signatures (parameters, return types, generics)
- Changed trait bounds on public generics
- Removed trait implementations
- Changed default values or behavior

**Python:**
- No automated semver-checker; manually review public API changes
- Check `__all__` exports, function signatures, class interfaces
- Check `pyproject.toml` version and classifiers
- Run `pip-audit` for security advisories before release

**JavaScript/TypeScript:**
- Review exported types and function signatures
- Check `package.json` version, `exports` field, `types` field
- Run `npm audit` for security advisories
- If TypeScript: check `.d.ts` files for breaking type changes

### 3. Suggest version bump

Based on the changes since last release:

| Change Type | Bump | Example |
|:--|:--|:--|
| Bug fixes only | Patch (0.0.X) | 1.2.3 -> 1.2.4 |
| New features, no breaking changes | Minor (0.X.0) | 1.2.3 -> 1.3.0 |
| Breaking API changes | Major (X.0.0) | 1.2.3 -> 2.0.0 |
| Pre-1.0 breaking changes | Minor (0.X.0) | 0.3.1 -> 0.4.0 |

Present the version bump as a decision with options:

> "Based on the changes since [last version], I recommend a **[bump type]**
> bump to **v[new version]**. Here is why:
>
> 1. **[Recommended bump]** - [rationale]
> 2. **[Alternative bump]** - [when this would be appropriate instead]
>
> Which version?"

Wait for the user to confirm before proceeding.

#### Graph write: version decision (SeleneDB)

After the user confirms the version bump:

```gql
INSERT (r:Release {
  version: $new_version,
  bump_type: $bump_type,
  date: date(),
  has_breaking_changes: $has_breaking
})
RETURN id(r) AS release_id
```

Link to session:

```gql
MATCH (s:Session) WHERE id(s) = $session_id
MATCH (r:Release) WHERE id(r) = $release_id
INSERT (s)-[:produced]->(r)
```

If there are breaking changes, link each to its code location:

```gql
MERGE (loc:CodeLocation {file: $file, function: $function})
MATCH (r:Release) WHERE id(r) = $release_id
INSERT (r)-[:breaking_change]->(loc)
```

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

Present the generated changelog to the user for review:

> "Here is the draft changelog for v[version]. Review and let me know:
> - Any entries to add, remove, or reword
> - Any entries miscategorized (e.g., marked as Added but should be Changed)
>
> I will incorporate your feedback before proceeding to documentation
> verification."

Wait for approval before proceeding.

#### Graph write: changelog (SeleneDB)

After changelog approval, update the release node:

```gql
MATCH (r:Release) WHERE id(r) = $release_id
SET r.changelog = $changelog_content
```

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

- [ ] Version bumped in manifest (Cargo.toml / package.json / pyproject.toml)
- [ ] Internal dependency versions updated
- [ ] CHANGELOG.md updated with new version section
- [ ] Breaking change detection passes (cargo-semver-checks / manual review)
- [ ] Documentation is current (README, API docs, migration guide)
- [ ] All tests pass
- [ ] All lints pass
- [ ] Security audit clean (cargo-audit / npm audit / pip-audit)
- [ ] Breaking changes have a migration guide
- [ ] Git tag format: `v{version}` (e.g., `v1.3.0`)

**Rust additional:**
- [ ] `cargo publish --dry-run` succeeds
- [ ] `cargo package --list` contains only intended files

**Python additional:**
- [ ] `python -m build` produces clean wheel and sdist
- [ ] `twine check dist/*` passes
- [ ] `py.typed` marker present if typed

**JavaScript additional:**
- [ ] `npm pack --dry-run` lists only intended files
- [ ] `.npmignore` or `files` field in package.json is correct
- [ ] `types` field points to valid `.d.ts` if TypeScript

### 8. Tag (do not push)

```bash
git tag -a v<version> -m "Release v<version>"
```

Report: "Release v<version> tagged and ready. Review the changelog and
tag, then push when ready."

Do not push tags or publish. The user handles that.

## Supporting files

- [selene-integration.md](../_selene/selene-integration.md) - SeleneDB graph schema, detection, and persistence patterns

## Common Rationalizations

| Rationalization | Why It's Wrong |
|---|---|
| "Bump minor, changes are mostly features" | Skipping semver-checks misses breaking changes hidden in refactors. Run the tool. |
| "Auto-generate changelog from commits" | Commit messages are for developers. Changelogs are for users. Translate. |
| "Docs don't change for minor releases" | API docs, examples, and migration notes all drift. Verify every release. |
| "Skip dry-run, package is fine" | Dry-runs catch packaging errors that tests don't cover. Minutes to run, hours to fix. |
| "Breaking changes documented in git log" | Users don't read git logs. Write a migration guide they can find. |

## Red Flags

Stop and reassess if you observe:
- Bumping version without running semver-checks (or manual review for non-Rust)
- Changelog entries that read like commit messages instead of user-facing language
- Skipping the dry-run for package publishing
- Tagging without completing the full pre-release checklist

## Verification

- [ ] Breaking changes detected via semver-checks or manual review
- [ ] Version bump confirmed with user
- [ ] Changelog written in user-facing language and approved
- [ ] Documentation verified current (README, API docs, migration guides)
- [ ] Tag created (not pushed — user handles that)

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
