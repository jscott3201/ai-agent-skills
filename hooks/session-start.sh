#!/usr/bin/env bash
# Inject a compact skill routing table at session start.
# This helps the agent recommend manual skills proactively.

cat <<'ROUTE'
{"additionalContext": "justin-tools: 35 skills available. Suggest manual skills when you see the user working on a matching task.\n\nPlanning: feature-design, research, debate\nBuilding: rust-scaffold, error-catalog, modularize, refactor, ci-pipeline\nTesting: test-strategy (auto), rust-ci-check, plan-verify (auto), requirements-trace, sequential-bench (auto)\nDebugging: debug (auto), perf-profile, incident-response\nReviewing: deep-review (auto), safety-checks (auto), code-standards (auto), dep-audit (auto)\nReleasing: release-prep, migration-guide, migration-safety\nDocs/Maintenance: docs-sync (auto), api-doc-gen, env-audit, crate-health, project-onboard\nBackground: commit-workflow, subagent-dispatch, team-coordination, technical-writing, no-shortcuts (auto)\n\nFor detailed routing: /justin-tools:skill-guide"}
ROUTE
