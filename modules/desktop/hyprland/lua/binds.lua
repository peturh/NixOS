-- Keybinds. See https://wiki.hypr.land/Configuring/Basics/Binds/
-- Dispatcher reference: https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local v = require("vars")

local mainMod = "SUPER"

--------------------------
-- Repeating resize binds
--------------------------

-- Resize windows with arrow keys.
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- Resize windows with hjkl keys.
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- Repeating functional keys (brightness, volume).
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 2%-"), { repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +2%"), { repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pamixer -d 2"),          { repeating = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pamixer -i 2"),          { repeating = true })

------------------
-- Regular binds
------------------

-- Autoclicker toggle.
hl.bind(mainMod .. " + F8", hl.dsp.exec_cmd("kill $(cat /tmp/auto-clicker.pid) 2>/dev/null || " .. v.bin.autoclicker .. " --cps 40"))
-- hl.bind(mainMod .. " + ALT + mouse:276", hl.dsp.exec_cmd("kill $(cat /tmp/auto-clicker.pid) 2>/dev/null || " .. v.bin.autoclicker .. " --cps 60"))

-- Night Mode (lower value means warmer temp).
hl.bind(mainMod .. " + F9",  hl.dsp.exec_cmd(v.bin.hyprsunset .. " --temperature 3500")) -- good values: 3500, 3000, 2500
hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd("pkill hyprsunset"))

-- Window/Session actions.
hl.bind(mainMod .. " + Q",         hl.dsp.exec_cmd(v.scripts.dontkillsteam))
hl.bind("ALT + F4",                hl.dsp.exec_cmd(v.scripts.dontkillsteam))
hl.bind(mainMod .. " + delete",    hl.dsp.exit()) -- kill Hyprland session
hl.bind(mainMod .. " + W",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.toggle())
hl.bind("ALT + return",            hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + ALT + L",   hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind(mainMod .. " + backspace", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
-- Restart DMS. Wraps `systemctl --user restart dms.service` so the unit's
-- environment, logging, and restart policy are preserved.
hl.bind("CTRL + ESCAPE",           hl.dsp.exec_cmd(v.scripts.restartDms))

-- Applications/Programs.
hl.bind(mainMod .. " + Return",    hl.dsp.exec_cmd(v.term))
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd(v.term))
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(v.fileManager))
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd(v.editor))
hl.bind(mainMod .. " + F",         hl.dsp.exec_cmd(v.browser))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd("youtube-music"))
hl.bind("CTRL + ALT + DELETE",     hl.dsp.exec_cmd(v.term .. " -e '" .. v.bin.btop .. "'")) -- System Monitor
hl.bind(mainMod .. " + CTRL + C",  hl.dsp.exec_cmd("hyprpicker --autocopy --format=hex")) -- Colour Picker

hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd("dms ipc call plugins toggle aiAssistant")) -- toggle AI assistant plugin
hl.bind(mainMod .. " + SPACE",     hl.dsp.exec_cmd("dms ipc call spotlight toggle")) -- launch desktop applications
hl.bind(mainMod .. " + ALT + K",   hl.dsp.exec_cmd(v.scripts.keyboardswitch)) -- change keyboard layout
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("dms ipc call control-center toggle")) -- control center
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("dms ipc call control-center toggle")) -- control center
hl.bind(mainMod .. " + ALT + G",   hl.dsp.exec_cmd(v.scripts.gamemode)) -- disable hypr effects for gamemode
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("dms ipc call clipboard toggle")) -- DMS built-in clipboard manager (cliphist-backed)
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("dms ipc call notifications toggle")) -- notification center
hl.bind(mainMod .. " + comma",     hl.dsp.exec_cmd("dms ipc call settings toggle")) -- DMS settings panel
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("dms ipc call processlist focusOrToggle")) -- task / process list
hl.bind(mainMod .. " + Y",         hl.dsp.exec_cmd("dms ipc call dankdash wallpaper")) -- wallpaper picker

-- Screenshot/Screencapture. DMS only ships a built-in screenshot IPC for
-- the niri compositor; on Hyprland we drive grim + slurp + satty from
-- scripts/screenshot.sh. Inside satty: Ctrl+C copies, Ctrl+S saves,
-- toolbar gives shapes/arrows/text; saved files land in
-- ~/Pictures/Screenshots/<timestamp>.png.
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(v.scripts.screenshot))

-- Cycle TLP power profile (low → medium → performance → low). Replaces
-- the Noctalia bar widget that drove the same script. The keybind path
-- avoids a custom DMS plugin (DMS plugin format is QML-API-incompatible
-- with the noctalia version), and `power-profiles-daemon` is force-
-- disabled in the dms module because it conflicts with TLP.
hl.bind(mainMod .. " + F11",       hl.dsp.exec_cmd(v.scripts.tlpCycle))

-- Functional keybinds.
hl.bind("XF86Sleep",       hl.dsp.exec_cmd("systemctl suspend")) -- Put computer into sleep mode
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t")) -- mute mic
hl.bind("XF86AudioMute",   hl.dsp.exec_cmd("pamixer -t")) -- mute audio
hl.bind("XF86AudioPlay",   hl.dsp.exec_cmd("playerctl play-pause")) -- Play/Pause media
hl.bind("XF86AudioPause",  hl.dsp.exec_cmd("playerctl play-pause")) -- Play/Pause media
hl.bind("XF86AudioNext",   hl.dsp.exec_cmd("playerctl next")) -- go to next media
hl.bind("XF86AudioPrev",   hl.dsp.exec_cmd("playerctl previous")) -- go to previous media

-- Switch between windows in a floating workspace (cycle + bring to top).
hl.bind(mainMod .. " + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next())
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
end)

-- Switch workspaces relative to the active workspace.
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.focus({ workspace = "r-1" }))

-- Move to the first empty workspace instantly.
hl.bind(mainMod .. " + CTRL + down", hl.dsp.focus({ workspace = "empty" }))

-- Move focus with arrow keys.
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind("ALT + Tab",           hl.dsp.focus({ direction = "d" }))

-- Move focus with HJKL keys.
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

-- Go to workspaces 5/6 with mouse side buttons.
hl.bind(mainMod .. " + mouse:276",         hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + mouse:275",         hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + mouse:276", hl.dsp.window.move({ workspace = 5, follow = true }))
hl.bind(mainMod .. " + SHIFT + mouse:275", hl.dsp.window.move({ workspace = 6, follow = true }))
hl.bind(mainMod .. " + CTRL + mouse:276",  hl.dsp.window.move({ workspace = 5, follow = false }))
hl.bind(mainMod .. " + CTRL + mouse:275",  hl.dsp.window.move({ workspace = 6, follow = false }))

-- Rebuild NixOS with a keybind.
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(v.term .. " -e " .. v.scripts.rebuild))

-- Scroll through existing workspaces with mainMod + scroll.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move active window to a relative workspace.
hl.bind(mainMod .. " + CTRL + ALT + right", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind(mainMod .. " + CTRL + ALT + left",  hl.dsp.window.move({ workspace = "r-1", follow = true }))

-- Move active window around current workspace (arrow keys).
hl.bind(mainMod .. " + SHIFT + CTRL + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + CTRL + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + down",  hl.dsp.window.move({ direction = "d" }))

-- Move active window around current workspace (HJKL).
hl.bind(mainMod .. " + SHIFT + CTRL + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + CTRL + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + J", hl.dsp.window.move({ direction = "d" }))

-- Special workspaces (scratchpad).
hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind(mainMod .. " + ALT + S",  hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind(mainMod .. " + S",        hl.dsp.workspace.toggle_special(""))

-------------------
-- Workspace 1..10
-------------------

for i = 1, 10 do
  local key = tostring(i % 10) -- 1..9 then 0 for workspace 10
  hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i, follow = true }))
  hl.bind(mainMod .. " + CTRL + " .. key,    hl.dsp.window.move({ workspace = i, follow = false }))
end

----------------
-- Mouse binds
----------------

-- Move/Resize windows with mainMod + LMB/RMB and dragging.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
