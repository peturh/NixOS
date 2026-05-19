#!/usr/bin/env bash
# Restart Noctalia (the Quickshell-based desktop shell).
#
# Noctalia is spawned via autostart.lua (systemd startup is deprecated upstream,
# see https://docs.noctalia.dev/v4/getting-started/nixos/#running-the-shell),
# so "restart" = kill + respawn.
#
# Why a separate script instead of `sh -c '...'` directly in binds.lua:
#   The actual running process is the wrapped quickshell binary
#   (`.quickshell-wrapped`, exec'd by the noctalia-shell C wrapper), so neither
#   `pkill -x noctalia-shell` nor `pkill -f noctalia-shell` matches it. We need
#   `pkill -f quickshell`. But when that lived inside `sh -c '... quickshell ...'`,
#   the sh process's own /proc/<pid>/cmdline contained the literal string
#   "quickshell" -- so `pkill -f quickshell` instantly killed the wrapping sh,
#   and the `sleep; respawn` tail never ran. Moving it into a script file fixes
#   the bug because the script's cmdline is just its nix-store path.

set -u

pkill -f quickshell || true

sleep 0.5

# `setsid` puts noctalia-shell in its own session so it survives this script
# exiting (Hyprland's exec dispatcher doesn't track it any further). The
# stdio redirection prevents it from inheriting Hyprland's tty/log fds.
setsid -f noctalia-shell </dev/null >/dev/null 2>&1
