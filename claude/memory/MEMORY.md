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
- Config symlinked from ~/.claude into ~/workspace/dotfiles (GitHub: AaronRAppel/dotfiles)
  - See [dotfiles_sync.md](dotfiles_sync.md) for sync reminder

## User Preferences
- Prefers plan mode by default
- Wants notifications when Claude needs attention but NOT when the hosting terminal app is frontmost

## Active Issues
- [Claude desktop blocked by CrowdStrike](claude_desktop_crowdstrike.md) — CrowdStrike Falcon spikes CPU on launch and prevents Claude desktop from running. Don't suggest reinstall; needs IT allowlist.
