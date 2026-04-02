# Skills Repo Framework Design

**Date:** 2026-04-02
**Status:** Approved

## Overview

A Claude Code plugin repo (`justin-tools`) for privately developing personal workflow skills, agents, and hooks. Optimized for iterative skill development with conventions that produce consistent, high-quality skills. Plugin architecture chosen over standalone skills for namespacing, versioning, and future shareability.

## Requirements

- Plugin-based structure for organizational benefits and future distribution
- Support all skill types: task-oriented, knowledge/convention, and agent-powered
- Plugin name centralized for easy renaming
- CLAUDE.md that teaches Claude how to write skills consistently in this repo
- Template skill for quick scaffolding
- Minimal overhead — no unused tooling or complex build steps

## Directory Structure

```
agent-skills/                          # repo root
├── .claude-plugin/
│   └── plugin.json                    # manifest — name, version, description
├── skills/                            # one subdirectory per skill
│   └── _template/                     # copy this to start a new skill
│       └── SKILL.md
├── agents/                            # subagent definitions (empty initially)
├── hooks/
│   └── hooks.json                     # event handlers (empty config initially)
├── scripts/                           # utility scripts (validation, rename, etc.)
│   └── rename-plugin.sh              # one-command plugin rename
├── .claude/
│   └── settings.json                  # project-level Claude Code settings
├── CLAUDE.md                          # conventions for developing skills in this repo
├── .gitignore
├── LICENSE
└── README.md
```

### Key structural decisions

- **`_template/` skill**: Prefixed with underscore so it sorts first. No valid description in frontmatter prevents Claude Code from loading it as a real skill. Copy to create new skills.
- **Plugin name only in `plugin.json`**: Single source of truth. Rename script updates this one location.
- **`CLAUDE.md` at repo root**: Auto-loaded when working in this repo. Teaches Claude skill-writing conventions.
- **Empty `agents/` and `hooks/`**: Present to signal architecture, populated as needed.

## Plugin Manifest

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

- Pre-1.0 version signals active development
- No component path overrides — uses default directory conventions
- No homepage/repository until publication

## Skill Template

The template at `skills/_template/SKILL.md` establishes consistent structure:

```yaml
---
name: skill-name
description: >
  What this skill does and when to use it.
# disable-model-invocation: true
# context: fork
# agent: Explore
# allowed-tools: Read Grep Glob
# paths: "*.ts,*.tsx"
---

## Purpose
[What problem this skill solves]

## Instructions
[Step-by-step imperative instructions]

## Guidance
[Trade-offs, constraints, decision criteria]
```

### Conventions

- Commented-out frontmatter options serve as quick reference
- Three sections: Purpose (why), Instructions (what), Guidance (how to decide)
- Description uses YAML `>` for readable multi-line under 250-char limit
- Supporting files added per-skill as needed

## CLAUDE.md

The repo CLAUDE.md covers:

- Plugin structure overview and directory purposes
- Step-by-step process for creating a new skill
- Skill writing conventions (specific > general, imperative voice, size limits, argument handling, invocation control, context forking)
- Quality checklist (description clarity, step-by-step instructions, tested, no hardcoded values)
- Rename instructions pointing to single source of truth

## Development Utilities

### `scripts/rename-plugin.sh`

- Accepts new name as argument, validates kebab-case format
- Reads and updates `plugin.json` using Python 3 (no `jq` dependency)
- Reports old name and new invocation pattern

## Development Workflow

1. Open repo in Claude Code: `claude --plugin-dir .`
2. Create skill: copy `skills/_template/` to `skills/<name>/`
3. Edit `SKILL.md` following conventions
4. Test: invoke with `/justin-tools:<name>`
5. Iterate: `/reload-plugins` picks up changes without restart

## Future Additions

- Private marketplace when ready to share with team
- Hook configurations for automated workflows
- Custom subagents for specialized tasks
- MCP server integrations
- Mining existing memory/CLAUDE.md files for skill candidates

## Alternatives Considered

1. **Minimal skeleton** (just plugin.json + skills/) — rejected because no development conventions, skills would be inconsistent as they accumulate
2. **Monorepo multi-plugin** — rejected as over-engineered for current single-plugin needs, can restructure later if needed
