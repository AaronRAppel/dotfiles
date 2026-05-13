# git tools

Lightweight setup for `git difftool` to open diffs in RubyMine without requiring a new RubyMine project session per worktree.

## Install

```bash
./setup.sh
```

Installs `bin/rubymine-difftool` to `~/.local/bin/` and configures three global git settings:

- `diff.tool = rubymine`
- `difftool.rubymine.cmd = rubymine-difftool "$LOCAL" "$REMOTE"`
- `difftool.prompt = false`

Re-running is safe (idempotent).

## Usage

```bash
git difftool HEAD                       # iterate every changed file
git difftool HEAD -- path/to/file       # single file
git difftool -d HEAD                    # directory-mode (single window, tree view)
git difftool main...HEAD                # full branch vs main
git difftool HEAD^ HEAD                 # last commit's diff
```

## How the wrapper works

`git difftool` deletes its temp files the moment the configured cmd returns. JetBrains Toolbox launchers (`rubymine1`) `open -na` the IDE and return immediately, so by the time RubyMine reads the files they're gone.

`rubymine-difftool` solves this by copying `$LOCAL` and `$REMOTE` to `~/.cache/git-difftool-rubymine/` before launching RubyMine. The IDE reads from the persistent copies; git's cleanup is harmless.

Auto-prunes copies older than 1 day on each invocation to keep the cache bounded.

## Caveats

- You're diffing **copies** in `~/.cache/...`, not the live files. Editing them in the diff window doesn't write back. One-way review only.
- The wrapper calls `rubymine1` (Toolbox-installed name). If Toolbox reinstalls and assigns a different suffix (`rubymine2`, etc.), edit `bin/rubymine-difftool` to match. Alternative: symlink `~/.local/bin/rubymine -> "$TOOLBOX/scripts/rubymineN"` and change the wrapper to call plain `rubymine`.
