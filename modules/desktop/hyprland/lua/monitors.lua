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
