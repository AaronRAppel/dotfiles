#!/bin/bash
# ~/dotfiles/install-claude.sh
# Symlinks personal Claude Code config into ~/.claude
# Run from any directory. Use --uninstall to remove symlinks.

DOTFILES="$HOME/workspace/dotfiles"
CLAUDE_HOME="$HOME/.claude"
# Claude encodes the home dir path with hyphens replacing dots and slashes
USERNAME_ENCODED=$(whoami | tr '.' '-')
MEMORY_DIR="$CLAUDE_HOME/projects/-Users-$USERNAME_ENCODED/memory"

if [ "$1" = "--uninstall" ]; then
  for f in "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/settings.json" "$CLAUDE_HOME/terse-contract.md"; do
    [ -L "$f" ] && rm "$f" && echo "Removed: $f"
  done
  find "$CLAUDE_HOME/scripts" -type l -delete 2>/dev/null
  find "$CLAUDE_HOME/commands" -type l -delete 2>/dev/null
  find "$CLAUDE_HOME/skills" -type l -delete 2>/dev/null
  find "$CLAUDE_HOME/output-styles" -type l -delete 2>/dev/null
  find "$MEMORY_DIR" -type l -delete 2>/dev/null
  echo "Removed symlinks"
  exit 0
fi

link_file() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    echo "Skipped (already linked): $dst"
  elif [ -e "$dst" ]; then
    echo "WARNING: $dst exists and is not a symlink. Back it up or remove it first."
  else
    ln -s "$src" "$dst"
    echo "Linked: $dst -> $src"
  fi
}

# Top-level files
link_file "$DOTFILES/claude/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
link_file "$DOTFILES/claude/settings.json" "$CLAUDE_HOME/settings.json"
link_file "$DOTFILES/claude/terse-contract.md" "$CLAUDE_HOME/terse-contract.md"

# Scripts
mkdir -p "$CLAUDE_HOME/scripts"
for file in "$DOTFILES/claude/scripts"/*; do
  [ -f "$file" ] || continue
  link_file "$file" "$CLAUDE_HOME/scripts/$(basename "$file")"
done

# Commands
mkdir -p "$CLAUDE_HOME/commands"
for file in "$DOTFILES/claude/commands"/*; do
  [ -f "$file" ] || continue
  link_file "$file" "$CLAUDE_HOME/commands/$(basename "$file")"
done

# Output styles
mkdir -p "$CLAUDE_HOME/output-styles"
for file in "$DOTFILES/claude/output-styles"/*; do
  [ -f "$file" ] || continue
  link_file "$file" "$CLAUDE_HOME/output-styles/$(basename "$file")"
done

# Skills (symlink entire skill directories)
mkdir -p "$CLAUDE_HOME/skills"
for dir in "$DOTFILES/claude/skills"/*/; do
  [ -d "$dir" ] || continue
  skill_name=$(basename "$dir")
  link_file "$dir" "$CLAUDE_HOME/skills/$skill_name"
done

# Memory
mkdir -p "$MEMORY_DIR"
for file in "$DOTFILES/claude/memory"/*; do
  [ -f "$file" ] || continue
  link_file "$file" "$MEMORY_DIR/$(basename "$file")"
done

echo "Done!"
