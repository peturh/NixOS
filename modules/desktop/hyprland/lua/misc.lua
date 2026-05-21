-- misc / render / ecosystem / xwayland / dwindle / master / group / binds settings.

hl.config({
  render = {
    -- explicit_sync = 1, -- 0 = off, 1 = on, 2 = auto based on gpu driver.
    -- explicit_sync_kms = 2, -- 0 = off, 1 = on, 2 = auto based on gpu driver.
    direct_scanout = 2, -- 0 = off, 1 = on, 2 = auto (on with content type 'game')
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },

  misc = {
    disable_hyprland_logo = true,
    mouse_move_focuses_monitor = true,
    -- Hyprland swallows the launching terminal when a graphical child opens.
    -- Match against `initialClass`: ghostty announces itself as
    -- `com.mitchellh.ghostty` over Wayland, kitty as `kitty`.
    swallow_regex = "^(com\\.mitchellh\\.ghostty|kitty)$",
    enable_swallow = true,
    vrr = 0, -- enable variable refresh rate (0=off, 1=on, 2=fullscreen only)
  },

  -- Hyprland 0.55 moved vfr out of `misc` into `debug`. Default is `true`
  -- (skip redraws when nothing changes — good for idle battery), but with
  -- VFR on, PipeWire screencast frames go out at a jittery cadence and
  -- Teams' encoder renders the gaps as visible flicker on the receiving
  -- end. Force constant frame delivery so screen-sharing looks clean to
  -- the other side; the idle-power cost on the AMD iGPU is small.
  debug = {
    vfr = false,
  },

  xwayland = {
    force_zero_scaling = false,
  },

  -- Hyprland 0.55 removed `dwindle.pseudotile` (it was a no-op key); the
  -- `pseudo` dispatcher is what actually toggles pseudotiling per window.
  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
    new_on_top = true,
    mfact = 0.5,
  },

  -- Group borders (active/inactive/locked variants) come from DMS's
  -- matugen-generated dms/colors.conf, sourced at the bottom of
  -- hyprland.lua. Setting them here would override the dynamic palette.

  binds = {
    workspace_back_and_forth = true,
    -- allow_workspace_cycles = true,
    -- pass_mouse_when_bound = false,
  },

  -- Tuning for the workspace swipe gesture (CTRL + 3-finger, bound below).
  -- In 0.55 the enable toggle and finger count moved out of this block into
  -- the new `hl.gesture` API; only the behavioral knobs live here. `use_r`
  -- makes the swipe use relative (`r±1`) workspace targeting so it matches
  -- the keyboard/scroll-wheel bindings (infinite, creates as you go).
  gestures = {
    workspace_swipe_distance = 300,
    workspace_swipe_create_new = true,
    workspace_swipe_forever = true,
    workspace_swipe_use_r = true,
    workspace_swipe_cancel_ratio = 0.5,
    workspace_swipe_min_speed_to_force = 30,
  },
})

-- Touchpad gestures.
--   3-finger horizontal             → pan the scrolling-layout tape (columns)
--   CTRL + 3-finger horizontal      → switch workspaces
-- `scroll_move` directly drives the scrolling layout's viewport offset, with
-- momentum and snap-to-column-grid on release (tuned by `gestures:scrolling:
-- move_snap_to_grid` / `move_snap_cursor`, both default true). Holding CTRL
-- escalates to the older workspace-swipe gesture.
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "scroll_move",
})
hl.gesture({
  fingers = 3,
  direction = "horizontal",
  mods = "CTRL",
  action = "workspace",
})
