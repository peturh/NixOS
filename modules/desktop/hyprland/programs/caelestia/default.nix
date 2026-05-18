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
