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
  -- This is what brings up hypridle.service and hyprpolkitagent.service.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")

  -- Spawn Noctalia. Systemd startup is deprecated upstream
  -- (https://docs.noctalia.dev/v4/getting-started/nixos/#running-the-shell)
  -- so we launch it directly here. CTRL+ESCAPE restarts it via pkill.
  hl.exec_cmd("noctalia-shell")

  hl.exec_cmd("polkit-agent-helper-1")
  hl.exec_cmd("pamixer --set-volume 50")

  -- Clipboard history daemon for the noctalia "clipper" plugin
  -- (SUPER+V). `wl-paste --watch cliphist store` listens to the
  -- Wayland clipboard and streams entries into cliphist's DB; the
  -- plugin reads from that DB. `pkill -x wl-paste` first so a
  -- replayed hyprland.start (e.g. on session restart) doesn't leave
  -- two watcher processes racing each other to write the same entry.
  -- Two watchers are required because wl-paste only consumes one MIME
  -- family at a time: text vs image. cliphist itself deduplicates
  -- and dispatches per-type so the DB stays coherent.
  hl.exec_cmd("pkill -x wl-paste; wl-paste --type text  --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)