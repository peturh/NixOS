#!/usr/bin/env bash
# Cycle TLP power profile (low → medium → performance → low) and surface
# the new state through a DMS toast.
#
# Background: under Noctalia the same logic lived in a custom QML bar widget
# (left-click cycle, right-click jump-to-performance). DMS plugins use a
# different manifest format, so we trade the always-visible widget for a
# keybind (SUPER+F11 by default — see lua/binds.lua) plus the `tlp-ctl` CLI
# for everything else. Power-profiles-daemon is force-disabled in the dms
# module because it conflicts with TLP, so this script remains the canonical
# way to change power profiles.

set -euo pipefail

tlp-ctl cycle >/dev/null

profile="$(tlp-ctl get)"

case "$profile" in
  low)         label="Low power" ;;
  medium)      label="Balanced" ;;
  performance) label="Performance" ;;
  *)           label="$profile" ;;
esac

if command -v dms >/dev/null; then
  dms ipc call toast info "Power profile: $label" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null; then
  notify-send "Power profile" "$label"
fi
