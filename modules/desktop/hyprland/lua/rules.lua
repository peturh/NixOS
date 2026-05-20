-- Window and layer rules. See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

----------------
-- Layer rules
----------------

-- DankMaterialShell (DMS) tags every layer-shell surface with the prefix
-- "dms:" (e.g. dms:bar, dms:control-center, dms:spotlight, dms:popout).
-- Disabling animations on every dms:* layer keeps panels feeling snappy
-- under Hyprland — DMS already animates its content internally.
-- See https://danklinux.com/docs/dankmaterialshell/layers for the full
-- namespace list.
hl.layer_rule({ match = { namespace = "^dms:.*$" }, no_anim = true })

-- Blur a curated subset of DMS modals/popouts. We deliberately *don't*
-- blur dms:bar (kills bar performance with our existing 6-pass blur from
-- looknfeel.lua) or dms:notification-popup (no aesthetic gain on a
-- transient toast).
hl.layer_rule({ match = { namespace = "^dms:(spotlight|clipboard|settings|control-center|color-picker|power-menu|app-launcher|process-list-modal|notification-center-popout|dash|notepad|polkit|modal|popout)$" }, blur = true })
hl.layer_rule({ match = { namespace = "^dms:(spotlight|clipboard|settings|control-center|color-picker|power-menu|app-launcher|process-list-modal|notification-center-popout|dash|notepad|polkit|modal|popout)$" }, ignore_alpha = 0.5 })

-----------------
-- Window rules
-----------------

hl.window_rule({ match = { title = "(.*)(Godot)(.*)$" }, tile = true })

-- Workspace placement examples (kept disabled, matching the legacy config):
-- hl.window_rule({ match = { class = "^(com\\.mitchellh\\.ghostty|kitty)$" }, workspace = "1" })
-- hl.window_rule({ match = { class = "^(code|VSCodium|code-url-handler|codium-url-handler)$" }, workspace = "2" })
-- hl.window_rule({ match = { class = "^(krita)$" }, workspace = "3" })
-- hl.window_rule({ match = { title = "(.*)(Godot)(.*)$" }, workspace = "3" })
-- hl.window_rule({ match = { title = "(GNU Image Manipulation Program)(.*)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(factorio)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(steam)$" }, workspace = "3" })
-- hl.window_rule({ match = { class = "^(firefox|floorp|zen)$" }, workspace = "5" })
-- hl.window_rule({ match = { class = "^(Spotify)$" }, workspace = "6" })
-- hl.window_rule({ match = { title = "(.*)(Spotify)(.*)$" }, workspace = "6" })

-- Opacity rules. Format: "active inactive" or "active" only.
-- Terminals are intentionally left fully opaque: the DMS-generated kitty /
-- ghostty palette already provides a deliberate background colour, and a
-- 0.80 window-rule opacity bled the wallpaper through it and made the
-- matugen light-mode colours look washed out. Restore the rule if you ever
-- want per-window transparency back.
-- hl.window_rule({ match = { class = "^(com\\.mitchellh\\.ghostty|kitty)$" }, opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(gcr-prompter)$" },                                     opacity = "0.90 0.90" }) -- keyring prompt
hl.window_rule({ match = { title = "^(Hyprland Polkit Agent)$" },                            opacity = "0.90 0.90" }) -- polkit prompt
hl.window_rule({ match = { class = "^(firefox)$" },                                          opacity = "1.00 1.00" })
hl.window_rule({ match = { class = "^(Brave-browser)$" },                                    opacity = "0.90 0.90" })
hl.window_rule({ match = { class = "^(Steam)$" },                                            opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(steam)$" },                                            opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(steamwebhelper)$" },                                   opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(Spotify)$" },                                          opacity = "0.80 0.80" })
hl.window_rule({ match = { title = "(.*)(Spotify)(.*)$" },                                   opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(VSCodium)$" },                                         opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(codium-url-handler)$" },                               opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(code)$" },                                             opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(code-url-handler)$" },                                 opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(terminalFileManager)$" },                              opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$" },                                  opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(org.kde.ark)$" },                                      opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(nwg-look)$" },                                         opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(qt5ct)$" },                                            opacity = "0.80 0.80" })
hl.window_rule({ match = { class = "^(qt6ct)$" },                                            opacity = "0.80 0.80" })

hl.window_rule({ match = { class = "^(com.github.rafostar.Clapper)$" },         opacity = "0.90 0.90" }) -- Clapper-Gtk
hl.window_rule({ match = { class = "^(com.github.tchx84.Flatseal)$" },          opacity = "0.80 0.80" }) -- Flatseal-Gtk
hl.window_rule({ match = { class = "^(hu.kramo.Cartridges)$" },                 opacity = "0.80 0.80" }) -- Cartridges-Gtk
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" },               opacity = "0.80 0.80" }) -- Obs-Qt
hl.window_rule({ match = { class = "^(gnome-boxes)$" },                         opacity = "0.80 0.80" }) -- Boxes-Gtk
hl.window_rule({ match = { class = "^(discord)$" },                             opacity = "0.90 0.90" }) -- Discord-Electron
hl.window_rule({ match = { class = "^(WebCord)$" },                             opacity = "0.90 0.90" }) -- WebCord-Electron
hl.window_rule({ match = { class = "^(app.drey.Warp)$" },                       opacity = "0.80 0.80" }) -- Warp-Gtk
hl.window_rule({ match = { class = "^(net.davidotek.pupgui2)$" },               opacity = "0.80 0.80" }) -- ProtonUp-Qt
hl.window_rule({ match = { class = "^(Signal)$" },                              opacity = "0.80 0.80" }) -- Signal-Gtk
hl.window_rule({ match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" },  opacity = "0.80 0.80" }) -- Upscaler-Gtk

hl.window_rule({ match = { class = "^(pavucontrol)$" },                                opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" },                 opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(blueman-manager)$" },                            opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(.blueman-manager-wrapped)$" },                   opacity = "0.80 0.70" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },  opacity = "0.80 0.70" })

-- Games: tag + content + fullscreen rules.
hl.window_rule({ match = { tag = "games" },     content = "game" })
hl.window_rule({ match = { content = "game" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app.*|steam_app_\\d+)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(gamescope)$" },                  tag = "+games" })
hl.window_rule({ match = { class = "(Waydroid)" },                     tag = "+games" })
hl.window_rule({ match = { class = "(osu!)" },                         tag = "+games" })

-- hl.window_rule({ match = { tag = "games" }, sync_fullscreen = true }) -- was "syncfullscreen on" in 0.52; rule was removed in 0.53
hl.window_rule({ match = { tag = "games" }, fullscreen = true })
-- hl.window_rule({ match = { tag = "games" }, border_size = 0 }) -- was "noborder on"
-- hl.window_rule({ match = { tag = "games" }, no_shadow = true })
-- hl.window_rule({ match = { tag = "games" }, no_blur = true })
-- hl.window_rule({ match = { tag = "games" }, no_anim = true })

-- Float rules.
hl.window_rule({ match = { class = "^(qt5ct)$" },                                      float = true })
hl.window_rule({ match = { class = "^(nwg-look)$" },                                   float = true })
hl.window_rule({ match = { class = "^(org.kde.ark)$" },                                float = true })
hl.window_rule({ match = { class = "^(Signal)$" },                                     float = true }) -- Signal-Gtk
hl.window_rule({ match = { class = "^(com.github.rafostar.Clapper)$" },                float = true }) -- Clapper-Gtk
hl.window_rule({ match = { class = "^(app.drey.Warp)$" },                              float = true }) -- Warp-Gtk
hl.window_rule({ match = { class = "^(net.davidotek.pupgui2)$" },                      float = true }) -- ProtonUp-Qt
hl.window_rule({ match = { class = "^(eog)$" },                                        float = true }) -- Imageviewer-Gtk
hl.window_rule({ match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" },         float = true }) -- Upscaler-Gtk
hl.window_rule({ match = { class = "^(pavucontrol)$" },                                float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" },                            float = true })
hl.window_rule({ match = { class = "^(.blueman-manager-wrapped)$" },                   float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },  float = true })
