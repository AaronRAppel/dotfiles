#!/bin/bash
# ~/dotfiles/install-cursor.sh
# Symlinks personal cursor rules and commands into current repo

DOTFILES="$HOME/workspace/dotfiles"

if [ "$1" = "--uninstall" ]; then
  find .cursor/rules -type l -delete 2>/dev/null
  find .cursor/commands -type l -delete 2>/dev/null
  echo "Removed symlinks"
  exit 0
fi

# Rules
RULES_SRC="$DOTFILES/cursor-rules"
RULES_DST=".cursor/rules"

if [ -d "$RULES_SRC" ]; then
  mkdir -p "$RULES_DST"
  for file in "$RULES_SRC"/*.mdc; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")
    if [ ! -e "$RULES_DST/$filename" ]; then
      ln -s "$file" "$RULES_DST/$filename"
      echo "Linked rule: $filename"
    else
      echo "Skipped rule (exists): $filename"
    fi
  done
fi

# Commands
COMMANDS_SRC="$DOTFILES/cursor-commands"
COMMANDS_DST=".cursor/commands"

if [ -d "$COMMANDS_SRC" ]; then
  mkdir -p "$COMMANDS_DST"
  for file in "$COMMANDS_SRC"/*.md; do
    [ -e "$file" ] || continue
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