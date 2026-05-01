# Hooks Setup

## Notification Script
**File:** `~/.claude/scripts/notify.sh`
- Walks up the process tree to detect which terminal app is hosting Claude
- Suppresses notification if that app is frontmost
- Uses `terminal-notifier` (Ruby gem) with `-activate` flag so clicking the notification opens the host app
- Supports: Terminal, iTerm2, VS Code, Warp, RubyMine (with bundle IDs for each)
- To add a new app: add a case to the process tree loop with the app's binary path and bundle ID

## Configured Hooks
All defined in `~/.claude/settings.json` under `"hooks"`:

| Event | Matcher | Message |
|-------|---------|---------|
| Stop | (none) | "Claude has finished" |
| Notification | permission_prompt | "Claude needs permission" |

Note: `idle_prompt` was removed — it double-notified 60s after Stop already fired.

## Hook Format Notes
- Settings.json hooks use: `{ "hooks": [ { "type": "command", "command": "..." } ] }` wrapper format
- Hooks with matchers add `"matcher": "value"` at the same level as `"hooks"`
- Hooks load at session start — restart Claude Code after changes
- Available Notification matchers: `permission_prompt`, `idle_prompt`, `elicitation_dialog`, `auth_success`
- `AskUserQuestion` does NOT trigger Notification hooks — only Stop fires when Claude finishes its turn
