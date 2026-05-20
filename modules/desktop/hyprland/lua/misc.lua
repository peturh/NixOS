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

  group = {
    col = {
      border_active = {
        colors = { "rgba(ca9ee6ff)", "rgba(f2d5cfff)" },
        angle = 45,
      },
      border_inactive = {
        colors = { "rgba(b4befecc)", "rgba(6c7086cc)" },
        angle = 45,
      },
      border_locked_active = {
        colors = { "rgba(ca9ee6ff)", "rgba(f2d5cfff)" },
        angle = 45,
      },
      border_locked_inactive = {
        colors = { "rgba(b4befecc)", "rgba(6c7086cc)" },
        angle = 45,
      },
    },
  },

  binds = {
    workspace_back_and_forth = true,
    -- allow_workspace_cycles = true,
    -- pass_mouse_when_bound = false,
  },
})
