#!/usr/bin/env bash
# Waybar control for the Orca screen reader.
#
#   status   Print JSON describing whether Orca is running (default).
#   toggle   Start Orca if stopped, quit it if running.
#   start    Start Orca (no-op if already running).
#   stop     Stop Orca via --quit, falling back to pkill.

set -u

ICON="󰔊"

is_running() {
    pgrep -x orca >/dev/null 2>&1
}

print_status() {
    if is_running; then
        printf '{"text":"%s","class":"active","tooltip":"Orca screen reader: ON\\nClick to stop"}\n' "$ICON"
    else
        printf '{"text":"%s","class":"inactive","tooltip":"Orca screen reader: OFF\\nClick to start"}\n' "$ICON"
    fi
}

start_orca() {
    if ! is_running; then
        # Detach completely so Waybar's on-click handler doesn't keep a parent
        # around (Orca would otherwise die when Waybar reaps it).
        setsid orca >/dev/null 2>&1 < /dev/null &
        disown 2>/dev/null || true
    fi
}

stop_orca() {
    if is_running; then
        orca --quit >/dev/null 2>&1 || pkill -x orca || true
    fi
}

cmd="${1:-status}"
case "$cmd" in
    status) print_status ;;
    toggle)
        if is_running; then stop_orca; else start_orca; fi
        ;;
    start) start_orca ;;
    stop)  stop_orca ;;
    *)
        echo "Usage: $0 [status|toggle|start|stop]" >&2
        exit 2
        ;;
esac
