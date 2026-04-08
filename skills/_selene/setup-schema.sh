#!/usr/bin/env bash
# Setup SeleneDB reasoning schema for justin-tools skills.
#
# Registers all node and edge types required for skill reasoning persistence.
# Run once per SeleneDB instance. Restart SeleneDB after to build search indexes.
#
# Usage:
#   ./skills/_selene/setup-schema.sh                    # default: localhost:8080
#   ./skills/_selene/setup-schema.sh http://myhost:8080  # custom endpoint
#
# After running, restart SeleneDB to initialize search indexes for
# SEARCHABLE properties.

set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
GQL_ENDPOINT="${BASE_URL}/gql"

ok=0
err=0

run_gql() {
  local stmt="$1"
  local label="$2"
  local result
  result=$(curl -sf -X POST "$GQL_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$stmt\"}" 2>&1) || {
    echo "FAIL  $label (connection error)"
    ((err++))
    return
  }
  local status
  status=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
  if [ "$status" = "02000" ] || [ "$status" = "00000" ]; then
    echo "  OK  $label"
    ((ok++))
  else
    local msg
    msg=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','unknown'))" 2>/dev/null)
    echo "FAIL  $label: $msg"
    ((err++))
  fi
}

echo "SeleneDB Reasoning Schema Setup"
echo "Endpoint: $GQL_ENDPOINT"
echo ""

# ── Node Types ──────────────────────────────────────────────────────────
echo "Registering node types..."

run_gql "CREATE NODE TYPE :Session (date :: DATE, project :: STRING NOT NULL INDEXED, branch :: STRING, scope :: STRING SEARCHABLE, skill :: STRING INDEXED, outcome :: STRING DEFAULT 'in_progress')" \
  "Session"

run_gql "CREATE NODE TYPE :Document (title :: STRING SEARCHABLE, doc_type :: STRING NOT NULL INDEXED, content :: STRING SEARCHABLE, mode :: STRING)" \
  "Document"

run_gql "CREATE NODE TYPE :Decision (summary :: STRING NOT NULL SEARCHABLE, rationale :: STRING SEARCHABLE, alternatives :: STRING, confidence :: STRING DEFAULT 'medium')" \
  "Decision"

run_gql "CREATE NODE TYPE :Finding (summary :: STRING NOT NULL SEARCHABLE, severity :: STRING NOT NULL INDEXED, category :: STRING INDEXED, why_it_matters :: STRING, suggested_fix :: STRING, triage :: STRING INDEXED)" \
  "Finding"

run_gql "CREATE NODE TYPE :Insight (summary :: STRING NOT NULL SEARCHABLE, sources :: STRING, confidence :: STRING DEFAULT 'medium', actionable :: BOOL DEFAULT false)" \
  "Insight"

run_gql "CREATE NODE TYPE :Hypothesis (statement :: STRING NOT NULL SEARCHABLE, prediction :: STRING, test :: STRING, result :: STRING, conclusion :: STRING INDEXED, rank :: INT)" \
  "Hypothesis"

run_gql "CREATE NODE TYPE :RootCause (why :: STRING NOT NULL SEARCHABLE, level :: INT NOT NULL, systemic :: BOOL DEFAULT false)" \
  "RootCause"

run_gql "CREATE NODE TYPE :DeferredItem (item :: STRING NOT NULL SEARCHABLE, description :: STRING SEARCHABLE, priority :: STRING NOT NULL INDEXED, category :: STRING INDEXED, source :: STRING, stale :: BOOL DEFAULT false)" \
  "DeferredItem"

run_gql "CREATE NODE TYPE :Gate (condition :: STRING NOT NULL SEARCHABLE, met :: BOOL DEFAULT false, met_on :: DATE, evidence :: STRING)" \
  "Gate"

run_gql "CREATE NODE TYPE :CoverageGap (function :: STRING NOT NULL, gap_type :: STRING NOT NULL INDEXED, description :: STRING SEARCHABLE, addressed :: BOOL DEFAULT false)" \
  "CoverageGap"

run_gql "CREATE NODE TYPE :Release (version :: STRING NOT NULL INDEXED, bump_type :: STRING, date :: DATE, changelog :: STRING SEARCHABLE, has_breaking_changes :: BOOL DEFAULT false)" \
  "Release"

run_gql "CREATE NODE TYPE :CodeLocation (file :: STRING NOT NULL INDEXED, line_start :: INT, line_end :: INT, function :: STRING INDEXED, module :: STRING INDEXED)" \
  "CodeLocation"

run_gql "CREATE NODE TYPE :Rationalization (pattern :: STRING NOT NULL SEARCHABLE, skill :: STRING NOT NULL INDEXED, corrective_action :: STRING)" \
  "Rationalization"

run_gql "CREATE NODE TYPE :PlanClaim (claim :: STRING NOT NULL SEARCHABLE, actual :: STRING, inaccuracy_type :: STRING NOT NULL INDEXED, blast_radius :: INT DEFAULT 0)" \
  "PlanClaim"

run_gql "CREATE NODE TYPE :Incident (title :: STRING NOT NULL SEARCHABLE, severity :: STRING NOT NULL INDEXED, blast_radius :: STRING, started_at :: STRING, resolved_at :: STRING, duration :: STRING, mitigation :: STRING SEARCHABLE, root_cause :: STRING SEARCHABLE, lessons_learned :: STRING SEARCHABLE)" \
  "Incident"

run_gql "CREATE NODE TYPE :Perspective (role :: STRING NOT NULL, priority_focus :: STRING, claim :: STRING SEARCHABLE, grounds :: STRING, warrant :: STRING, qualifier :: STRING, rebuttal :: STRING, score :: INT)" \
  "Perspective"

run_gql "CREATE NODE TYPE :GitCommit (sha :: STRING NOT NULL UNIQUE INDEXED, short_sha :: STRING, message :: STRING SEARCHABLE, author :: STRING, date :: DATE, branch :: STRING, files_changed :: INT)" \
  "GitCommit"

echo ""

# ── Edge Types ──────────────────────────────────────────────────────────
echo "Registering edge types..."

run_gql "CREATE EDGE TYPE :produced (FROM :Session TO :Decision, :Finding, :Insight, :Hypothesis, :RootCause, :DeferredItem, :CoverageGap, :Release, :Incident, :Perspective, :PlanClaim, :Document, :Rationalization, :GitCommit)" \
  "produced"

run_gql "CREATE EDGE TYPE :contains (FROM :Document TO :Decision, :Finding, :Insight)" \
  "contains"

run_gql "CREATE EDGE TYPE :based_on (FROM :Decision TO :Insight, :Finding, :Hypothesis)" \
  "based_on"

run_gql "CREATE EDGE TYPE :affects (FROM :Decision, :Finding, :Hypothesis, :Insight, :CoverageGap TO :CodeLocation)" \
  "affects"

run_gql "CREATE EDGE TYPE :led_to (FROM :Decision TO :Decision, :Finding)" \
  "led_to"

run_gql "CREATE EDGE TYPE :resolved_by (FROM :Finding, :DeferredItem TO :Decision)" \
  "resolved_by"

run_gql "CREATE EDGE TYPE :gated_by (FROM :DeferredItem TO :Gate)" \
  "gated_by"

run_gql "CREATE EDGE TYPE :blocks (FROM :DeferredItem TO :DeferredItem)" \
  "blocks"

run_gql "CREATE EDGE TYPE :supersedes ()" \
  "supersedes"

run_gql "CREATE EDGE TYPE :why (FROM :RootCause TO :RootCause)" \
  "why"

run_gql "CREATE EDGE TYPE :covers (FROM :CoverageGap TO :CodeLocation)" \
  "covers"

run_gql "CREATE EDGE TYPE :continued_from (FROM :Session TO :Session)" \
  "continued_from"

run_gql "CREATE EDGE TYPE :observed_in (FROM :Rationalization TO :Session)" \
  "observed_in"

run_gql "CREATE EDGE TYPE :verified_as (FROM :Document TO :Decision)" \
  "verified_as"

run_gql "CREATE EDGE TYPE :breaking_change (FROM :Release TO :CodeLocation)" \
  "breaking_change"

run_gql "CREATE EDGE TYPE :mitigated_by (FROM :Incident TO :Decision)" \
  "mitigated_by"

run_gql "CREATE EDGE TYPE :caused_by (FROM :Incident TO :RootCause)" \
  "caused_by"

run_gql "CREATE EDGE TYPE :postmortem (FROM :Incident TO :Document)" \
  "postmortem"

run_gql "CREATE EDGE TYPE :argued_by (FROM :Document TO :Perspective)" \
  "argued_by"

run_gql "CREATE EDGE TYPE :ruled_as (FROM :Document TO :Decision)" \
  "ruled_as"

run_gql "CREATE EDGE TYPE :non_goal (FROM :Document TO :Decision)" \
  "non_goal"

run_gql "CREATE EDGE TYPE :implemented_by (FROM :Decision, :Document TO :GitCommit)" \
  "implemented_by"

run_gql "CREATE EDGE TYPE :fixed_by (FROM :Finding, :RootCause TO :GitCommit)" \
  "fixed_by"

run_gql "CREATE EDGE TYPE :introduced_by (FROM :Incident TO :GitCommit)" \
  "introduced_by"

run_gql "CREATE EDGE TYPE :released_in (FROM :GitCommit TO :Release)" \
  "released_in"

echo ""
echo "Done: $ok registered, $err failed"

if [ "$err" -gt 0 ]; then
  echo ""
  echo "Some types failed — they may already exist (safe to ignore)."
  echo "Check FAIL messages above for actual errors."
fi

echo ""
echo "IMPORTANT: Restart SeleneDB to initialize search indexes."
echo "Search (semanticSearch, hybridSearch, textSearch) will not work"
echo "until the instance is restarted after schema registration."
