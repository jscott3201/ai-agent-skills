# justin-tools Plugin Development

A Claude Code plugin providing a complete development lifecycle toolkit:
38 skills, 9 agents, 8 hooks. Supports Rust, Python, and JavaScript/TypeScript.

## Plugin Structure

```
skills/<name>/SKILL.md     — skill with optional supporting files
skills/_selene/            — shared SeleneDB integration (schema, patterns, detection)
skills/_template/          — copy to create a new skill
agents/<name>.md           — subagent definitions
hooks/hooks.json           — event handlers
scripts/                   — development utilities (rename-plugin.sh)
docs/                      — getting-started, skills/agents/hooks reference
.claude-plugin/            — plugin manifest + marketplace config
```

## Output Directory

Skills and agents write documents to `_agentskills/` in target projects.
Never commit `_agentskills/` unless the user explicitly asks.

```
_agentskills/
├── plans/       — implementation plans (feature-design)
├── design/      — design documents (feature-design formal path)
├── research/    — technical deep-dives, landscapes (research)
├── debates/     — debate findings (debate)
├── reviews/     — review and audit reports (when saved)
└── DEFERRED.md  — deferred work tracking
```

## Creating Skills

1. Copy `skills/_template/` to `skills/<skill-name>/`
2. Names: lowercase, hyphens only, max 64 characters
3. Description: front-load the key use case, under 250 characters
4. Keep SKILL.md under 500 lines, move reference material to supporting files
5. Reference supporting files with markdown links so Claude knows when to load them
6. Test with `claude --plugin-dir .` then `/justin-tools:<skill-name>`

## Skill Conventions

- Instructions are imperative: "Run the tests" not "You should run the tests"
- Use `$ARGUMENTS` for user input, not hardcoded values
- Default to model-invocable; use `disable-model-invocation: true` only for
  skills with side effects or that the user should trigger deliberately
- Do NOT use `context: fork` - delegate to custom agents instead
- Cross-skill references must point to accessible skills (not ones with
  `disable-model-invocation: true` that Claude cannot invoke)
- Multi-language: include Rust, Python, and JS/TS examples where applicable
- Output files go to `_agentskills/<subfolder>/`

## User Interaction Convention

Skills and agents that involve decisions, findings, or multi-step workflows
must present topics one at a time and let the user drive. Follow this pattern
at every decision point:

1. **One topic at a time.** Never dump a list of findings, options, or tasks
   all at once. Present the highest-priority item, resolve it, then move to
   the next.
2. **1-3 options with tradeoffs.** When meaningful choices exist, present
   1-3 options. For each, state what it does well and what it does poorly.
3. **State your recommendation.** For each decision point, say which option
   you favor and why. The user can accept, adjust, or override.
4. **Wait for the user.** Do not proceed to the next topic until the user
   responds. Silence is not consent.
5. **User drives, agent follows.** The user sets direction, scope, and pace.
   The agent provides analysis, options, and recommendations.

**Scope:** This convention applies to skills invoked in the main conversation
and to primary agents (debugger, test-engineer, release-manager, researcher,
onboarder, debate-lead). Read-only subagents (deep-reviewer,
security-auditor, code-analyzer) return findings to their parent skill, which
then applies this convention when presenting to the user.

## Agent Conventions

- Plugin agents cannot use: `hooks`, `mcpServers`, `permissionMode`
- Plugin agents can use: `skills`, `memory`, `tools`, `disallowedTools`,
  `model`, `effort`, `maxTurns`, `background`, `isolation`, `color`
- Preload skills via the `skills` field (full content injected at startup)
- Use `memory: user` for agents that accumulate knowledge across sessions
- Read-only agents: set `disallowedTools: Write, Edit, NotebookEdit`
- Full-access agents: omit `tools`/`disallowedTools` to inherit all

## Hook Conventions

- Plugin hooks go in `hooks/hooks.json`, not settings files
- Use `if` field for precise argument matching on Bash commands
- PreToolUse exit code 2 blocks the action (cannot be bypassed)
- Prompt-based hooks (type: prompt) use Haiku for fast evaluation
- TeammateIdle hooks keep team agents productive

## SeleneDB Integration

Skills can persist reasoning to SeleneDB (an AI-first property graph
database) for cross-session knowledge accumulation. SeleneDB is optional
and purely additive — skills fall back to existing behavior when it is
not available.

**Architecture:**
- User configures SeleneDB MCP server in project/user settings
- Skills detect `gql_query` tool availability at runtime
- Graph stores structured reasoning: decisions, findings, hypotheses,
  root causes, deferred items, coverage gaps, releases
- Skills write at decision points (user triage = graph commit)
- Skills auto-recall relevant prior reasoning at start via scoped
  vector search
- Sessions auto-create and chain via `:continued_from` edges

**Migrated skills (18):** research, deep-review, debug, plan-verify,
release-prep, deferred-tracking, test-strategy, feature-design, debate,
incident-response, refactor, perf-profile, modularize, project-onboard,
requirements-trace, milestone-tracking, notes, session-tracker.

**Integration files:**
- `skills/_selene/selene-integration.md` — detection, sessions, auto-recall, fallback
- `skills/_selene/selene-schema.md` — node types, edge types, properties
- `skills/_selene/selene-patterns.md` — write patterns, read queries, rationalization tracking
- `skills/_selene/reasoning-schema.gql` — GQL DDL for schema registration
- `skills/_selene/setup-schema.sh` — one-command schema setup (run once, then restart SeleneDB)

**Adding SeleneDB to a new skill:**
1. Add `### 0. Context recall (SeleneDB)` section matching the skill's
   numbering convention
2. Add `#### Graph write: [name] (SeleneDB)` sections at each decision point
3. Reference `selene-integration.md` in the Supporting Files section
4. Add the skill to the fallback table in `selene-integration.md`

**Cross-skill bridges:**
- deep-review deferred findings auto-create `:DeferredItem` nodes
- deep-review findings surface in test-strategy auto-recall
- release-prep queries deferred items gated on "next release"

## Quality Checklist

Before considering a skill or agent complete:
- [ ] Description under 250 chars, front-loads the key use case
- [ ] SKILL.md under 500 lines
- [ ] No `context: fork`
- [ ] Cross-references accessible (no dmi:true conflicts)
- [ ] Supporting files referenced from SKILL.md
- [ ] Multi-language examples where applicable (Rust, Python, JS/TS)
- [ ] Output paths use `_agentskills/<subfolder>/`
- [ ] SeleneDB integration follows `_selene/` patterns (if applicable)
- [ ] Tested via `--plugin-dir .`

## Version Management

Bump version in `.claude-plugin/plugin.json` after changes. Users update with:
```bash
claude plugin update justin-tools@justin-tools-marketplace
```

## Renaming

Plugin name only in `.claude-plugin/plugin.json`. Run
`./scripts/rename-plugin.sh <new-name>` to change it.
