# justin-tools Plugin Development

A Claude Code plugin providing a complete development lifecycle toolkit:
28 skills, 9 agents, 8 hooks. Supports Rust, Python, and JavaScript/TypeScript.

## Plugin Structure

```
skills/<name>/SKILL.md     — skill with optional supporting files
agents/<name>.md           — subagent definitions
hooks/hooks.json           — event handlers
scripts/                   — development utilities (rename-plugin.sh)
docs/                      — getting-started, skills/agents/hooks reference
skills/_template/          — copy to create a new skill
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

## Quality Checklist

Before considering a skill or agent complete:
- [ ] Description under 250 chars, front-loads the key use case
- [ ] SKILL.md under 500 lines
- [ ] No `context: fork`
- [ ] Cross-references accessible (no dmi:true conflicts)
- [ ] Supporting files referenced from SKILL.md
- [ ] Multi-language examples where applicable (Rust, Python, JS/TS)
- [ ] Output paths use `_agentskills/<subfolder>/`
- [ ] Tested via `--plugin-dir .`

## Version Management

Bump version in `.claude-plugin/plugin.json` after changes. Users update with:
```bash
claude plugin update justin-tools@justin-tools-marketplace
```

## Renaming

Plugin name only in `.claude-plugin/plugin.json`. Run
`./scripts/rename-plugin.sh <new-name>` to change it.
