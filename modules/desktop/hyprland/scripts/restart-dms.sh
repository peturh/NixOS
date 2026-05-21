#!/usr/bin/env bash
# Restart DMS (DankMaterialShell, the Quickshell-based desktop shell).
#
# `systemctl --user restart` is the sanctioned way to bounce it.
# `dms restart` exists upstream but it's not a hot-reload: it sends
# SIGUSR1 to the running daemon which exits-on-signal so systemd will
# restart the unit (see core/cmd/dms/shell.go:restartShell). Either
# path triggers the same cold-start path through Theme.qml's
# Component.onCompleted; the light→dark→light flicker that visibly
# accompanies the restart comes from that cold start, not from the
# restart mechanism itself, and is mitigated by the dms-shell package
# patch in ../programs/dms/default.nix.

set -u

systemctl --user restart dms.service
