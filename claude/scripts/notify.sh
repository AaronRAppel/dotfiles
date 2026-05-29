#!/bin/bash
# Sends a macOS notification unless the user is looking at the app running Claude.
# Clicking the notification activates the host terminal app.
# Usage: notify.sh "message text"

MESSAGE="${1:-Claude needs your attention}"

# Find the terminal app by walking up the process tree
HOST_APP=""
BUNDLE_ID=""
pid=$$
while [ "$pid" -ne 1 ] && [ -n "$pid" ]; do
  cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
  case "$cmd" in
    */Terminal.app/*)  HOST_APP="Terminal";  BUNDLE_ID="com.apple.Terminal"; break ;;
    */iTerm.app/*)     HOST_APP="iTerm2";    BUNDLE_ID="com.googlecode.iterm2"; break ;;
    */Code)            HOST_APP="Code";      BUNDLE_ID="com.microsoft.VSCode"; break ;;
    */Warp.app/*)      HOST_APP="Warp";      BUNDLE_ID="dev.warp.Warp-Stable"; break ;;
    *RubyMine*)        HOST_APP="rubymine";  BUNDLE_ID="com.jetbrains.rubymine"; break ;;
    */Claude.app/*)    exit 0 ;;  # Claude Code desktop sends its own notifications
  esac
  pid=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ')
done

FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

if [ -n "$HOST_APP" ] && [ "$FRONT_APP" = "$HOST_APP" ]; then
  exit 0
fi

ACTIVATE_ARGS=()
if [ -n "$BUNDLE_ID" ]; then
  ACTIVATE_ARGS=(-execute "open -b $BUNDLE_ID")
fi

PATH="$HOME/.local/share/mise/installs/ruby/3.4.9/bin:$PATH" $HOME/.local/share/mise/installs/ruby/3.4.9/bin/terminal-notifier -message "$MESSAGE" -title "Claude Code" -sound Ping "${ACTIVATE_ARGS[@]}"
