-- Monitor configuration. See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Easily plug in any monitor (fallback).
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1,
})

-- Laptop (same at work and home).
hl.monitor({
  output = "desc:Lenovo Group Limited 0x403A",
  mode = "1920x1200@60",
  position = "auto",
  scale = 1,
})

-- Work Setup: Samsung 4K (LS32D80xU) on the left, laptop auto-positioned to the right.
-- Center-aligned vertically for easier mouse movement.
hl.monitor({
  output = "desc:Samsung Electric Company LS32D80xU",
  mode = "3840x2160@60",
  position = "auto-left",
  scale = 1,
})

-- Home Setup: laptop auto-positioned to the left, Samsung ultrawide on the right.
-- Center-aligned vertically for easier mouse movement.
hl.monitor({
  output = "desc:Samsung Electric Company S34C65xU",
  mode = "3440x1440@60",
  position = "auto-right",
  scale = 1,
})

----------------
-- Workspace anchoring
----------------

-- Workspace 1 is the "primary" workspace and 10 is the dedicated comms
-- workspace (Slack/Teams autostart there — see autostart.lua). Marking them
-- persistent keeps both visible on the DMS bar even when empty so the pager
-- stays stable across reboots, hot-plug, and `nixos-rebuild switch` reloads.
hl.workspace_rule({ workspace = "1",  persistent = true })
hl.workspace_rule({ workspace = "10", persistent = true })

-- With an external display connected, workspace 1 lives on the external and
-- workspace 10 stays pinned to the laptop (so comms apps never get yanked
-- across when an external is plugged in mid-session). Matched by connector
-- name rather than EDID description so it works uniformly on all three
-- ThinkPads (eDP-1 on every host, while external descriptions vary by
-- work/home setup). With only the laptop attached this is a no-op and both
-- workspaces sit on eDP-1.
local function applyWorkspaceLayout()
  local laptop, external
  for _, m in ipairs(hl.get_monitors()) do
    if m.name:find("^eDP") then
      laptop = m
    elseif not external then
      external = m
    end
  end
  if external and laptop then
    hl.exec_cmd("hyprctl dispatch moveworkspacetomonitor 1 "  .. external.name)
    hl.exec_cmd("hyprctl dispatch moveworkspacetomonitor 10 " .. laptop.name)
  end
end

hl.on("hyprland.start", applyWorkspaceLayout)
hl.on("monitor.added",  applyWorkspaceLayout)
