# Log out of the Hyprland session without ever killing sddm-helper.
#
# SDDM 0.21 maps a SIGTERMed sddm-helper to HELPER_AUTH_ERROR (QProcess
# CrashExit → exit code 1) and Display::slotHelperFinished then skips the
# greeter restart: the result is a black screen that only a hard reboot
# fixes. `loginctl terminate-session` kills the whole session scope,
# helper included, so it must not run while Hyprland is alive.
#
# Instead: ask Hyprland to exit (Lua config syntax: `hl.dsp.exit()`; a bare
# `dispatch exit` is rejected by Hyprland >= 0.56), wait for it, and let the chain
# (Hyprland → start-hyprland → sddm-helper exit 0 → SDDM respawns greeter)
# end the session. Fall back to SIGTERM on the compositor process only.
# Each step is logged to ~/.cache/hypr-logout.log so a bad logout can be
# diagnosed afterwards (the Hyprland log itself lives on tmpfs).

set -u

log=${XDG_CACHE_HOME:-$HOME/.cache}/hypr-logout.log
sig=${HYPRLAND_INSTANCE_SIGNATURE:-}
hlog=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/$sig/hyprland.log

say() { printf '%s %s\n' "$(date '+%F %T.%3N')" "$*" >>"$log"; }

alive() { hyprctl -i "$sig" version >/dev/null 2>&1; }

hypr_pid() { pgrep -u "$(id -u)" -f '/bin/Hyprland( |$)' | head -1; }

snapshot() {
  [ -r "$hlog" ] && tail -n 300 "$hlog" >"${log%.log}-hyprland-tail.log" 2>/dev/null
}

say "logout requested (session=${XDG_SESSION_ID:-?} sig=$sig pid=$(hypr_pid))"

if ! alive; then
  say "hyprland not reachable; nothing to do"
  exit 0
fi

say "hyprctl dispatch exit -> $(hyprctl -i "$sig" dispatch 'hl.dsp.exit()' 2>&1)"

for i in $(seq 1 200); do # 20 s
  alive || { say "hyprland gone after ~$((i / 10)).$((i % 10))s"; snapshot; exit 0; }
  [ "$((i % 20))" -eq 0 ] && snapshot
  sleep 0.1
done

pid=$(hypr_pid)
say "hyprland still alive after 20s (pid=$pid); sending SIGTERM to the compositor only"
snapshot
[ -n "$pid" ] && kill -TERM "$pid" 2>/dev/null

for i in $(seq 1 100); do # 10 s
  alive || { say "hyprland gone after SIGTERM (~$((i / 10))s)"; snapshot; exit 0; }
  sleep 0.1
done

say "hyprland did not exit; giving up without touching the session (reboot needed)"
snapshot
exit 1
