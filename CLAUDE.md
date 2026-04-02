# justin-tools Plugin Development

This repo is a Claude Code plugin containing personal workflow skills,
agents, and hooks. When working here, you are helping develop and
maintain these skills.

## Plugin Structure

- `skills/<name>/SKILL.md` — each skill is a directory with SKILL.md entry point
- `agents/<name>.md` — subagent definitions
- `hooks/hooks.json` — event handler configuration
- `scripts/` — development utilities
- `skills/_template/` — copy this to create a new skill

## Creating a New Skill

1. Copy `skills/_template/` to `skills/<skill-name>/`
2. Skill names: lowercase, hyphens only (e.g., `code-review`, `deploy-staging`)
3. Replace `name: skill-name` in frontmatter with the actual skill name
4. Fill in all sections: Purpose, Instructions, Guidance
5. Write a description that front-loads the key use case (under 250 chars)
6. Test with `claude --plugin-dir .` then invoke with `/justin-tools:<skill-name>`

## Skill Writing Conventions

- **Be specific over general** — skills should solve a concrete problem,
  not provide vague guidance
- **Instructions are imperative** — "Run the tests" not "You should run the tests"
- **Keep SKILL.md under 500 lines** — move reference material to supporting files
- **Use $ARGUMENTS for user input** — don't hardcode values that should be parameters
- **Default to model-invocable** — only set `disable-model-invocation: true`
  for skills with side effects (deploys, sends, publishes)
- **Use `context: fork` for heavy research** — keeps the main conversation
  context clean

## Skill Quality Checklist

Before considering a skill complete:
- [ ] Description clearly states WHEN to use the skill
- [ ] Instructions are step-by-step and unambiguous
- [ ] Tested via `--plugin-dir .` invocation
- [ ] No hardcoded paths or values that should be arguments

## Renaming the Plugin

The plugin name appears only in `.claude-plugin/plugin.json`.
Update the `name` field there — or run `./scripts/rename-plugin.sh <new-name>`.
All skill invocations will use the new namespace automatically.
