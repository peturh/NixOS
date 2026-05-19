{
  inputs,
  pkgs,
  username,
  wallpaper,
  ...
}: let
  # Wallpapers live in modules/themes/wallpapers as plain .png; Qt6's built-in
  # image decoders (used by Quickshell/Noctalia) handle PNG natively, so we
  # just expose the directory as-is.
  wallpapersDir = ../../../../themes/wallpapers;

  # The path Noctalia will use as its boot-time fallback wallpaper. Matches the
  # filename selected by `commonSettings.wallpaper` in flake.nix.
  defaultWallpaperPath = "/home/${username}/Pictures/Wallpapers/${wallpaper}.png";

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
  # Install tlp-ctl system-wide rather than into the per-user home-manager
  # profile. Noctalia is spawned by Hyprland's autostart.lua before the
  # home-manager profile is necessarily on PATH for the graphical session,
  # so a home.packages install would leave Quickshell's Process unable to
  # find `tlp-ctl` (the bar widget would stay stuck on the bolt/"…"
  # placeholder and clicks would silently no-op). /run/current-system/sw/bin
  # is always on PATH, and is where `tlp` itself lives.
  environment.systemPackages = [tlpCtl];

  home-manager.sharedModules = [
    inputs.noctalia.homeModules.default
    ({lib, ...}: {
      home.file."Pictures/Wallpapers" = {
        source = wallpapersDir;
        recursive = true;
      };

      # Seed Noctalia's wallpaper cache so it boots straight to the wallpaper
      # picked in flake.nix instead of flashing its bundled "owl" logo
      # (Assets/Wallpaper/noctalia.png) while WallpaperService loads. Noctalia
      # reads `defaultWallpaper` from ~/.cache/noctalia/wallpapers.json before
      # any per-monitor entry is set; we patch only that one key with jq so a
      # user who later picks a different wallpaper through Noctalia's UI keeps
      # their selection across rebuilds.
      home.activation.seedNoctaliaWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
        cacheDir="$HOME/.cache/noctalia"
        cacheFile="$cacheDir/wallpapers.json"
        desired="${defaultWallpaperPath}"
        ${pkgs.coreutils}/bin/mkdir -p "$cacheDir"
        if [ -s "$cacheFile" ] && ${pkgs.jq}/bin/jq -e . "$cacheFile" >/dev/null 2>&1; then
          tmp="$cacheFile.tmp"
          ${pkgs.jq}/bin/jq --arg p "$desired" '.defaultWallpaper = $p' "$cacheFile" > "$tmp" \
            && mv "$tmp" "$cacheFile"
        else
          printf '{"defaultWallpaper":"%s","wallpapers":{},"usedRandomWallpapers":{}}\n' \
            "$desired" > "$cacheFile"
        fi
      '';

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
        # Hyprland's autostart.lua instead. The running process is the
        # NixOS-wrapped `.quickshell-wrapped` binary (the noctalia-shell C
        # wrapper exec's quickshell), so the CTRL+ESCAPE restart keybind
        # (scripts/restart-noctalia.sh) matches via `pkill -f quickshell`
        # rather than the noctalia-shell name.
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
            density = "default";
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

          wallpaper = {
            enabled = true;
            directory = "/home/${username}/Pictures/Wallpapers";
            setWallpaperOnAllMonitors = true;
            fillMode = "crop";
          };

          colorSchemes = {
            predefinedScheme = "Catppuccin Mocha";
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
