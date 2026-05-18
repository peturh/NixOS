{
  inputs,
  pkgs,
  terminal,
  ...
}: let
  # Quickshell/Caelestia uses Qt6's built-in image decoders, which do not
  # support JPEG XL out of the box. Our existing wallpapers in
  # modules/themes/wallpapers are .jxl, so we decode them to .png at build
  # time and expose the decoded set as the wallpaper directory.
  wallpapersDecoded = pkgs.runCommand "caelestia-wallpapers" {
    nativeBuildInputs = [pkgs.libjxl];
  } ''
    mkdir -p $out
    for f in ${../../../../themes/wallpapers}/*.jxl; do
      name=$(basename "$f" .jxl)
      djxl "$f" "$out/$name.png"
    done
  '';

  # Hyprland 0.55+ Lua-config mode rejects the legacy `workspace N` dispatch
  # IPC syntax: caelestia's bar sends classic strings, Hyprland tries to eval
  # them as Lua and crashes with `')' expected near '2'`. Upstream Hyprland
  # declared this expected behaviour — tools must update. Patch caelestia's
  # workspace click handler to use the new Lua dispatcher syntax instead.
  # https://github.com/hyprwm/Hyprland/discussions/14255
  caelestiaShellPatched =
    (inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli).overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace modules/bar/components/workspaces/Workspaces.qml \
            --replace-fail 'Hypr.dispatch(`workspace ''${ws}`);' \
                           'Hypr.dispatch(`hl.dsp.focus({ workspace = ''${ws} })`);' \
            --replace-fail 'Hypr.dispatch("togglespecialworkspace special");' \
                           "Hypr.dispatch('hl.dsp.workspace.toggle_special(\"special\")');"
        '';
    });
in {
  home-manager.sharedModules = [
    inputs.caelestia-shell.homeManagerModules.default
    ({...}: {
      home.file."Pictures/Wallpapers" = {
        source = wallpapersDecoded;
        recursive = true;
      };

      programs.caelestia = {
        enable = true;
        package = caelestiaShellPatched;

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
            # Hide the caelestia "logo" entry at the top of the bar (the
            # crescent / Pac-Man-looking glyph). NixOS's /etc/os-release sets
            # LOGO=nix-snowflake, but the icon doesn't always resolve at bar
            # render time and caelestia falls back to its bundled logo.svg.
            # We don't need either, so drop the entry entirely. Order matches
            # the upstream default; only the `logo` entry has enabled=false.
            entries = [
              { id = "logo"; enabled = false; }
              { id = "workspaces"; enabled = true; }
              { id = "spacer"; enabled = true; }
              { id = "activeWindow"; enabled = true; }
              { id = "spacer"; enabled = true; }
              { id = "tray"; enabled = true; }
              { id = "clock"; enabled = true; }
              { id = "statusIcons"; enabled = true; }
              { id = "power"; enabled = true; }
            ];
            workspaces = {
              shown = 10;
              perMonitorWorkspaces = true;
              showWindows = true;
              # Per-app icons shown next to running windows in the workspace bar.
              # The regex matches the Hyprland window class (case-insensitive in
              # practice); icon names come from Material Symbols (Rounded):
              # https://fonts.google.com/icons
              windowIcons = [
                # Browsers
                { regex = "(firefox|google-chrome|microsoft-edge|helium)"; icon = "public"; }

                # Terminals
                { regex = "(kitty|alacritty|wezterm|foot|ghostty)"; icon = "terminal"; }

                # Editors / IDEs
                { regex = "(code|vscode)"; icon = "code"; }
                { regex = "cursor"; icon = "code"; }
                { regex = "obsidian"; icon = "edit_note"; }

                # Chat / messaging
                { regex = "discord"; icon = "chat"; }
                { regex = "slack"; icon = "chat"; }
                { regex = "signal"; icon = "chat"; }
                { regex = "teams-for-linux|microsoft teams"; icon = "groups"; }

                # Media — audio
                { regex = "spotify"; icon = "music_note"; }
                { regex = "audacity"; icon = "graphic_eq"; }

                # Media — video
                { regex = "(mpv|vlc)"; icon = "play_circle"; }
                { regex = "iptvnator"; icon = "live_tv"; }

                # Media — graphics
                { regex = "gimp"; icon = "brush"; }

                # File management
                { regex = "(org\\.gnome\\.nautilus|nautilus)"; icon = "folder"; }
                { regex = "(org\\.gnome\\.fileroller|file-roller)"; icon = "folder_zip"; }

                # System / hardware tools
                { regex = "gparted"; icon = "hard_drive"; }
                { regex = "usbimager"; icon = "usb"; }
                { regex = "lact"; icon = "developer_board"; }
                { regex = "virt-manager"; icon = "monitor"; }
                { regex = "gnome-firmware|org\\.gnome\\.firmware"; icon = "system_update"; }
                { regex = "8bitdo-updater"; icon = "sports_esports"; }

                # Cloud sync / remote
                { regex = "celeste"; icon = "sync"; }
                { regex = "(remmina|org\\.remmina\\.remmina)"; icon = "screen_share"; }

                # Networking
                { regex = "transmission(-gtk|-qt)?"; icon = "download"; }

                # Gaming
                { regex = "steam(_app_(default|[0-9]+))?"; icon = "sports_esports"; }
              ];
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
            # Caelestia defaults to Fahrenheit; force Celsius for both the
            # weather widget and the performance-tab CPU/GPU temps.
            useFahrenheit = false;
            useFahrenheitPerformance = false;
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
