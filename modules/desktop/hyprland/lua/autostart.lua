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
end)