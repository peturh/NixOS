#!/usr/bin/env bash

# wwan-ctl — thin wrapper around ModemManager + NetworkManager used by the
# DMS wwanCtl plugin. `nmcli connection up/down` is enough to drive the
# Telenor profile end-to-end (NM internally enables/disables the modem
# through ModemManager), so neither this script nor the QML widget needs
# polkit / pkexec — the user is in the `networkmanager` group.

# Single-modem assumption: matches the t14s hardware (one Intel XMM7560
# soldered down). We use `-m any` rather than `-m 0` because the modem's
# D-Bus index isn't stable — it bumps to /Modem/1, /Modem/2, … each time
# ModemManager rediscovers the device (hot-replug, suspend/resume, MM
# restart). If a second modem ever appears we'd have to resolve the path
# from `mmcli -L` instead.

CONNECTION_NAME="Telenor WWAN"
WWAN_DEVICE="wwan0mbim0"

USAGE="
Usage: $0 [COMMAND]

COMMANDS:
    get             Print modem state (default)
                    Options: --json
    connect         Bring the Telenor WWAN connection up
    disconnect      Bring the Telenor WWAN connection down
    toggle          Connect if down, disconnect if up
"

Help() { echo "$USAGE"; }

# Strip ANSI escapes that mmcli emits when stdout is a TTY-like sink.
_strip_ansi() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Pull a field out of `mmcli -m 0` by suffix-matching its label.
# Example: mm_field "$mm" "state" → "connected"
#
# Returns 0 with empty stdout when the field is absent. mmcli omits
# fields depending on modem state (an enabled-but-not-registered modem
# has no `access tech` / `operator name`), and since writeShellApplication
# turns on `set -euo pipefail` a failing grep here would kill the script.
mm_field() {
    local haystack="$1" needle="$2"
    printf "%s" "$haystack" \
        | { grep -E "^\s*\|\s*${needle}:" || true; } \
        | head -1 \
        | sed -E "s/^[^:]*${needle}:\s*//" \
        | sed 's/^[ \t]*//;s/[ \t]*$//'
}

get_status() {
    local mm_raw mm state signal tech operator ip nm_state present

    mm_raw=$(mmcli -m any 2>/dev/null || true)
    mm=$(printf "%s" "$mm_raw" | _strip_ansi)

    if [ -z "$mm" ]; then
        present="false"
        state="absent"
        signal=0
        tech=""
        operator=""
    else
        present="true"
        state=$(mm_field "$mm" "state")
        # "38% (recent)" → "38". Same set-e survival trick as mm_field —
        # an absent signal-quality line would otherwise abort the pipeline.
        signal=$(mm_field "$mm" "signal quality" | { grep -oE '[0-9]+' || true; } | head -1)
        tech=$(mm_field "$mm" "access tech")
        operator=$(mm_field "$mm" "operator name")
    fi

    : "${signal:=0}"
    : "${state:=unknown}"

    nm_state=$(nmcli -t -f GENERAL.STATE device show "$WWAN_DEVICE" 2>/dev/null \
        | awk -F: '{print $2}' | sed 's/^ *//;s/ *$//' || true)
    ip=$(nmcli -t -f IP4.ADDRESS device show "$WWAN_DEVICE" 2>/dev/null \
        | awk -F: '{print $2}' | head -1 | sed 's/^ *//;s/ *$//' || true)

    case "${1:-}" in
        --json)
            jq -n --compact-output \
                --argjson present "$present" \
                --arg state "$state" \
                --argjson signal "$signal" \
                --arg tech "$tech" \
                --arg operator "$operator" \
                --arg ip "$ip" \
                --arg nmState "$nm_state" \
                '{
                    present: $present,
                    state: $state,
                    signal: $signal,
                    tech: $tech,
                    operator: $operator,
                    ip: $ip,
                    nmState: $nmState,
                    connected: ($state == "connected")
                }'
            ;;
        *)
            echo "state=$state signal=${signal}% tech=$tech operator=$operator ip=$ip"
            ;;
    esac
}

is_connected() {
    nmcli -t -f GENERAL.STATE device show "$WWAN_DEVICE" 2>/dev/null \
        | grep -q "100 (connected)"
}

cmd_connect() { nmcli connection up "$CONNECTION_NAME"; }
cmd_disconnect() { nmcli connection down "$CONNECTION_NAME"; }
cmd_toggle() {
    if is_connected; then cmd_disconnect; else cmd_connect; fi
}

# Wrapped by pkgs.writeShellApplication, which enables `set -euo pipefail`.
cmd="${1:-}"
arg="${2:-}"

case "$cmd" in
    -h | --help) Help; exit 0 ;;
    "" | get | status) get_status "$arg" ;;
    connect) cmd_connect ;;
    disconnect) cmd_disconnect ;;
    toggle) cmd_toggle ;;
    *) echo "Unknown command: $cmd" >&2; exit 1 ;;
esac
