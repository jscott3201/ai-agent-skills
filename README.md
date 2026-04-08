# justin-tools

A SeleneDB-first Claude Code plugin. Every skill reads from and writes to a
property graph for cross-session knowledge accumulation. 24 graph-native
skills, 9 agents, 4 hook types.

**Requires [SeleneDB](https://selenedb.com)** - an AI-first property graph
database with native MCP support.

## How it works

```
You work on code ──> Skills persist reasoning to the graph ──> Future sessions recall prior context
                          │
                          ├── Design decisions with rationale
                          ├── Security concerns linked to dependencies
                          ├── Debug hypotheses and root causes
                          ├── Review findings that graduate to conventions
                          ├── Milestones grouping commits and documents
                          └── Notes annotating any graph node
```

Every skill creates a session, recalls prior reasoning, writes structured
nodes at decision points, and closes the session with a summary. The graph
accumulates knowledge across sessions, projects, and skills.

## Setup

### 1. Install SeleneDB MCP

Configure the SeleneDB MCP server in your Claude Code project or user settings.
Skills detect `gql_query` tool availability at startup.

### 2. Register the schema

```bash
./skills/_selene/setup-schema.sh http://localhost:8080
# Restart SeleneDB to build search indexes
```

### 3. Install the plugin

```bash
claude plugin marketplace add /path/to/agent-skills
claude plugin install justin-tools@justin-tools-marketplace
```

**Update after changes:**

```bash
claude plugin update justin-tools@justin-tools-marketplace
```

## Skills

### Planning

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `feature-design` | `/justin-tools:feature-design [desc]` | Design decisions, plan documents, milestones |
| `research` | `/justin-tools:research [topic]` | Insights, documents, topic tags |
| `debate` | `/justin-tools:debate [question]` | Perspectives with Toulmin scores, rulings |
| `plan-verify` | Auto | Plan claims verified against codebase |

### Building

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `modularize` | `/justin-tools:modularize [scope]` | Structural findings, deferred items |
| `refactor` | `/justin-tools:refactor [target]` | Smell analysis, transformation decisions |
| `code-standards` | Auto | Convention violations; promotes recurring violations to Convention nodes |

### Debugging

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `debug` | Auto | Hypotheses, root cause chains (5 Whys) |
| `perf-profile` | `/justin-tools:perf-profile [target]` | Baseline insights, optimization decisions |
| `incident-response` | `/justin-tools:incident-response [issue]` | Incidents, mitigations, postmortems |

### Review and security

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `deep-review` | Auto | Findings with severity; graduates recurring patterns to conventions |
| `safety-checks` | Auto | **SecurityConcern** nodes linked to dependencies and code via `:affects` |
| `dep-audit` | Auto | Dependency nodes; **SecurityConcern** nodes for supply chain issues |

### Releasing

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `release-prep` | `/justin-tools:release-prep [crate]` | Release nodes, changelog entries |
| `requirements-trace` | `/justin-tools:requirements-trace [plan]` | Trace gaps, coverage decisions |

### Tracking

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `milestone-tracking` | Auto | Milestones grouping commits, documents, decisions |
| `deferred-tracking` | Auto | Deferred items with gate conditions |
| `session-tracker` | Auto | Session summaries for cross-session continuity |
| `commit-workflow` | Background | GitCommit nodes linked to milestones and decisions |

### Documentation

| Skill | Invoke | Graph writes |
|:--|:--|:--|
| `graph-docs` | `/justin-tools:graph-docs [type]` | Document nodes assembled from graph traversal |
| `project-onboard` | `/justin-tools:project-onboard` | Project assessment, setup decisions |

### Background

| Skill | Description |
|:--|:--|
| `notes` | All skills auto-annotate graph nodes with rationale, observations, TODOs, bookmarks |
| `skill-guide` | Routes tasks to the right skill via graph queries on skill and category nodes |

## Agents

Specialized subagents with preloaded skills and persistent memory.

| Agent | Skills | Access | Purpose |
|:--|:--|:--|:--|
| `deep-reviewer` | deep-review | Read-only | Post-phase code review |
| `security-auditor` | safety-checks | Read-only | STRIDE security audit |
| `code-analyzer` | modularize, code-standards | Read-only | Structural analysis |
| `test-engineer` | test-strategy | Full | Test planning and generation |
| `debugger` | debug, safety-checks | Full | Systematic debugging |
| `researcher` | research | Full | Technical deep-dives |
| `release-manager` | release-prep, graph-docs | Full | Release preparation |
| `onboarder` | project-onboard | Full | New project setup |
| `debate-lead` | debate | Full | Multi-perspective decisions |

## The graph

The property graph is the foundation. Every skill writes structured reasoning
at decision points. Here is what accumulates:

### Node types (23)

| Category | Types |
|:--|:--|
| **Sessions** | Session, GitCommit |
| **Reasoning** | Decision, Finding, Insight, Hypothesis, RootCause, PlanClaim |
| **Artifacts** | Document, Release, CoverageGap, Perspective, Rationalization |
| **Security** | SecurityConcern (links to dependencies and code via `:affects`) |
| **Tracking** | DeferredItem, Gate, Milestone, Note, Convention |
| **Structure** | CodeLocation, Topic |

### Key relationships

```
Session ──:produced──> Decision ──:implemented_by──> GitCommit ──:part_of──> Milestone
                           │
                           └──:affects──> CodeLocation
                           
SecurityConcern ──:affects──> Dependency
                └──:mitigated_by──> GitCommit

Finding (recurring) ──:promoted_from──> Convention ──:applies_to──> scope

Note ──:annotates──> (any node)

Document ──:informs──> Document  (research informs plan)

Session ──:continued_from──> Session  (multi-session chains)
```

### What you can query

```gql
-- Open security concerns with affected dependencies
MATCH (sc:SecurityConcern)-[:affects]->(d:dependency)
WHERE sc.project = 'myproject' AND sc.status = 'open'
RETURN d.name, sc.summary, sc.severity

-- Decision-to-commit traceability
MATCH (d:Decision)-[:implemented_by]->(c:GitCommit)
WHERE d.project = 'myproject'
RETURN d.summary, c.short_sha, c.message

-- Active conventions for a language
MATCH (c:Convention {active: true})
WHERE c.project = 'myproject' AND c.scope = 'rust'
RETURN c.rule, c.severity, c.rationale

-- What research informed a plan
MATCH (r:Document)-[:informs]->(p:Document {doc_type: 'plan'})
WHERE r.project = 'myproject'
RETURN r.title, p.title
```

### Multi-project

Multiple projects share one graph. All project-specific nodes carry a
`project` property. Cross-cutting nodes (skills, agents, dependencies) are
shared. Topics can bridge projects for cross-cutting discovery.

```gql
-- Shared topics across projects
MATCH (d1:Document)-[:about]->(t:Topic)<-[:about]-(d2:Document)
WHERE d1.project <> d2.project
RETURN t.name, d1.project, d2.project

-- Dependencies with concerns across all projects
MATCH (sc:SecurityConcern)-[:affects]->(d:dependency)
WHERE sc.status = 'open'
RETURN d.name, sc.project, sc.severity
```

## Hooks

| Event | Description |
|:--|:--|
| **SessionStart** | Injects 24-skill routing table; queries last 3 sessions for continuity |
| **PreToolUse** | Blocks `git push`, `git reset --hard`, `git checkout --`, `git clean -f`, `rm -rf` |
| **TeammateIdle** | Reminds idle teammates to check for pending tasks |
| **Notification** | macOS desktop alert when Claude needs input |

## Development

```bash
# Add a new skill
cp -r skills/_template skills/my-new-skill
# Edit SKILL.md — must include context recall + graph write patterns

# Test locally
claude --plugin-dir .

# Rename the plugin
./scripts/rename-plugin.sh new-name
```

Every new skill must:
1. Reference `skills/_selene/selene-integration.md` for session management
2. Include `### 0. Context recall` section with graph queries
3. Include `#### Graph write` sections at each decision point
4. Follow patterns in `skills/_selene/selene-patterns.md`

See [CLAUDE.md](CLAUDE.md) for full development conventions.
