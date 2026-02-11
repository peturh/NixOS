#!/usr/bin/env bash

# Check for playerctl existence
if ! command -v tlp >/dev/null; then
    echo "Couldn't find tlp. Exiting." >&2
    exit 1
fi

# ==== Usage ====
USAGE="
Usage: $0 [COMMAND] [ARGUMENTS] [COMMAND_OPTIONS]
       $0 -h

OPTIONS:

    -h, --help      Show this message

COMMANDS:
    get
        Get mode (default)
        Options: --json, -v | --verbose
    set [bat|ac|auto]
        Set mode

    toggle
        Toggle mode

    --
        Pass args to tlp
"

function Help() {
    echo "$USAGE"
}


# ==== Functions ====

# ---- Mode functions ----

get_mode() {
    local raw_mode=$(tlp-stat -m)
    local handling
    case "$raw_mode" in
        *"(manual)" )
            handling=manual
            raw_mode="${raw_mode%% *}" # Remove everything after the first space
            ;;
        * )
            handling=auto
            ;;
    esac
    # Normalize mode to lowercase for consistency
    raw_mode=$(echo "$raw_mode" | tr '[:upper:]' '[:lower:]')
    # Extract power source from "profile/source" format (e.g. "performance/ac" -> "ac")
    local mode
    if [[ "$raw_mode" == */* ]]; then
        mode="${raw_mode##*/}"
    else
        mode="$raw_mode"
    fi
    # Normalize "bat" to "battery" for waybar format-icons matching
    [[ "$mode" == "bat" ]] && mode="battery"
    print_mode "TLP Mode" "$mode" "$handling" "$1"
}

set_mode() {
    local mode="$1"
    case "$mode" in
        bat* )
            pkexec tlp bat;;
        ac ) 
            pkexec tlp ac;;
        auto )
            pkexec tlp start;;
        * )
            echo "Unknown mode: $mode" >&2
            exit 1;;
    esac
}

toggle_mode() {
    local raw_mode=$(tlp-stat -m)
    # Normalize and extract power source from "profile/source" format
    raw_mode=$(echo "$raw_mode" | tr '[:upper:]' '[:lower:]')
    local mode
    if [[ "$raw_mode" == */* ]]; then
        mode="${raw_mode##*/}"
    else
        mode="$raw_mode"
    fi
    case "$mode" in
        bat* ) 
            pkexec tlp ac;;
        * )
            pkexec tlp bat;;
    esac
}


# ---- Lib functions ----

function print_mode() {
    local param="$1"
    local mode="$2"
    local handling="$3"

    case "$4" in
        --json )
            jq -n --unbuffered --compact-output \
                --arg mode "$mode" \
                --arg tooltip "$param: $mode ($handling)" \
                --arg handling "$handling" \
                '{
                    "text": $mode, "alt": $mode,
                    "tooltip": $tooltip,
                    "class": [ $mode, $handling ]
                }'
            ;;
        -v | --verbose )
            echo "$mode"
            echo "$param: $mode ($handling)"
            echo "$mode","$handling"
            ;;
        * )
            [ -n "$mode" ] && echo "$mode" || echo "$param";;
    esac
}


# ==== Main ====

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    Help
    exit 0
fi

case "$1" in
    -h | --help )
        Help
        exit 0;;
    "" | get )
        get_mode "$2";;
    set )
        set_mode "$2";;
    toggle )
        toggle_mode;;
    -- )
        tlp "${@:2}";;
    * )
        echo "Unknown command: $1" >&2
        exit 1;;
esac