{
  pkgs,
  ...
}: let
  # Choose the desired variant: "main", "moon", or "dawn"
  variant = "main";

  # Compute base names for themes
  baseName =
    if variant == "main"
    then "rose-pine"
    else "rose-pine-${variant}";
in {
  home-manager.sharedModules = [
    ({config, ...}: {
      # Include Rose Pine GTK and icon themes
      home.packages = [pkgs.rose-pine-gtk-theme pkgs.rose-pine-icon-theme];

      # GTK configuration
      gtk = {
        enable = true;
        theme = {
          name = baseName;
          package = pkgs.rose-pine-gtk-theme;
        };
        iconTheme = {
          # package = pkgs.adwaita-icon-theme;
          # name = "Adwaita";
          package = pkgs.papirus-icon-theme;
          name = "Papirus-Dark";
        };
        gtk3.extraConfig = {
          "gtk-application-prefer-dark-theme" = "1";
        };
        gtk4 = {
          theme = config.gtk.theme;
          extraConfig = {
            "gtk-application-prefer-dark-theme" = "1";
          };
        };
      };

      # Qt configuration
      qt = {
        enable = true;
        platformTheme.name = "gtk";
        style.name = "adwaita-dark";
      };

      # Wallpaper is owned by DMS; see modules/desktop/hyprland/programs/dms.

      # GNOME dark mode
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };

      # Pointer cursor
      home.pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      # GTK4 assets for consistency
      xdg.configFile = {
        "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
        "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
        "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
      };
    })
  ];
}
