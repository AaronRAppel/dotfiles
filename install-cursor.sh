#!/bin/bash
# ~/dotfiles/install-cursor.sh
# Symlinks personal cursor rules and commands into current repo

DOTFILES="$HOME/workspace/dotfiles"

if [ "$1" = "--uninstall" ]; then
  find .cursor/rules/personal -type l -delete 2>/dev/null
  find .cursor/commands/personal -type l -delete 2>/dev/null
  echo "Removed symlinks"
  exit 0
fi

# Rules (symlink individual files)
RULES_SRC="$DOTFILES/cursor-rules/personal"
RULES_DST=".cursor/rules/personal"

if [ -d "$RULES_SRC" ]; then
  mkdir -p "$RULES_DST"
  for file in "$RULES_SRC"/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    if [ ! -e "$RULES_DST/$filename" ]; then
      ln -s "$file" "$RULES_DST/$filename"
      echo "Linked rule: $filename"
    else
      echo "Skipped rule (exists): $filename"
    fi
  done
fi

# Commands (symlink individual files)
COMMANDS_SRC="$DOTFILES/cursor-commands/personal"
COMMANDS_DST=".cursor/commands/personal"

if [ -d "$COMMANDS_SRC" ]; then
  mkdir -p "$COMMANDS_DST"
  for file in "$COMMANDS_SRC"/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    if [ ! -e "$COMMANDS_DST/$filename" ]; then
      ln -s "$file" "$COMMANDS_DST/$filename"
      echo "Linked command: $filename"
    else
      echo "Skipped command (exists): $filename"
    fi
  done
fi

echo "Done!"