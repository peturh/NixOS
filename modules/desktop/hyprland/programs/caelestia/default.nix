{
  inputs,
  terminal,
  ...
}: {
  home-manager.sharedModules = [
    inputs.caelestia-shell.homeManagerModules.default
    ({...}: {
      # Make the flake's wallpaper collection available to caelestia's
      # wallpaper picker. Caelestia reads from ~/Pictures/Wallpapers by default
      # (see paths.wallpaperDir below).
      home.file."Pictures/Wallpapers" = {
        source = ../../../../themes/wallpapers;
        recursive = true;
      };

      programs.caelestia = {
        enable = true;

        systemd = {
          enable = true;
          # Bring caelestia up via Hyprland's HM-managed graphical session
          # target. autostart.lua already starts hyprland-session.target on
          # `hyprland.start`, which pulls this unit in.
          target = "graphical-session.target";
          environment = [
            "QT_QPA_PLATFORM=wayland"
            "QT_QPA_PLATFORMTHEME=qt6ct"
          ];
        };

        cli.enable = true;

        settings = {
          general = {
            apps = {
              terminal = [terminal];
              audio = ["pavucontrol"];
              playback = ["mpv"];
              explorer = ["nautilus"];
            };
            # hypridle owns idle timeouts; disable caelestia's built-in idle
            # to avoid double-lock / double-DPMS behaviour.
            idle = {
              lockBeforeSleep = false;
              inhibitWhenAudio = false;
              timeouts = [];
            };
          };

          bar = {
            persistent = true;
            showOnHover = true;
            workspaces = {
              shown = 10;
              perMonitorWorkspaces = true;
              showWindows = true;
            };
            status = {
              showBattery = true;
              showBluetooth = true;
              showNetwork = true;
              showWifi = true;
              showLockStatus = true;
            };
          };

          services = {
            useTwelveHourClock = false;
            audioIncrement = 0.02;
            brightnessIncrement = 0.02;
          };

          paths = {
            wallpaperDir = "~/Pictures/Wallpapers";
          };

          notifs = {
            defaultExpireTimeout = 5000;
            expire = true;
          };

          osd = {
            enabled = true;
            enableBrightness = true;
          };

          lock = {
            hideNotifs = false;
          };
        };
      };
    })
  ];
}
