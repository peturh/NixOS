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
  -- the caelestia.service (defined by the caelestia HM module).
  hl.exec_cmd("dbus-update-activation-environment --systemd --all && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")

  -- nm-applet still feeds the system tray that caelestia's bar renders.
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("polkit-agent-helper-1")
  hl.exec_cmd("pamixer --set-volume 50")
end)