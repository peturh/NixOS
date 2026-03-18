#!/usr/bin/env bash

if ! command -v tlp >/dev/null; then
    echo "Couldn't find tlp. Exiting." >&2
    exit 1
fi

PERF_MARKER="/tmp/tlp-performance-mode"
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

is_performance_active() {
    [ -f "$PERF_MARKER" ] || return 1
    local gov
    gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    if [ "$gov" != "performance" ]; then
        rm -f "$PERF_MARKER"
        return 1
    fi
    return 0
}

get_profile() {
    local profile handling
    if is_performance_active; then
        profile="performance"
        handling="manual"
    elif is_on_ac; then
        profile="medium"
        handling="auto"
    else
        profile="low"
        handling="auto"
    fi
    print_profile "$profile" "$handling" "$1"
}

set_profile() {
    case "$1" in
        low)
            rm -f "$PERF_MARKER"
            pkexec tlp bat
            ;;
        medium)
            rm -f "$PERF_MARKER"
            pkexec tlp ac
            ;;
        performance)
            pkexec tlp ac
            pkexec "$SCRIPT_PATH" _apply_performance
            touch "$PERF_MARKER"
            ;;
        auto)
            rm -f "$PERF_MARKER"
            pkexec tlp start
            ;;
        *)
            echo "Unknown profile: $1" >&2
            exit 1
            ;;
    esac
}

toggle_profile() {
    if is_performance_active; then
        set_profile auto
    else
        set_profile performance
    fi
}

print_profile() {
    local profile="$1"
    local handling="$2"

    case "$3" in
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

case "$1" in
    -h | --help)
        Help
        exit 0
        ;;
    "" | get)
        get_profile "$2"
        ;;
    set)
        set_profile "$2"
        ;;
    toggle)
        toggle_profile
        ;;
    _apply_performance)
        _apply_performance
        ;;
    --)
        tlp "${@:2}"
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
