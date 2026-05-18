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
          color = {
            gradient = 1;

            # Mocha
            gradient_color_1 = "'#94e2d5'";
            gradient_color_2 = "'#89dceb'";
            gradient_color_3 = "'#74c7ec'";
            gradient_color_4 = "'#89b4fa'";
            gradient_color_5 = "'#cba6f7'";
            gradient_color_6 = "'#f5c2e7'";
            gradient_color_7 = "'#eba0ac'";
            gradient_color_8 = "'#f38ba8'";
          };
        };
      };
    })
  ];
}
