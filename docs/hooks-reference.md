# Hooks Reference

Complete reference for all 8 hooks in the justin-tools plugin.

## How Hooks Work

Hooks are deterministic automations that fire at specific lifecycle points.
Unlike skills (which Claude chooses to use), hooks always execute when
their event fires. They enforce rules that should never be bypassed.

All hooks are defined in `hooks/hooks.json` and travel with the plugin.

## Hook Catalog

### PreToolUse Hooks (5)

These fire before a Bash command executes. Exit code 2 blocks the command
and sends feedback to Claude explaining why.

#### Block git push

**Matcher:** `Bash`
**Filter:** `Bash(git push*)`
**Behavior:** blocks with "Only the user pushes to remote"

Enforces the commit-workflow rule that Claude never pushes. The user
maintains full control over what reaches the remote. The only exception
is if the user explicitly asks Claude to push in the current conversation.

#### Block git reset --hard

**Matcher:** `Bash`
**Filter:** `Bash(git reset --hard*)`
**Behavior:** blocks with "Use a safer alternative or ask the user"

Prevents destructive history rewriting. Claude should use `git stash`,
`git checkout -- <file>`, or ask the user for guidance instead.

#### Block git checkout --

**Matcher:** `Bash`
**Filter:** `Bash(git checkout -- *)`
**Behavior:** blocks with "Discards uncommitted changes. Ask the user first"

Prevents accidental loss of uncommitted work. Claude should ask before
discarding changes.

#### Block git clean -f

**Matcher:** `Bash`
**Filter:** `Bash(git clean -f*)`
**Behavior:** blocks with "Removes untracked files permanently. Ask first"

Prevents deletion of untracked files that may be the user's in-progress
work.

#### Block rm -rf

**Matcher:** `Bash`
**Filter:** `Bash(rm -rf *)`
**Behavior:** blocks with "Use a targeted rm or ask the user"

Prevents recursive forced deletion. Claude should use specific file
removal or ask for confirmation.

### SessionStart Hook (1)

#### Skill routing table

**Matcher:** none (fires on every session start)
**Type:** command (additionalContext injection)
**Behavior:** injects compact skill routing table

Runs `session-start.sh` at the beginning of every session to inject a
compact task-to-skill routing table. This helps the agent recommend manual
skills proactively when it sees the user working on a matching task.

The output is a one-line-per-category summary of all 35 skills grouped by
workflow phase (planning, building, testing, debugging, reviewing, releasing,
maintenance). Skills marked (auto) are noted so the agent knows not to
invoke them explicitly.

Points to `/justin-tools:skill-guide` for detailed routing when the compact
table isn't sufficient.

### TeammateIdle Hook (1)

#### Task check

**Matcher:** none (fires for all teammates)
**Type:** command (additionalContext injection)
**Behavior:** reminds teammate to check for pending tasks

Fires when an agent team teammate is about to go idle. Injects a reminder
via `additionalContext` to check the task list for pending unblocked tasks
before idling.

This is advisory, not blocking. The teammate checks the task list and
claims the next task if available. If no tasks remain, the teammate idles
normally. This lightweight approach avoids forcing teammates into loops
while keeping them productive.

### Notification Hook (1)

#### Desktop alert

**Matcher:** none (fires on all notifications)
**Type:** command (macOS osascript)
**Behavior:** displays macOS desktop notification

Sends a native macOS notification when Claude needs attention (permission
prompt, idle prompt, etc). Allows the user to work elsewhere without
watching the terminal.

**Platform:** macOS only. For Linux, replace with `notify-send`. For
Windows, replace with PowerShell notification.

## Security Model

PreToolUse hooks with exit code 2 **cannot be bypassed**, even in
`bypassPermissions` mode. This makes the git push and destructive command
blocks authoritative safety controls.

The TeammateIdle hook uses `additionalContext` injection (advisory only),
not exit code 2. This keeps it safe to experiment with — remove it if it
causes teammate loops.

## Customization

To modify hooks, edit `hooks/hooks.json` at the plugin root. Changes
take effect after `/reload-plugins`.

To add project-specific hooks (e.g., auto-format for a specific language),
add them to the project's `.claude/settings.json` rather than the plugin.
Plugin hooks should be universal; project hooks should be project-specific.
