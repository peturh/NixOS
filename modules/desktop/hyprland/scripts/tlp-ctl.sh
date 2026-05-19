#!/usr/bin/env bash

if ! command -v tlp >/dev/null; then
    echo "Couldn't find tlp. Exiting." >&2
    exit 1
fi

# Records the user's explicit profile choice across invocations. Without
# this, `get_profile` could only infer state from AC + a perf marker, which
# meant choosing "low" while on AC would silently look like "medium" on the
# next read (because on-AC + no-perf-marker == medium). The state file is
# stamped with the AC state at write time: when AC plug state changes the
# stored choice is treated as stale and we fall back to the AC-state
# default (medium on AC, low on battery). This matches what TLP itself
# does on udev plug events (it re-runs `tlp auto` and overrides our
# manual `tlp ac` / `tlp bat` calls), so the stale-state fallback keeps
# the indicator honest.
STATE_FILE="/tmp/tlp-ctl-state"
SCRIPT_PATH="$(readlink -f "$0")"

# ==== Usage ====
USAGE="
Usage: $0 [COMMAND] [ARGUMENTS] [COMMAND_OPTIONS]
       $0 -h

OPTIONS:
    -h, --help      Show this message

COMMANDS:
    get             Get current profile (default)
                    Options: --json, -v | --verbose
    set [low|medium|performance|auto]
                    Set power profile
    cycle           Cycle through low → medium → performance
    toggle          Toggle performance mode on/off
    --              Pass args to tlp
"

Help() { echo "$USAGE"; }


# ==== Internal (run via pkexec as root) ====

_apply_performance() {
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance > "$gov" 2>/dev/null
    done
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        echo performance > "$epp" 2>/dev/null
    done
    [ -f /sys/devices/system/cpu/cpufreq/boost ] && echo 1 > /sys/devices/system/cpu/cpufreq/boost
    [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ] && echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
    [ -f /sys/firmware/acpi/platform_profile ] && echo performance > /sys/firmware/acpi/platform_profile
}


# ==== Functions ====

is_on_ac() {
    for supply in /sys/class/power_supply/*/online; do
        [ -f "$supply" ] && [ "$(cat "$supply" 2>/dev/null)" = "1" ] && return 0
    done
    return 1
}

current_ac_state() {
    if is_on_ac; then echo 1; else echo 0; fi
}

# Default profile when nothing is manually set: balanced on AC, leaf on
# battery. This is what `get_profile` returns whenever the state file is
# missing or stale (AC plug state changed since we wrote it).
default_profile() {
    if is_on_ac; then echo medium; else echo low; fi
}

# State file format: "<profile>:<ac_state>", e.g. "performance:1".
read_state() {
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE" 2>/dev/null
}

write_state() {
    echo "$1:$(current_ac_state)" > "$STATE_FILE"
}

clear_state() {
    rm -f "$STATE_FILE"
}

get_profile() {
    local profile handling format stored profile_part ac_part
    format="${1:-}"
    stored=$(read_state)
    profile_part="${stored%%:*}"
    ac_part="${stored##*:}"

    if [ -n "$profile_part" ] && [ "$ac_part" = "$(current_ac_state)" ]; then
        profile="$profile_part"
        handling="manual"
    else
        profile="$(default_profile)"
        handling="auto"
    fi
    print_profile "$profile" "$handling" "$format"
}

set_profile() {
    case "${1:-}" in
        low)
            write_state low
            pkexec tlp bat
            ;;
        medium)
            write_state medium
            pkexec tlp ac
            ;;
        performance)
            write_state performance
            pkexec tlp ac
            pkexec "$SCRIPT_PATH" _apply_performance
            ;;
        auto)
            clear_state
            pkexec tlp start
            ;;
        *)
            echo "Unknown profile: ${1:-}" >&2
            exit 1
            ;;
    esac
}

toggle_profile() {
    local current
    current=$(get_profile)
    if [ "$current" = "performance" ]; then
        set_profile auto
    else
        set_profile performance
    fi
}

cycle_profile() {
    local current next
    current=$(get_profile)
    case "$current" in
        low)         next=medium ;;
        medium)      next=performance ;;
        performance) next=low ;;
        *)           next="$(default_profile)" ;;
    esac
    set_profile "$next"
}

print_profile() {
    local profile="${1:-}"
    local handling="${2:-}"

    case "${3:-}" in
        --json)
            jq -n --unbuffered --compact-output \
                --arg profile "$profile" \
                --arg tooltip "Power: $profile ($handling)" \
                --arg handling "$handling" \
                '{
                    "text": $profile, "alt": $profile,
                    "tooltip": $tooltip,
                    "class": [ $profile, $handling ]
                }'
            ;;
        -v | --verbose)
            echo "$profile"
            echo "Power: $profile ($handling)"
            echo "$profile,$handling"
            ;;
        *)
            echo "$profile"
            ;;
    esac
}


# ==== Main ====

# Wrapped by pkgs.writeShellApplication, which enables `set -euo pipefail`.
# Guard every positional access with a default so `tlp-ctl get` (no $2),
# bare `tlp-ctl` (no $1), etc. don't trip set -u with "unbound variable".
cmd="${1:-}"
arg="${2:-}"

case "$cmd" in
    -h | --help)
        Help
        exit 0
        ;;
    "" | get)
        get_profile "$arg"
        ;;
    set)
        set_profile "$arg"
        ;;
    toggle)
        toggle_profile
        ;;
    cycle)
        cycle_profile
        ;;
    _apply_performance)
        _apply_performance
        ;;
    --)
        tlp "${@:2}"
        ;;
    *)
        echo "Unknown command: $cmd" >&2
        exit 1
        ;;
esac
