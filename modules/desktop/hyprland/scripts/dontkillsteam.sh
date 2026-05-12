#!/usr/bin/env bash
# Hyprland 0.55 rewrote the dispatcher system to route through the Lua API,
# so the old `killactive` dispatcher name no longer resolves. Pass the Lua
# dispatcher expression to hyprctl instead. See:
# https://github.com/hyprwm/Hyprland/releases/tag/v0.55.0
if [[ $(hyprctl activewindow -j | jq -r ".class") == "Steam" ]]; then
    xdotool windowunmap "$(xdotool getactivewindow)"
else
    hyprctl dispatch "hl.dsp.window.close()"
fi
