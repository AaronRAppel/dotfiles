# Memory

## User Environment
- macOS, zsh, oh-my-zsh
- Default terminal: Apple Terminal
- IDE: RubyMine
- Repos in ~/workspace/ (zenpayroll, mithrin, web, scheduling-service, terraform, etc.)

## Claude Code Setup
- Model: Claude Opus 4.6 via AWS Bedrock
- Default permission mode: plan
- Settings: ~/.claude/settings.json
- Custom notification script: ~/.claude/scripts/notify.sh
  - See [hooks.md](hooks.md) for details

## User Preferences
- Prefers plan mode by default
- Wants notifications when Claude needs attention but NOT when the hosting terminal app is frontmost
