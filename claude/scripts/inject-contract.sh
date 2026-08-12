#!/bin/bash
# UserPromptSubmit hook: prints the pre-send checklist on every turn, plus any
# violations style-check.sh recorded for the previous response. Stdout becomes context.

cat "$HOME/.claude/terse-contract.md" 2>/dev/null

# Read without clearing: style-check.sh rewrites this file from scratch after every
# response, so it always describes the latest one. Clearing here instead would lose the
# violation for good if a single injection were dropped or the turn retried.
VIOLATIONS="$HOME/.claude/style-violations.txt"
if [ -s "$VIOLATIONS" ]; then
  echo
  echo "## Your previous response violated the checklist"
  cat "$VIOLATIONS"
  echo "Correct this in the response you are about to write."
fi

exit 0
