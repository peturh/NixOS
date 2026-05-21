-- general / decoration / animations + bezier curves.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 9,
    border_size = 2,
    col = {
      active_border = {
        colors = { "rgba(ca9ee6ff)", "rgba(f2d5cfff)" },
        angle = 45,
      },
      inactive_border = {
        colors = { "rgba(b4befecc)", "rgba(6c7086cc)" },
        angle = 45,
      },
    },
    resize_on_border = true,
    layout = "scrolling", -- dwindle | master | scrolling (PaperWM-style, built-in since 0.55)
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

-- Animation leaves.
hl.animation({ leaf = "windows",          enabled = true, speed = 3,   bezier = "md3_decel",   style = "popin 60%" })
hl.animation({ leaf = "border",           enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 2.5, bezier = "md3_decel" })
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.5, bezier = "easeOutExpo", style = "slide" })
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "fluent_decel", style = "slidefade 15%" })
-- hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "md3_decel", style = "slidefadevert 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",   style = "slidevert" })
