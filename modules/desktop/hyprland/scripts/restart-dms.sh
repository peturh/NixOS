#!/usr/bin/env bash
# Restart DMS (DankMaterialShell, the Quickshell-based desktop shell).
#
# DMS runs as the systemd user service `dms.service`, started by
# hyprland-session.target via the home-manager integration in
# modules/desktop/hyprland/programs/dms/default.nix. `systemctl --user
# restart` is the sanctioned way to bounce it (preserves the unit's
# environment, restart policy, journal); upstream's own `dms restart`
# just shells out to the same systemctl call when the service is
# managed.

set -u

systemctl --user restart dms.service
