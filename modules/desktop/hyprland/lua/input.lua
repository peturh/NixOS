-- Input configuration. Pulls kb_layout/kb_variant from the Nix-generated vars.lua.

local v = require("vars")

hl.config({
  input = {
    kb_layout = v.kbdLayout,
    kb_variant = v.kbdVariant,
    numlock_by_default = true,
    repeat_delay = 300, -- or 212
    repeat_rate = 30,

    follow_mouse = 1,

    touchpad = {
      natural_scroll = false,
    },

    tablet = {
      output = "current",
    },

    sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
    force_no_accel = true,
  },
})
