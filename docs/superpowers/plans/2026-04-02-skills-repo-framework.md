# Skills Repo Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the `justin-tools` Claude Code plugin repo with all directories, configuration, template skill, CLAUDE.md conventions, and development utilities.

**Architecture:** Flat plugin structure using Claude Code's default directory conventions (no custom paths in manifest). All files are static configuration or markdown — no build step, no dependencies.

**Tech Stack:** Markdown (SKILL.md, CLAUDE.md), JSON (plugin.json, hooks.json, settings.json), Bash (rename script)

---

## File Map

| File | Responsibility |
|:--|:--|
| `.claude-plugin/plugin.json` | Plugin identity — name, version, metadata |
| `skills/_template/SKILL.md` | Skeleton for new skills with commented-out frontmatter reference |
| `agents/.gitkeep` | Placeholder so git tracks the empty directory |
| `hooks/hooks.json` | Empty hooks config ready for future event handlers |
| `scripts/rename-plugin.sh` | Rename plugin name in plugin.json, validate kebab-case |
| `.claude/settings.json` | Empty project-level Claude Code settings |
| `CLAUDE.md` | Skill-writing conventions for Claude when working in this repo |
| `.gitignore` | Standard ignores + settings.local.json |
| `README.md` | Quick-start for humans: what this is, how to use, how to add skills |

---

### Task 1: Initialize repo and create plugin manifest

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.gitignore`

- [ ] **Step 1: Create `.claude-plugin/` directory and `plugin.json`**

```bash
mkdir -p .claude-plugin
```

Write `.claude-plugin/plugin.json`:

```json
{
  "name": "justin-tools",
  "description": "Personal workflow skills, agents, and automation",
  "version": "0.1.0",
  "author": {
    "name": "Justin Scott"
  },
  "keywords": ["personal", "workflows", "productivity"]
}
```

- [ ] **Step 2: Create `.gitignore`**

Write `.gitignore`:

```
.DS_Store
*.swp
*.swo
*~
.claude/settings.local.json
```

- [ ] **Step 3: Commit**

```bash
git add .claude-plugin/plugin.json .gitignore
git commit -m "feat: initialize plugin manifest and gitignore"
```

---

### Task 2: Create skill template

**Files:**
- Create: `skills/_template/SKILL.md`

- [ ] **Step 1: Create the template directory**

```bash
mkdir -p skills/_template
```

- [ ] **Step 2: Write the template SKILL.md**

Write `skills/_template/SKILL.md`:

```yaml
---
name: skill-name
description: >
  What this skill does and when to use it. Front-load the key use case.
  Claude uses this to decide when to apply the skill automatically.
# disable-model-invocation: true    # uncomment for manual-only skills
# context: fork                      # uncomment to run in a subagent
# agent: Explore                     # uncomment to specify subagent type
# allowed-tools: Read Grep Glob      # uncomment to restrict tool access
# paths: "*.ts,*.tsx"                # uncomment to limit to specific file types
---

## Purpose

[What problem this skill solves]

## Instructions

[Step-by-step instructions Claude follows when this skill is invoked]

1. **Step one**: ...
2. **Step two**: ...
3. **Step three**: ...

## Guidance

[Trade-offs, constraints, or decision criteria Claude should consider]
```

- [ ] **Step 3: Verify template is not loadable as a skill**

Run: `grep -c "^description:" skills/_template/SKILL.md`

Expected: The description is a placeholder (`What this skill does...`), so Claude Code will see it but won't match it to any real task context. The `name: skill-name` is also not a valid invocable name since it's clearly a placeholder.

- [ ] **Step 4: Commit**

```bash
git add skills/_template/SKILL.md
git commit -m "feat: add skill template with commented frontmatter reference"
```

---

### Task 3: Create empty directory placeholders

**Files:**
- Create: `agents/.gitkeep`
- Create: `hooks/hooks.json`
- Create: `.claude/settings.json`
- Create: `scripts/` (directory only, script added in Task 5)

- [ ] **Step 1: Create agents directory with .gitkeep**

```bash
mkdir -p agents
touch agents/.gitkeep
```

- [ ] **Step 2: Create hooks directory with empty hooks.json**

```bash
mkdir -p hooks
```

Write `hooks/hooks.json`:

```json
{
  "hooks": {}
}
```

- [ ] **Step 3: Create .claude directory with empty settings.json**

```bash
mkdir -p .claude
```

Write `.claude/settings.json`:

```json
{}
```

- [ ] **Step 4: Create scripts directory**

```bash
mkdir -p scripts
```

- [ ] **Step 5: Commit**

```bash
git add agents/.gitkeep hooks/hooks.json .claude/settings.json
git commit -m "feat: add placeholder directories for agents, hooks, and settings"
```

---

### Task 4: Write CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

Write `CLAUDE.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md with skill development conventions"
```

---

### Task 5: Create rename script

**Files:**
- Create: `scripts/rename-plugin.sh`

- [ ] **Step 1: Write the rename script**

Write `scripts/rename-plugin.sh`:

```bash
#!/usr/bin/env bash
# Renames the plugin by updating plugin.json
# Usage: ./scripts/rename-plugin.sh new-name

set -euo pipefail

NEW_NAME="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/.claude-plugin/plugin.json"

if [[ -z "$NEW_NAME" ]]; then
  echo "Usage: $0 <new-name>"
  echo "  name must be lowercase letters, numbers, and hyphens"
  exit 1
fi

if [[ ! "$NEW_NAME" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
  echo "Error: name must be lowercase letters, numbers, and hyphens"
  exit 1
fi

OLD_NAME=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['name'])")

python3 -c "
import json, sys
with open('$MANIFEST') as f:
    m = json.load(f)
m['name'] = '$NEW_NAME'
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
    f.write('\n')
"

echo "Renamed: $OLD_NAME -> $NEW_NAME"
echo "Skills are now invoked as /$NEW_NAME:<skill-name>"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/rename-plugin.sh
```

- [ ] **Step 3: Test the script**

Run: `./scripts/rename-plugin.sh test-name`

Expected output:
```
Renamed: justin-tools -> test-name
Skills are now invoked as /test-name:<skill-name>
```

Then verify: `python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['name'])"`

Expected: `test-name`

- [ ] **Step 4: Revert the test rename**

Run: `./scripts/rename-plugin.sh justin-tools`

Expected output:
```
Renamed: test-name -> justin-tools
Skills are now invoked as /justin-tools:<skill-name>
```

- [ ] **Step 5: Commit**

```bash
git add scripts/rename-plugin.sh
git commit -m "feat: add plugin rename script"
```

---

### Task 6: Write README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

Write `README.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with usage and structure overview"
```

---

### Task 7: Verify the plugin loads in Claude Code

- [ ] **Step 1: Run Claude Code with the plugin**

Run: `claude --plugin-dir .`

- [ ] **Step 2: Check skill listing**

In the Claude Code session, type: `What skills are available?`

Expected: The `_template` skill should appear in the listing (it has a description, even though it's a placeholder). No errors about plugin loading.

- [ ] **Step 3: Check for plugin errors**

Run: `claude --plugin-dir . --debug 2>&1 | head -50`

Expected: No errors related to `justin-tools` plugin loading. Should see the plugin being discovered and skills being registered.

- [ ] **Step 4: Exit and confirm**

If everything loads cleanly, the framework is complete. No commit needed for this task — it's verification only.
