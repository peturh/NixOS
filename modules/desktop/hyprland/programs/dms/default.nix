{
  inputs,
  lib,
  pkgs,
  username,
  wallpaper,
  ...
}: let
  # Wallpapers live in modules/themes/wallpapers as plain .png; Qt6's built-in
  # image decoders (used by Quickshell/DMS) handle PNG natively, so we just
  # expose the directory as-is into ~/Pictures/Wallpapers.
  wallpapersDir = ../../../../themes/wallpapers;

  # The path DMS will use as its boot-time fallback wallpaper. Matches the
  # filename selected by `commonSettings.wallpaper` in flake.nix.
  defaultWallpaperPath = "/home/${username}/Pictures/Wallpapers/${wallpaper}.png";

  # Wrap modules/desktop/hyprland/scripts/tlp-ctl.sh as a `tlp-ctl` binary on
  # PATH so a keybind can call it without knowing the script's nix-store
  # path. The script itself shells out to `pkexec tlp ...`; the polkit rule
  # in modules/programs/misc/tlp/default.nix grants the `power` group pkexec
  # without a password prompt.
  #
  # In the Noctalia setup this drove a custom QML bar widget. DMS uses
  # plugin.json/QML APIs that don't map 1:1, so we trade the bar widget for
  # a SUPER+F11 keybind (see lua/binds.lua) and a `tlp-ctl` CLI users can
  # invoke from anywhere. Nothing is lost functionally; just a click less
  # discoverable.
  tlpCtl = pkgs.writeShellApplication {
    name = "tlp-ctl";
    runtimeInputs = with pkgs; [tlp jq coreutils];
    text = builtins.readFile ../../scripts/tlp-ctl.sh;
  };
in {
  # Install tlp-ctl system-wide. Same reasoning as the previous Noctalia
  # module: keybinds and any session-spawned scripts need it on
  # /run/current-system/sw/bin, not just home-manager's per-user profile.
  environment.systemPackages = [
    tlpCtl
    pkgs.claude-code
  ];

  # Power profile management: the DMS NixOS module would otherwise enable
  # power-profiles-daemon by default, which conflicts with TLP. We use the
  # home-manager module instead (no PPD), but explicitly assert PPD off so
  # a future module change can't sneak it back in.
  services.power-profiles-daemon.enable = lib.mkForce false;

  home-manager.sharedModules = [
    inputs.dms.homeModules.dank-material-shell
    ({
      config,
      lib,
      ...
    }: {
      # Mount our wallpaper collection into ~/Pictures/Wallpapers so DMS's
      # built-in wallpaper picker (Settings → Personalization → Wallpaper)
      # can browse them. Files are read-only symlinks into the Nix store.
      home.file."Pictures/Wallpapers" = {
        source = wallpapersDir;
        recursive = true;
      };

      # Two-way settings sync. We want both:
      #   • DMS's own Settings UI (SUPER+,) can save changes immediately,
      #   • those changes live inside this Nix repo (git-tracked, survive
      #     rebuilds, replicate to other hosts).
      #
      # `programs.dank-material-shell.settings` would deploy settings.json
      # as a *read-only* Nix-store symlink, breaking the UI write path.
      # Instead we bypass that option entirely and have home-manager
      # symlink ~/.config/DankMaterialShell/settings.json straight at the
      # working copy at modules/desktop/hyprland/programs/dms/settings.json
      # via `mkOutOfStoreSymlink`. DMS writes through the symlink and
      # `git status` immediately picks the change up.
      #
      # The upstream module already gates its own xdg.configFile entry on
      # `cfg.settings != { }`, so leaving that option unset means our
      # entry wins without a conflict.
      xdg.configFile."DankMaterialShell/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink
        "/home/${username}/NixOS/modules/desktop/hyprland/programs/dms/settings.json";

      # Seed DMS's session.json so the shell boots straight to the
      # configured wallpaper, weather location, and theme mode instead of
      # the upstream defaults (empty background, "New York, NY" weather).
      # We deliberately *don't* use home-manager's `session` option here
      # because that would write a read-only symlink and prevent DMS from
      # mutating the file when the user picks a different wallpaper from
      # the in-shell picker. Instead, we patch only the keys we own,
      # leaving the rest for DMS / the UI to manage. jq's `// $x` keeps
      # any pre-existing override the user may have set through the GUI.
      home.activation.seedDmsSession = lib.hm.dag.entryAfter ["writeBoundary"] ''
        stateDir="$HOME/.local/state/DankMaterialShell"
        stateFile="$stateDir/session.json"
        desired="${defaultWallpaperPath}"
        ${pkgs.coreutils}/bin/mkdir -p "$stateDir"

        # Refuse to clobber a home-manager-owned symlink (i.e. if a future
        # change accidentally re-enables programs.dank-material-shell.session
        # — that path produces a Nix-store-target symlink we can't write to).
        if [ -L "$stateFile" ]; then
          echo "seedDmsSession: $stateFile is a symlink; skipping seed." >&2
        elif [ -s "$stateFile" ] && ${pkgs.jq}/bin/jq -e . "$stateFile" >/dev/null 2>&1; then
          tmp="$stateFile.tmp"
          ${pkgs.jq}/bin/jq \
            --arg wp "$desired" \
            '.wallpaperPath = (.wallpaperPath // $wp)
             | .wallpaperPathDark = (.wallpaperPathDark // $wp)
             | .wallpaperPathLight = (.wallpaperPathLight // $wp)
             | .weatherLocation = (.weatherLocation // "Malmö, Sweden")
             | .weatherCoordinates = (.weatherCoordinates // "55.6050,13.0038")
             | .nightModeUseIPLocation = (.nightModeUseIPLocation // true)
             | .isLightMode = (.isLightMode // false)' \
            "$stateFile" > "$tmp" \
            && mv "$tmp" "$stateFile"
        else
          ${pkgs.jq}/bin/jq -n --arg wp "$desired" '{
            "wallpaperPath": $wp,
            "wallpaperPathDark": $wp,
            "wallpaperPathLight": $wp,
            "weatherLocation": "Malmö, Sweden",
            "weatherCoordinates": "55.6050,13.0038",
            "nightModeUseIPLocation": true,
            "isLightMode": false
          }' > "$stateFile"
        fi
      '';

      programs.dank-material-shell = {
        enable = true;

        # Start DMS as a user systemd service rather than spawning it from
        # autostart.lua. The home-manager hyprland module already pulls
        # `hyprland-session.target` into the user session (see
        # modules/desktop/hyprland/default.nix's `systemd.enable = true`),
        # and DMS's `wayland.systemd.target` defaults to that target on
        # Hyprland — so this Just Works.
        systemd.enable = true;

        # Optional capability toggles. Defaults are `true` upstream; we
        # restate them so a future module rename or default flip is loud.
        enableSystemMonitoring = true; # cpuUsage / memUsage bar widgets via dgop
        enableVPN = true; # vpn bar widget via NetworkManager
        enableDynamicTheming = true; # wallpaper-derived palette via matugen
        enableAudioWavelength = true; # cava-backed audio visualizer
        enableCalendarEvents = true; # khal calendar events in the dash
        enableClipboardPaste = true; # wtype-backed clipboard paste-from-history

        # NB: `programs.dank-material-shell.settings` is intentionally
        # left unset — the file is wired up above via xdg.configFile +
        # mkOutOfStoreSymlink so the UI can write to it. The schema
        # reference (keys, widget IDs) lives in DankMaterialShell's
        # quickshell/Modules/DankBar/WidgetHost.qml (componentMap) and
        # quickshell/Common/SettingsData.qml (barConfigs default).
        #
        # Session state at ~/.local/state/DankMaterialShell/session.json
        # is similarly DMS-owned; `seedDmsSession` above writes initial
        # values on first install while preserving any later UI changes.
      };

      # Harden the upstream dms.service so it can't get stuck in
      # `start-limit-hit` after a startup race. The unit is `WantedBy=
      # graphical-session.target`, and on a mid-session rebuild
      # home-manager may kick it off *before* Hyprland's autostart.lua
      # has propagated WAYLAND_DISPLAY into the systemd user environment
      # via `dbus-update-activation-environment --systemd --all`. With
      # the default `Restart=on-failure` + 5-tries-in-10s limit, that
      # race left dms.service permanently failed on the active session.
      #
      # Two changes:
      #   1. ExecStartPre waits up to ~12s for WAYLAND_DISPLAY to be set
      #      and the corresponding socket to exist, so a too-early start
      #      attempt fails cleanly instead of deep inside Qt's platform
      #      init (which produces a coredump and noisy journal).
      #   2. StartLimitIntervalSec=0 disables the burst limit so systemd
      #      will keep retrying with RestartSec backoff until Hyprland
      #      finishes propagating the env.
      systemd.user.services.dms = {
        Unit.StartLimitIntervalSec = 0;
        Service = {
          RestartSec = 2;
          ExecStartPre = "${pkgs.bash}/bin/bash -c 'for _ in $(seq 1 60); do [ -n \"$WAYLAND_DISPLAY\" ] && [ -S \"$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY\" ] && exit 0; sleep 0.2; done; echo \"dms: WAYLAND_DISPLAY never appeared in systemd user env\" >&2; exit 1'";
        };
      };
    })
  ];
}
