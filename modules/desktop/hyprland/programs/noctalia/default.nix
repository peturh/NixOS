{
  inputs,
  pkgs,
  username,
  ...
}: let
  # Quickshell-based shells (Caelestia, Noctalia) use Qt6's built-in image
  # decoders, which do not support JPEG XL out of the box. Our existing
  # wallpapers in modules/themes/wallpapers are .jxl, so we decode them to
  # .png at build time and expose the decoded set as the wallpaper dir.
  wallpapersDecoded = pkgs.runCommand "noctalia-wallpapers" {
    nativeBuildInputs = [pkgs.libjxl];
  } ''
    mkdir -p $out
    for f in ${../../../../themes/wallpapers}/*.jxl; do
      name=$(basename "$f" .jxl)
      djxl "$f" "$out/$name.png"
    done
  '';

  # Wrap modules/desktop/hyprland/scripts/tlp-ctl.sh as a `tlp-ctl` binary on
  # PATH so the Noctalia plugin (and any keybind) can call it without knowing
  # the script's nix-store path. The script itself shells out to `pkexec tlp
  # ...`; the polkit rule in modules/programs/misc/tlp/default.nix grants the
  # `power` group pkexec without a password prompt.
  tlpCtl = pkgs.writeShellApplication {
    name = "tlp-ctl";
    runtimeInputs = with pkgs; [tlp jq coreutils];
    text = builtins.readFile ../../scripts/tlp-ctl.sh;
  };

  # The Noctalia plugin lives at ~/.config/noctalia/plugins/tlp-ctl/. The
  # `id` field of manifest.json must match the directory name; the bar
  # widget is then addressed as "plugin:tlp-ctl" in settings.bar.widgets.
  tlpPluginDir = ./plugin-tlp-ctl;
in {
  home-manager.sharedModules = [
    inputs.noctalia.homeModules.default
    ({...}: {
      home.packages = [tlpCtl];

      home.file."Pictures/Wallpapers" = {
        source = wallpapersDecoded;
        recursive = true;
      };

      # Ship the local tlp-ctl plugin into Noctalia's plugin directory. We
      # bypass the git-sparse-checkout install path entirely; PluginRegistry
      # scans this folder at startup and discovers the plugin by its
      # manifest.json. Files are read-only symlinks into the Nix store
      # (Noctalia's hot-reload watcher follows symlinks).
      xdg.configFile."noctalia/plugins/tlp-ctl/manifest.json".source =
        tlpPluginDir + "/manifest.json";
      xdg.configFile."noctalia/plugins/tlp-ctl/BarWidget.qml".source =
        tlpPluginDir + "/BarWidget.qml";

      programs.noctalia-shell = {
        enable = true;

        # Systemd startup is deprecated upstream; Noctalia is spawned from
        # Hyprland's autostart.lua instead. We still pin the package so that
        # `pkill -x noctalia-shell` + respawn picks up the same binary.
        systemd.enable = false;

        plugins = {
          version = 2;
          # Keep the official source registered so the GUI plugin manager
          # still works for browsing/installing additional plugins.
          sources = [
            {
              enabled = true;
              name = "Noctalia Plugins";
              url = "https://github.com/noctalia-dev/noctalia-plugins";
            }
          ];
          # Mark our locally-shipped plugin as enabled. The directory name
          # under ~/.config/noctalia/plugins/ is the plain id "tlp-ctl"
          # (treated as "from main source" for state-tracking purposes —
          # this is fine because we never let Noctalia try to update it).
          states = {
            tlp-ctl = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
          };
        };

        settings = {
          bar = {
            position = "top";
            density = "compact";
            showCapsule = true;
            widgets = {
              left = [
                {id = "ControlCenter";}
                {id = "Workspace"; showApplications = true; hideUnoccupied = false;}
                {id = "ActiveWindow";}
              ];
              center = [
                {
                  id = "Clock";
                  formatHorizontal = "HH:mm";
                  useMonospacedFont = true;
                }
              ];
              right = [
                {id = "SystemMonitor";}
                {id = "MediaMini";}
                {id = "Tray";}
                {id = "Network";}
                {id = "Bluetooth";}
                {id = "Volume";}
                {id = "Brightness";}
                {id = "Battery";}
                {id = "plugin:tlp-ctl";}
                {id = "NotificationHistory";}
              ];
            };
          };

          general = {
            avatarImage = "/home/${username}/.face";
            radiusRatio = 1;
            animationSpeed = 1;
            lockOnSuspend = true;
          };

          ui = {
            tooltipsEnabled = true;
            panelBackgroundOpacity = 0.93;
          };

          audio = {
            volumeStep = 2;
          };

          brightness = {
            brightnessStep = 2;
          };

          location = {
            name = "Stockholm, Sweden";
            weatherEnabled = true;
            useFahrenheit = false;
            use12hourFormat = false;
            autoLocate = true;
          };

          notifications = {
            enabled = true;
            location = "top_right";
          };

          osd = {
            enabled = true;
            location = "top_right";
          };

          # Noctalia is still Quickshell/Qt6; same JPEG-XL caveat as
          # Caelestia. The wallpaper directory points at the decoded PNGs.
          wallpaper = {
            enabled = true;
            directory = "/home/${username}/Pictures/Wallpapers";
            setWallpaperOnAllMonitors = true;
            fillMode = "crop";
          };

          colorSchemes = {
            predefinedScheme = "Noctalia (default)";
            darkMode = true;
            useWallpaperColors = false;
          };

          systemMonitor = {
            cpuWarningThreshold = 80;
            cpuCriticalThreshold = 90;
            tempWarningThreshold = 80;
            tempCriticalThreshold = 90;
            memWarningThreshold = 80;
            memCriticalThreshold = 90;
          };

          # The lock screen owns suspend/lock when hypridle fires; keep
          # password-with-fprintd off until we wire up fingerprint auth.
          sessionMenu = {
            enableCountdown = true;
            countdownDuration = 10000;
          };
        };
      };
    })
  ];
}
