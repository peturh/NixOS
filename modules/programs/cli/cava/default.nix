{...}: {
  home-manager.sharedModules = [
    (_: {
      # Caelestia (and Hyprland-side widgets) rewrite ~/.config/cava/config at
      # runtime, replacing the symlink HM created. On the next rebuild HM
      # would try to back the live file up to `config.backup`, collide with
      # the stale backup from the previous cycle, and abort activation.
      # `force = true` makes HM overwrite the path without backing it up.
      xdg.configFile."cava/config".force = true;
      programs.cava = {
        enable = true;
        settings = {
          general = {
            framerate = 60;
            sensitivity = 100; # Default
            autosens = 1;
          };
          # No [color] block: cava falls back to the terminal's
          # foreground/background, which is itself DMS-matugen-driven via
          # the kitty + ghostty templates. Same approach as btop's
          # theme_background=false — let the terminal palette drive the
          # visual so it tracks wallpaper / dark-light toggles for free.
        };
      };
    })
  ];
}
