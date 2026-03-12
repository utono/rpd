#!/bin/bash
# ~/.hammerspoon/scripts/screenshot.sh
#
# Takes an interactive screenshot (select area), saves to ~/Pictures/Screenshots/,
# copies file path to clipboard, keeps only 5 newest screenshots.
# Triggered by Hammerspoon global keybind (Cmd+|).

WATCH_DIR="$HOME/Pictures/Screenshots"
MAX_SCREENSHOTS=5

mkdir -p "$WATCH_DIR"

# Generate timestamped filename
filename="screenshot-$(date +%Y%m%d-%H%M%S).png"
filepath="$WATCH_DIR/$filename"

# Interactive area selection screenshot
screencapture -iW "$filepath"

# screencapture exits 0 even if user cancels, but no file is created
[ -f "$filepath" ] || exit 0

# Copy path to clipboard
printf '%s' "$filepath" | pbcopy

# Keep only the 5 most recent screenshots
count=$(ls -1 "$WATCH_DIR"/*.png 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" -gt "$MAX_SCREENSHOTS" ]; then
    ls -1t "$WATCH_DIR"/*.png | tail -n +"$((MAX_SCREENSHOTS + 1))" | while read -r f; do
        rm -f "$f"
    done
fi

# Notify
osascript -e "display notification \"$filename\" with title \"Screenshot\" subtitle \"Path copied to clipboard\""
