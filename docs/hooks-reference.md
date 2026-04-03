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

### Stop Hook (1)

#### Verification check

**Matcher:** none (fires on every stop)
**Type:** prompt (Haiku evaluation)
**Behavior:** checks if code was edited without running verification

Uses a Claude Haiku model to evaluate: did Claude edit or write code files
(Edit, Write, NotebookEdit) in this turn AND did Claude NOT run a
verification command (cargo fmt/clippy/test, npm test, pytest, ruff, eslint)
before stopping?

If yes: returns `ok: false` with a reason, which Claude receives as its
next instruction and continues working to run verification.

If no edits were made, or verification was already run: returns `ok: true`
and Claude stops normally.

This prevents the most common CI failure: code committed without running
format/lint/test.

### TeammateIdle Hook (1)

#### Task check

**Matcher:** none (fires for all teammates)
**Type:** prompt (Haiku evaluation)
**Behavior:** checks for pending unblocked tasks

Fires when an agent team teammate is about to go idle. Uses Haiku to
check if pending, unblocked tasks exist in the shared task list.

If tasks exist: returns `ok: false`, prompting the teammate to claim the
next task instead of going idle.

If no tasks remain: returns `ok: true`, allowing the teammate to idle.

This keeps teammates productive and prevents premature idling while work
remains.

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

The Stop verification hook uses Haiku for fast, low-cost evaluation.
It fires on every stop but only flags when code edits occurred without
verification, keeping false positives low.

## Customization

To modify hooks, edit `hooks/hooks.json` at the plugin root. Changes
take effect after `/reload-plugins`.

To add project-specific hooks (e.g., auto-format for a specific language),
add them to the project's `.claude/settings.json` rather than the plugin.
Plugin hooks should be universal; project hooks should be project-specific.
