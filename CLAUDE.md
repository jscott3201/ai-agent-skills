# justin-tools Plugin Development

This repo is a Claude Code plugin containing personal workflow skills,
agents, and hooks. When working here, you are helping develop and
maintain these skills.

## Plugin Structure

- `skills/<name>/SKILL.md` - each skill is a directory with SKILL.md entry point
- `agents/<name>.md` - subagent definitions
- `hooks/hooks.json` - event handler configuration
- `scripts/` - development utilities
- `skills/_template/` - copy this to create a new skill

## Output Directory Structure

Skills and agents that produce documents write to `_agentskills/` in the
target project. This directory should be gitignored in target projects.
Do not commit files in `_agentskills/` unless the user explicitly asks.

```
_agentskills/
├── plans/          # implementation plans (feature-design)
├── design/         # design documents (feature-design formal path)
├── research/       # technical deep-dives, landscape analyses (research)
├── debates/        # multi-perspective debate findings (debate)
└── reviews/        # deep-review and security audit reports (when saved)
```

Create subdirectories as needed. Name files with date and topic:
`YYYY-MM-DD-<topic>-<type>.md`

## Creating a New Skill

1. Copy `skills/_template/` to `skills/<skill-name>/`
2. Skill names: lowercase, hyphens only (e.g., `code-review`, `deploy-staging`)
3. Replace `name: skill-name` in frontmatter with the actual skill name
4. Fill in all sections: Purpose, Instructions, Guidance
5. Write a description that front-loads the key use case (under 250 chars)
6. Test with `claude --plugin-dir .` then invoke with `/justin-tools:<skill-name>`

## Skill Writing Conventions

- **Be specific over general** - skills should solve a concrete problem,
  not provide vague guidance
- **Instructions are imperative** - "Run the tests" not "You should run the tests"
- **Keep SKILL.md under 500 lines** - move reference material to supporting files
- **Use $ARGUMENTS for user input** - don't hardcode values that should be parameters
- **Default to model-invocable** - only set `disable-model-invocation: true`
  for skills with side effects (deploys, sends, publishes)
- **Do not use `context: fork`** - instead, instruct Claude to use the Agent
  tool with a custom agent or Explore subagent for research phases
- **Reference custom agents** - for skills that need subagent research, delegate
  to the appropriate custom agent (code-reviewer, security-auditor, researcher)

## Agent Writing Conventions

- **Plugin agents cannot use:** `hooks`, `mcpServers`, `permissionMode`
  (security restriction)
- **Plugin agents can use:** `skills`, `memory`, `tools`, `disallowedTools`,
  `model`, `effort`, `maxTurns`, `background`, `isolation`, `color`
- **Preload skills via the `skills` field** - full content is injected at startup
- **Use persistent memory** (`memory: user`) for agents that accumulate knowledge

## Skill Quality Checklist

Before considering a skill complete:
- [ ] Description clearly states WHEN to use the skill (under 250 chars)
- [ ] Instructions are step-by-step and unambiguous
- [ ] No `context: fork` (use Agent tool with custom agents instead)
- [ ] Cross-skill references point to accessible skills (not dmi:true)
- [ ] Supporting files are referenced from SKILL.md
- [ ] Tested via `--plugin-dir .` invocation
- [ ] No hardcoded paths or values that should be arguments
- [ ] Output files go to `_agentskills/<subfolder>/`

## Renaming the Plugin

The plugin name appears only in `.claude-plugin/plugin.json`.
Update the `name` field there or run `./scripts/rename-plugin.sh <new-name>`.
All skill invocations will use the new namespace automatically.
