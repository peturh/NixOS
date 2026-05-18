-- Window and layer rules. See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

----------------
-- Layer rules
----------------

hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0.7 })

-----------------
-- Window rules
-----------------

-- hl.window_rule({ match = { class = "^(Rofi)$" }, no_anim = true })

hl.window_rule({ match = { title = "(.*)(Godot)(.*)$" }, tile = true })

-- Workspace placement examples (kept disabled, matching the legacy config):
-- hl.window_rule({ match = { class = "^(kitty|Alacritty|org.wezfurlong.wezterm)$" }, workspace = "1" })
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
hl.window_rule({ match = { class = "^(kitty|alacritty|Alacritty|org.wezfurlong.wezterm)$" }, opacity = "0.80 0.80" })
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
hl.window_rule({ match = { class = "^(yad)$" },                                              opacity = "0.80 0.80" })

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
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },                       opacity = "0.80 0.70" })
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
hl.window_rule({ match = { class = "^(yad)$" },                                        float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" },                                float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" },                            float = true })
hl.window_rule({ match = { class = "^(.blueman-manager-wrapped)$" },                   float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },                       float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },  float = true })
