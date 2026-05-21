-- Autostart. See https://wiki.hypr.land/Configuring/Basics/Autostart/

local v = require("vars")

hl.on("hyprland.start", function()
  -- hl.exec_cmd("[workspace 1 silent] slack")
  -- hl.exec_cmd("[workspace 2 silent] " .. v.browser)
  -- hl.exec_cmd("[workspace 3 silent] " .. v.editor)
  -- hl.exec_cmd("[workspace 6 silent] " .. v.term)
  -- hl.exec_cmd("[workspace special silent] " .. v.browser .. " --private-window")
  -- hl.exec_cmd("[workspace special silent] " .. v.term)

  -- Activate the user systemd graphical session. Home-manager normally emits
  -- this as `exec-once` in hyprland.conf, but Hyprland 0.55+ prefers
  -- hyprland.lua and silently ignores hyprland.conf, so we replay it here.
  -- This is what brings up hypridle.service, hyprpolkitagent.service, and
  -- (now) dms.service via hyprland-session.target.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")

  -- DMS (DankMaterialShell) is started by hyprland-session.target via the
  -- home-manager dms module (`programs.dank-material-shell.systemd.enable
  -- = true`). No need to spawn it manually here. CTRL+ESCAPE restarts it
  -- via scripts/restart-dms.sh (`systemctl --user restart dms.service`).

  hl.exec_cmd("polkit-agent-helper-1")
  hl.exec_cmd("pamixer --set-volume 50")

  -- Work comms autostart on workspace 10 (pinned to the laptop by
  -- monitors.lua when an external display is connected). `silent` keeps
  -- focus on the active workspace so the session doesn't yank to ws10
  -- mid-login. `command -v` guards mean the other two ThinkPads (which
  -- don't ship Slack/Teams — work-only, see hosts/t14s) skip cleanly
  -- instead of leaving "not found" noise in the journal.
  hl.exec_cmd("[workspace 10 silent] command -v slack           >/dev/null && exec slack")
  hl.exec_cmd("[workspace 10 silent] command -v teams-for-linux >/dev/null && exec teams-for-linux")

  -- Clipboard history daemon for DMS's built-in clipboard manager
  -- (SUPER+V → `dms ipc call clipboard toggle`). `wl-paste --watch
  -- cliphist store` listens to the Wayland clipboard and streams entries
  -- into cliphist's DB; DMS reads from that DB. `pkill -x wl-paste`
  -- first so a replayed hyprland.start (e.g. on session restart) doesn't
  -- leave two watcher processes racing each other to write the same
  -- entry. Two watchers are required because wl-paste only consumes one
  -- MIME family at a time: text vs image. cliphist itself deduplicates
  -- and dispatches per-type so the DB stays coherent.
  hl.exec_cmd("pkill -x wl-paste; wl-paste --type text  --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- DMS-driven border colors. hyprland.lua reads ~/.config/hypr/dms/colors.conf
  -- at config load and applies via hl.config, but on a cold boot Hyprland
  -- starts before DMS has had a chance to render the file, so the initial
  -- pass is a no-op and borders fall back to compiled-in defaults. Wait for
  -- DMS to write the file once, then trigger a single `hyprctl reload` so
  -- hyprland.lua re-runs against the now-populated file. The flag in
  -- $XDG_RUNTIME_DIR makes this idempotent across `hyprctl reload` (which
  -- may re-fire `hyprland.start`) and self-clears on logout because
  -- $XDG_RUNTIME_DIR/$UID is wiped when the last user process exits. On
  -- subsequent DMS palette changes (wallpaper / dark-light toggle) Hyprland
  -- is already up, so a manual reload picks them up.
  hl.exec_cmd("sh -c 'f=\"$XDG_RUNTIME_DIR/hypr-dms-colors-loaded\"; [ -e \"$f\" ] && exit 0; colors=\"$HOME/.config/hypr/dms/colors.conf\"; for _ in $(seq 1 100); do [ -s \"$colors\" ] && { touch \"$f\"; exec hyprctl reload; }; sleep 0.3; done'")
end)