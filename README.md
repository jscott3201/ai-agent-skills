# justin-tools

A Claude Code plugin for personal workflow skills, agents, and automation.

## Usage

Load the plugin during development:

```bash
claude --plugin-dir /path/to/agent-skills
```

Invoke a skill:

```
/justin-tools:<skill-name>
```

Reload after changes (no restart needed):

```
/reload-plugins
```

## Adding a New Skill

1. Copy the template:
   ```bash
   cp -r skills/_template skills/my-new-skill
   ```
2. Edit `skills/my-new-skill/SKILL.md` — fill in name, description, and instructions
3. Test with `/justin-tools:my-new-skill`

See `CLAUDE.md` for full conventions.

## Renaming the Plugin

```bash
./scripts/rename-plugin.sh new-name
```

## Structure

```
skills/          — one directory per skill, each with SKILL.md
agents/          — subagent definitions (.md files)
hooks/           — event handlers (hooks.json)
scripts/         — development utilities
.claude-plugin/  — plugin manifest (plugin.json)
```
