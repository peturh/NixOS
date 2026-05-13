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
  -- This is what brings up hyprpaper.service, hypridle.service,
  -- swaync.service, hyprpolkitagent.service, etc.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target")

  hl.exec_cmd("waybar")
  hl.exec_cmd("nm-applet --indicator") -- NetworkManager tray applet
  hl.exec_cmd("wl-clipboard-history -t")
  hl.exec_cmd(v.bin.wlPaste .. " --type text --watch cliphist store") -- clipboard store text data
  hl.exec_cmd(v.bin.wlPaste .. " --type image --watch cliphist store") -- clipboard store image data
  hl.exec_cmd("rm '$XDG_CACHE_HOME/cliphist/db'") -- Clear clipboard
  hl.exec_cmd(v.scripts.batterynotify) -- battery notification
  -- hl.exec_cmd(v.scripts.autowaybar) -- uncomment packages at the top
  hl.exec_cmd("polkit-agent-helper-1")
  hl.exec_cmd("pamixer --set-volume 50")
end)