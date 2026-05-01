---
name: dotfiles_sync_reminder
description: Remind user to commit Claude config changes to dotfiles repo after modifying settings, memories, skills, or commands
type: feedback
---

After a session that modifies Claude config files (settings.json, CLAUDE.md, commands, skills, scripts, or memory files), remind the user to commit changes to their dotfiles repo at ~/workspace/dotfiles.

**Why:** Claude config is symlinked from ~/.claude into ~/workspace/dotfiles (GitHub: AaronRAppel/dotfiles). New memory files land as real files, not symlinks, so they also need to be copied into the repo and replaced with symlinks.

**How to apply:** At the end of a session where config was changed, say something like: "A few Claude config files changed this session — want me to sync them to your dotfiles repo?" Also watch for new memory files that aren't symlinks yet and offer to move them.
