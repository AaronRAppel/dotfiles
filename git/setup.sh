#!/bin/bash
# Set up `git difftool` to open changes in RubyMine.
#
# Installs the wrapper script to ~/.local/bin/ and configures git globally.
# Re-running is safe — `cp -f` overwrites and `git config` is idempotent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"

if ! command -v rubymine1 >/dev/null 2>&1; then
  echo "warning: rubymine1 not on PATH (Toolbox-installed launcher). The wrapper expects it. Edit the wrapper if your launcher has a different name." >&2
fi

mkdir -p "$BIN_DIR"
cp -f "$SCRIPT_DIR/bin/rubymine-difftool" "$BIN_DIR/rubymine-difftool"
chmod +x "$BIN_DIR/rubymine-difftool"

git config --global diff.tool rubymine
git config --global difftool.rubymine.cmd 'rubymine-difftool "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false

echo "git difftool -> RubyMine configured."
echo "  Try:  git difftool HEAD"
echo "  Or:   git difftool -d HEAD   (directory-mode, single window)"
