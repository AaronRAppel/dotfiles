# macOS Notifications Plugin for Claude Code

## Context

Claude Code runs long tasks, asks permission questions, and finishes work — but there's no notification when the terminal isn't visible. Aaron built a personal notification setup using `terminal-notifier` and Claude Code hooks. This plugin packages that setup for the gusto/claude-code marketplace so other engineers can get the same experience by enabling a plugin and running a one-time setup command.

## Plugin Overview

**Name:** `macos-notifications`
**Marketplace:** `gusto-claude-code` (hosted at `gusto/claude-code`)
**Platform:** macOS only (uses `osascript` and `terminal-notifier`)

A standalone plugin that sends native macOS notifications when Claude Code needs attention. Hooks activate automatically on plugin enable; notifications require a one-time `/macos-notifications:setup` to install `terminal-notifier` via Homebrew.

## Plugin Structure

```
plugins/macos-notifications/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── hooks/
│   ├── hooks.json
│   └── notify.sh
└── skills/
    └── setup/
        └── SKILL.md
```

## Components

### 1. hooks/hooks.json

Declares three hooks that call `notify.sh` with a context-specific message:

| Event            | Matcher          | Message                          |
|------------------|------------------|----------------------------------|
| Stop             | (none)           | "Claude has finished"            |
| PermissionRequest| (none)           | "Claude needs permission"        |
| PreToolUse       | AskUserQuestion  | "Claude has a question for you"  |

Each hook entry:
```json
{
  "hooks": [
    {
      "type": "command",
      "command": "$CLAUDE_PLUGIN_ROOT/hooks/notify.sh '<message>'"
    }
  ]
}
```

### 2. hooks/notify.sh

A portable bash script that sends a macOS notification. Behavior:

1. **Dependency check** — runs `command -v terminal-notifier`. If not found, exits 0 silently (no-op before setup).
2. **Load terminal config** — reads `~/.claude/notification-terminals.json` for the user's configured terminals. If the config file doesn't exist, exits 0 silently (setup hasn't been run yet).
3. **Terminal detection** — walks the process tree via `ps` to identify the host terminal app. Matches against the terminals configured in the JSON file. Each terminal entry has:
   - `name` — display name (e.g., "Terminal")
   - `process_pattern` — pattern to match in the process tree (e.g., "*/Terminal.app/*")
   - `bundle_id` — macOS bundle ID for click-to-activate (e.g., "com.apple.Terminal")
4. **Frontmost suppression** — uses `osascript` to check if the host app is frontmost. If so, exits 0 (user is already looking at it).
5. **Send notification** — calls `terminal-notifier` with:
   - `-message "$MESSAGE"` — the hook-provided message
   - `-title "Claude Code"`
   - `-sound Ping`
   - `-execute "open -b $BUNDLE_ID"` — clicking the notification activates the host terminal

**Config file format** (`~/.claude/notification-terminals.json`):
```json
{
  "terminals": [
    { "name": "Terminal", "process_pattern": "*/Terminal.app/*", "bundle_id": "com.apple.Terminal" },
    { "name": "VS Code", "process_pattern": "*/Code", "bundle_id": "com.microsoft.VSCode" }
  ]
}
```

Key differences from the original script:
- Uses `command -v terminal-notifier` instead of hardcoded mise/Ruby path
- Exits silently if `terminal-notifier` is missing (graceful pre-setup behavior)
- No Ruby or mise dependency — uses Homebrew `terminal-notifier`
- Terminal list is config-driven, not hardcoded — users select terminals during setup

### 3. skills/setup/SKILL.md

A user-invocable skill at `/macos-notifications:setup`. Steps:

1. Check if `terminal-notifier` is already on PATH
2. If missing, check if Homebrew is available
3. Run `brew install terminal-notifier`
4. Ask which terminal apps the user runs Claude Code in (multi-select). Known terminals:
   - Terminal.app, iTerm2, VS Code, Warp, RubyMine, Claude Desktop, Ghostty, Alacritty
   - "Other" option: user provides app name, process pattern, and bundle ID
5. Write selections to `~/.claude/notification-terminals.json`
6. Send a test notification to verify the setup
7. Report success or troubleshooting guidance

Re-running `/macos-notifications:setup` overwrites the config, allowing users to change their terminal selection.

Frontmatter:
```yaml
---
name: setup
description: Install terminal-notifier for macOS notifications. Run this once after enabling the plugin.
allowed-tools: [Bash]
---
```

### 4. plugin.json

```json
{
  "name": "macos-notifications",
  "version": "1.0.0",
  "description": "Native macOS notifications when Claude needs your attention",
  "author": {
    "name": "Aaron Appel",
    "email": "aaron.appel@gusto.com"
  },
  "pages": {
    "icon": "🔔",
    "features": [
      "Notifies when Claude finishes, needs permission, or has a question",
      "Suppresses notifications when you're already looking at the terminal",
      "Clicking a notification activates the correct terminal app"
    ],
    "components": [
      {
        "type": "skill",
        "name": "setup",
        "description": "Install terminal-notifier and verify notifications work"
      }
    ]
  }
}
```

### 5. README.md

Brief usage doc covering:
- What the plugin does
- Quick start: enable plugin → run `/macos-notifications:setup`
- Supported terminal apps
- How to add a new terminal app (re-run `/macos-notifications:setup` or edit `~/.claude/notification-terminals.json`)
- macOS-only limitation

## User Flow

1. Engineer browses gusto-claude-code marketplace, enables `macos-notifications`
2. Hooks activate but are no-ops (terminal-notifier not installed yet)
3. Engineer runs `/macos-notifications:setup`
4. Setup skill installs `terminal-notifier` via Homebrew, sends a test notification
5. From now on, notifications fire whenever Claude finishes, needs permission, or asks a question — unless the terminal is already frontmost

## Verification

- [ ] Enable the plugin locally via `claude --plugin-dir ./plugins/macos-notifications`
- [ ] Confirm hooks are registered (check `Stop`, `PermissionRequest`, `PreToolUse` events)
- [ ] Without `terminal-notifier` installed: hooks exit silently, no errors
- [ ] Run `/macos-notifications:setup`: `terminal-notifier` installs, test notification appears
- [ ] Trigger each hook event and confirm notification appears
- [ ] Confirm notification is suppressed when the terminal app is frontmost
- [ ] Confirm clicking the notification activates the correct terminal app
- [ ] Run `bin/lint` and `claude plugin validate .` on the plugin
