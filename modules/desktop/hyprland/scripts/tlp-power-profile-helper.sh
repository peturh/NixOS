#!/usr/bin/env bash
# Companion helper for the tlp-power-profile DMS plugin (installed via
# the DMS plugin store from github.com/peturh/tlp-power-profile).
#
# TLP itself only exposes two modes (ac, bat). This script layers a
# "performance" mode on top, mirroring what power-profiles-daemon does on
# AC: force the cpufreq governor + EPP + turbo + ACPI platform profile to
# their performance equivalents. It first invokes `tlp ac` so TLP's own
# state stays consistent, then writes the perf overrides via sysfs. Each
# sysfs write is best-effort — laptops vary in which knobs they expose, so
# a missing file is not an error.
#
# Invoked under pkexec by the plugin; polkit grants the `power` group
# password-less pkexec via modules/programs/misc/tlp/default.nix.

set -e

case "${1:-}" in
    performance)
        tlp ac

        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [ -w "$gov" ] && echo performance > "$gov" 2>/dev/null || true
        done

        for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            [ -w "$epp" ] && echo performance > "$epp" 2>/dev/null || true
        done

        [ -w /sys/devices/system/cpu/cpufreq/boost ] && \
            echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true

        [ -w /sys/devices/system/cpu/intel_pstate/no_turbo ] && \
            echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true

        [ -w /sys/firmware/acpi/platform_profile ] && \
            echo performance > /sys/firmware/acpi/platform_profile 2>/dev/null || true
        ;;
    -h|--help|"")
        cat <<EOF
Usage: $0 performance

Applies a 'performance' overlay on top of \`tlp ac\`: forces cpufreq
governor / EPP / turbo / platform_profile to performance.

Run as root (pkexec or sudo).
EOF
        ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Try: $0 --help" >&2
        exit 1
        ;;
esac
