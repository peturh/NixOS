{
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  # Wallpapers live in modules/themes/wallpapers as plain .png; Qt6's built-in
  # image decoders (used by Quickshell/DMS) handle PNG natively, so we just
  # expose the directory as-is into ~/Pictures/Wallpapers.
  wallpapersDir = ../../../../themes/wallpapers;

  # Boot-time fallback wallpapers for DMS. Picked from the files synced into
  # ~/Pictures/Wallpapers below. We seed light/dark separately so the first-
  # launch session.json doesn't have wallpaperPathLight pointing at the dark
  # PNG — a mismatch that, combined with isLightMode=true and themeModeAuto,
  # made the cold-start visibly flicker through dark on its way to light
  # (matugen on dark image → light-mode auto-switch → matugen on light
  # image). `wallpaperPath` matches the default isLightMode=true seed below.
  defaultLightWallpaperPath = "/home/${username}/Pictures/Wallpapers/thinkpad-light.png";
  defaultDarkWallpaperPath = "/home/${username}/Pictures/Wallpapers/thinkpad-dark.png";

  # Pull cursor theme + size out of DMS's settings.json so the DMS UI
  # (Settings → Personalization → Cursor) stays the single source of truth.
  # When the user picks a new cursor there, settings.json is updated through
  # the mkOutOfStoreSymlink below; the next `nixos-rebuild` re-reads this
  # file and propagates the choice to home.pointerCursor.
  #
  # Cursor wiring is kept local to this DMS module on purpose: any sibling
  # module that forces gtk/qt/icon themes or dark-mode keys would fight DMS's
  # matugen + portal-driven theming on every rebuild (see
  # modules/desktop/hyprland/default.nix). Keeping it here preserves the
  # "DMS owns the look" invariant.
  dmsSettings = builtins.fromJSON (builtins.readFile ./settings.json);
  cursorTheme = dmsSettings.cursorSettings.theme or "Bibata-Original-Ice";
  cursorSize = dmsSettings.cursorSettings.size or 24;
  iconTheme = dmsSettings.iconTheme or "Adwaita";

  # Wrap modules/desktop/hyprland/scripts/tlp-ctl.sh as a `tlp-ctl` binary on
  # PATH so the SUPER+F11 cycle keybind (via scripts/tlp-cycle.sh) can call
  # it without knowing the script's nix-store path. The script itself shells
  # out to `pkexec tlp ...`; the polkit rule in modules/programs/misc/tlp/default.nix
  # grants the `power` group pkexec without a password prompt.
  tlpCtl = pkgs.writeShellApplication {
    name = "tlp-ctl";
    runtimeInputs = with pkgs; [tlp jq coreutils];
    text = builtins.readFile ../../scripts/tlp-ctl.sh;
  };

  # Wrap modules/desktop/hyprland/scripts/wwan-ctl.sh as a `wwan-ctl` binary
  # on PATH for the DMS wwanCtl plugin (plugins/wwanCtl/WwanWidget.qml).
  # Backed by `nmcli connection up/down "Telenor WWAN"` which NM resolves
  # through ModemManager — works without polkit because the user is in the
  # `networkmanager` group.
  wwanCtl = pkgs.writeShellApplication {
    name = "wwan-ctl";
    runtimeInputs = with pkgs; [modemmanager networkmanager jq gnugrep gnused gawk coreutils];
    text = builtins.readFile ../../scripts/wwan-ctl.sh;
  };

  # Packages from the user's standalone DMS plugin flake at
  # github.com/peturh/tlp-power-profile. `tlp-power-profile-helper` is the
  # wrapped helper binary (TLP only exposes ac/bat; this script layers a
  # "performance" overlay by forcing cpufreq governor / EPP / turbo /
  # platform_profile). The plugin invokes it as
  # `pkexec tlp-power-profile-helper performance` — pkexec on NixOS has
  # /run/current-system/sw/bin on its PATH, so installing via
  # environment.systemPackages below makes the name resolve.
  # `tlp-power-profile-plugin` is a derivation containing plugin.json,
  # qmldir, and the QML files at share/DankMaterialShell/plugins/tlp-power-profile.
  tlpPowerProfile = inputs.tlp-power-profile.packages.${pkgs.stdenv.hostPlatform.system};
in {
  # Install tlp-ctl system-wide. Same reasoning as the previous Noctalia
  # module: keybinds and any session-spawned scripts need it on
  # /run/current-system/sw/bin, not just home-manager's per-user profile.
  environment.systemPackages = [
    tlpCtl
    wwanCtl
    tlpPowerProfile.tlp-power-profile-helper
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

      # System-wide pointer cursor. DMS already exports XCURSOR_THEME /
      # HYPRCURSOR_THEME into the Hyprland session via its matugen Hyprland
      # template (see settings.json: matugenTemplateHyprland), so the live
      # cursor in the compositor follows the DMS UI without a rebuild.
      #
      # What that path does NOT do is:
      #   • create ~/.icons/default/index.theme (GTK/Qt/X11 fallback path),
      #   • set XCURSOR_SIZE (without it Hyprland often falls back to its
      #     built-in yellow pointer when hyprcursor can't find the theme),
      #   • register the cursor with gtk3/gtk4/dconf, or
      #   • make sure the chosen cursor package is actually realised into
      #     the user profile.
      #
      # home.pointerCursor handles all of that in one place. The name/size
      # are read from settings.json above so DMS remains authoritative; the
      # package is pinned to bibata-cursors because every variant DMS ships
      # in its cursor picker dropdown by default lives in that single
      # derivation (Bibata-{Modern,Original}-{Classic,Ice,Amber}). If the
      # user later picks a non-Bibata theme via the DMS UI they'll need to
      # swap the package here too.
      home.pointerCursor = {
        package = pkgs.bibata-cursors;
        name = cursorTheme;
        size = cursorSize;
        gtk.enable = true;
        x11.enable = true;
        hyprcursor.enable = true;
      };

      # DMS's in-shell icon theme picker writes ~/.config/gtk-{3,4}.0/settings.ini
      # and pokes xdg-desktop-portal, but does NOT directly set the GNOME
      # gsettings key org.gnome.desktop.interface.icon-theme. GTK4 /
      # libadwaita apps (nautilus, etc.) read from gsettings, so the
      # portal-only sync silently fails and folders fall back to compiled-in
      # Adwaita. Propagate DMS's choice into dconf ourselves, mirroring how
      # home.pointerCursor above propagates cursorSettings.
      dconf.settings."org/gnome/desktop/interface" = {
        icon-theme = iconTheme;
        # Make the xdg-desktop-portal report `prefer-light` to DMS (which
        # has syncModeWithPortal=true in settings.json) and to GTK apps.
        # Without this the portal returns `default`, which DMS's QML
        # treats as dark — visible as a dark flash on every dms.service
        # restart (e.g. nixos-rebuild) before session.json finishes
        # loading. The seedDmsSession activation below also defaults
        # isLightMode to true for fresh installs.
        color-scheme = "prefer-light";
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

      # wwan-ctl bar widget. Out-of-store symlink pattern so QML edits are
      # picked up by a plugin reload (DMS Settings → Plugins) without a
      # nixos-rebuild. Shells out to the `wwan-ctl` binary installed above.
      xdg.configFile."DankMaterialShell/plugins/wwanCtl".source =
        config.lib.file.mkOutOfStoreSymlink
        "/home/${username}/NixOS/modules/desktop/hyprland/programs/dms/plugins/wwanCtl";

      # tlpPowerProfile bar widget — symlinked straight out of the
      # tlp-power-profile-plugin derivation. The package installs its
      # QML/plugin.json/qmldir under share/DankMaterialShell/plugins/tlp-power-profile,
      # so pointing xdg.configFile at that subdir gives DMS exactly the
      # plugin tree it expects without any of the repo's extra files
      # (helper/, README.md, flake.nix, …) bleeding into the plugin dir.
      # Bump the source revision with `nix flake update tlp-power-profile`.
      #
      # The plugin's "Performance" profile shells out to
      # `pkexec tlp-power-profile-helper performance`; that binary is
      # installed system-wide above and lands in /run/current-system/sw/bin,
      # which pkexec searches by default. Polkit grants the `power` group
      # password-less pkexec via modules/programs/misc/tlp/default.nix, and
      # ${username} is already in `power` via hosts/common.nix.
      xdg.configFile."DankMaterialShell/plugins/tlp-power-profile".source = "${tlpPowerProfile.tlp-power-profile-plugin}/share/DankMaterialShell/plugins/tlp-power-profile";

      # DMS Agent — AI desktop assistant by francis. Pinned via the
      # `dms-agent` flake input (flake = false) and re-exposed as
      # `pkgs.dms-agent` through the additions overlay; the derivation in
      # pkgs/dms-agent.nix copies the upstream tree into
      # share/DankMaterialShell/plugins/dmsAgent. Bumping the pin means
      # editing the rev in flake.nix and running `nix flake update dms-agent`.
      xdg.configFile."DankMaterialShell/plugins/dmsAgent".source = "${pkgs.dms-agent}/share/DankMaterialShell/plugins/dmsAgent";

      # Screen capture toolbar (third-party plugin from
      # github.com/JDKamalakar/DMS-ScreenCapture_Toolbar). Daemon-type
      # plugin: provides a `dms ipc call screenCaptureToolbar toggle`
      # entrypoint for a pill toolbar with screenshot + screen-recording
      # controls. Runtime deps (grim, slurp, satty, wl-clipboard,
      # gpu-screen-recorder, jq) are already installed via the Hyprland
      # module and the per-host gpu-screen-recorder import.
      xdg.configFile."DankMaterialShell/plugins/screenCaptureToolbar".source =
        config.lib.file.mkOutOfStoreSymlink
        "/home/${username}/NixOS/modules/desktop/hyprland/programs/dms/plugins/screenCaptureToolbar";

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
        light="${defaultLightWallpaperPath}"
        dark="${defaultDarkWallpaperPath}"
        ${pkgs.coreutils}/bin/mkdir -p "$stateDir"

        # Refuse to clobber a home-manager-owned symlink (i.e. if a future
        # change accidentally re-enables programs.dank-material-shell.session
        # — that path produces a Nix-store-target symlink we can't write to).
        if [ -L "$stateFile" ]; then
          echo "seedDmsSession: $stateFile is a symlink; skipping seed." >&2
        elif [ -s "$stateFile" ] && ${pkgs.jq}/bin/jq -e . "$stateFile" >/dev/null 2>&1; then
          tmp="$stateFile.tmp"
          ${pkgs.jq}/bin/jq \
            --arg light "$light" \
            --arg dark "$dark" \
            '.wallpaperPath = (.wallpaperPath // $light)
             | .wallpaperPathLight = (.wallpaperPathLight // $light)
             | .wallpaperPathDark = (.wallpaperPathDark // $dark)
             | .weatherLocation = (.weatherLocation // "Malmö, Sweden")
             | .weatherCoordinates = (.weatherCoordinates // "55.6050,13.0038")
             | .nightModeUseIPLocation = (.nightModeUseIPLocation // true)
             | .isLightMode = (.isLightMode // true)' \
            "$stateFile" > "$tmp" \
            && mv "$tmp" "$stateFile"
        else
          ${pkgs.jq}/bin/jq -n --arg light "$light" --arg dark "$dark" '{
            "wallpaperPath": $light,
            "wallpaperPathLight": $light,
            "wallpaperPathDark": $dark,
            "weatherLocation": "Malmö, Sweden",
            "weatherCoordinates": "55.6050,13.0038",
            "nightModeUseIPLocation": true,
            "isLightMode": true
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
      # `start-limit-hit` after a startup race, and so it doesn't subscribe
      # to Hyprland IPC before Hyprland has finished publishing its
      # monitor/workspace state.
      #
      # The unit is `WantedBy=graphical-session.target`, and on a mid-
      # session rebuild home-manager may kick it off *before* Hyprland's
      # autostart.lua has propagated WAYLAND_DISPLAY into the systemd
      # user environment via `dbus-update-activation-environment
      # --systemd --all`. With the default `Restart=on-failure` +
      # 5-tries-in-10s limit, that race left dms.service permanently
      # failed on the active session.
      #
      # Separately, even when WAYLAND_DISPLAY *is* set, Hyprland may not
      # yet have finished publishing monitors/workspaces over its IPC
      # socket at the moment DMS subscribes. DMS bakes whatever half-
      # built state it sees into the bar widgets — in particular the
      # workspace switcher caches per-monitor "active workspace" state
      # and ends up marking multiple pills active until the next
      # `systemctl --user restart dms.service`. The second ExecStartPre
      # waits for `hyprctl monitors -j` to return a non-empty list so
      # DMS starts against a fully-populated compositor.
      #
      # Three changes:
      #   1. First ExecStartPre waits up to ~12s for WAYLAND_DISPLAY to
      #      be set and the corresponding socket to exist.
      #   2. Second ExecStartPre waits up to ~15s for Hyprland's IPC
      #      socket to exist and `hyprctl monitors -j` to return at
      #      least one monitor.
      #   3. StartLimitIntervalSec=0 disables the burst limit so systemd
      #      will keep retrying with RestartSec backoff until Hyprland
      #      finishes propagating the env.
      systemd.user.services.dms = let
        hyprctl = "${pkgs.hyprland}/bin/hyprctl";
        jq = "${pkgs.jq}/bin/jq";
        bash = "${pkgs.bash}/bin/bash";
        waitWayland = "${bash} -c 'for _ in $(seq 1 60); do [ -n \"$WAYLAND_DISPLAY\" ] && [ -S \"$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY\" ] && exit 0; sleep 0.2; done; echo \"dms: WAYLAND_DISPLAY never appeared in systemd user env\" >&2; exit 1'";
        waitHyprlandIpc = "${bash} -c 'for _ in $(seq 1 60); do if [ -n \"$HYPRLAND_INSTANCE_SIGNATURE\" ] && [ -S \"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock\" ] && ${hyprctl} monitors -j 2>/dev/null | ${jq} -e \"length > 0\" >/dev/null 2>&1; then exit 0; fi; sleep 0.25; done; echo \"dms: Hyprland IPC never published a monitor list\" >&2; exit 1'";
      in {
        Unit.StartLimitIntervalSec = 0;
        Service = {
          RestartSec = 2;
          ExecStartPre = [waitWayland waitHyprlandIpc];
        };
      };
    })
  ];
}
