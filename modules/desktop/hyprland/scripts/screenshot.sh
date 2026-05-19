#!/usr/bin/env bash
# Region screenshot → satty markup editor.
#
# Replaces the noctalia "screen-shot-and-record" plugin (which we used to bind
# to SUPER+P). DMS only ships an `ipc niri screenshot` IPC for the niri
# compositor; on Hyprland we drive the wlroots screenshot stack directly:
#   slurp           interactive region selector (-d shows a dimmed overlay)
#   grim            captures the selected region as raw PNG to stdout
#   satty           opens the PNG in the markup editor; Ctrl+S writes it to
#                   ~/Pictures/Screenshots, Ctrl+C copies to clipboard.
#
# satty's --early-exit makes it close the moment the region is finalised in
# slurp (otherwise it sticks around as an empty window when you cancel).
# `--copy-command wl-copy` wires Ctrl+C through wl-clipboard so the result
# lands on the Wayland clipboard rather than satty's internal store.

set -euo pipefail

screenshotDir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$screenshotDir"

filename="$screenshotDir/$(date +%Y-%m-%d_%H-%M-%S).png"

geometry=$(slurp -d) || exit 0

grim -g "$geometry" - | satty \
  --filename - \
  --output-filename "$filename" \
  --early-exit \
  --copy-command wl-copy \
  --initial-tool brush \
  --actions-on-enter save-to-clipboard \
  --save-after-copy
