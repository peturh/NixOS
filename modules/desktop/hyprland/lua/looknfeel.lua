-- general / decoration / animations + bezier curves.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 9,
    border_size = 2,
    -- Border colors come from DMS's matugen-generated dms/colors.conf
    -- (sourced at the bottom of hyprland.lua). Don't set col.* here or it
    -- will override the dynamic palette.
    resize_on_border = true,
    layout = "dwindle", -- dwindle | master | scrolling (PaperWM-style, built-in since 0.55)
    -- allow_tearing = true, -- Allow tearing for games (use immediate window rules for specific games or all titles)
  },

  decoration = {
    shadow = { enabled = false },
    rounding = 10,
    dim_special = 0.3,
    blur = {
      enabled = true,
      special = true,
      size = 6, -- 6
      passes = 1, -- 2
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
    },
  },

  animations = {
    enabled = true,
  },
})

-- Bezier curves.
hl.curve("linear",        { type = "bezier", points = { {0, 0},    {1, 1}     } })
hl.curve("md3_standard",  { type = "bezier", points = { {0.2, 0},  {0, 1}     } })
hl.curve("md3_decel",     { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("md3_accel",     { type = "bezier", points = { {0.3, 0},  {0.8, 0.15} } })
hl.curve("overshot",      { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1} } })
hl.curve("crazyshot",     { type = "bezier", points = { {0.1, 1.5}, {0.76, 0.92} } })
hl.curve("hyprnostretch", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("fluent_decel",  { type = "bezier", points = { {0.1, 1},  {0, 1}     } })
hl.curve("easeInOutCirc", { type = "bezier", points = { {0.85, 0}, {0.15, 1}  } })
hl.curve("easeOutCirc",   { type = "bezier", points = { {0, 0.55}, {0.45, 1}  } })
hl.curve("easeOutExpo",   { type = "bezier", points = { {0.16, 1}, {0.3, 1}   } })

-- Spring curves. NOTE: when a leaf uses a spring curve, `speed` is ignored —
-- the spring physics (mass/stiffness/dampening) determine timing.
hl.curve("spring_menu",      { type = "spring", mass = 1,   stiffness = 300, dampening = 25 })
hl.curve("spring_window",    { type = "spring", mass = 1,   stiffness = 170, dampening = 18 })
hl.curve("spring_open",      { type = "spring", mass = 1,   stiffness = 170, dampening = 18 })
hl.curve("spring_workspace", { type = "spring", mass = 1.2, stiffness = 170, dampening = 22 })
hl.curve("spring_special",   { type = "spring", mass = 1,   stiffness = 170, dampening = 18 })

-- Animation leaves.
-- Old bezier-based leaves kept as comments for quick revert:
-- hl.animation({ leaf = "windows",          enabled = true, speed = 3,   bezier = "md3_decel",   style = "popin 60%" })
-- hl.animation({ leaf = "fade",             enabled = true, speed = 2.5, bezier = "md3_decel" })
-- hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slide" })
-- hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",   style = "slidevert" })

-- NOTE: when referencing a spring curve in an animation, the field is
-- `spring = "..."` (not `bezier`). Bezier curves still use `bezier = "..."`.
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3,   spring = "spring_open",      style = "popin 60%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3,   spring = "spring_window",    style = "popin 60%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 3,   spring = "spring_window" })
hl.animation({ leaf = "border",           enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 2.5, spring = "spring_menu" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.5, spring = "spring_workspace", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   spring = "spring_special",   style = "slidevert" })
