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

  # Upstream noctalia plugin: "ScreenShot & Record"
  # https://github.com/noctalia-dev/noctalia-plugins/tree/main/screen-shot-and-record
  # Pinned by commit so rebuilds are reproducible; bump `rev` (and `hash`,
  # leave empty and Nix will print the correct value on the next build) to
  # update. We pull only the one plugin's subdirectory via sparseCheckout
  # so a 100-plugin repo isn't dragged into the closure.
  screenShotPluginSrc = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-plugins";
    rev = "7f0b5568b2970ab4a263c0c7c5e7d03e9899dead";
    hash = "sha256-fLCgRH4+jwYFHlDeZk0bOs83WNWy1+v/L2bLwUT4FtU=";
    sparseCheckout = ["screen-shot-and-record"];
  };

  # Upstream noctalia plugin: "Claude Code Panel"
  # https://github.com/noctalia-dev/noctalia-plugins/tree/main/claude-code-panel
  # Same sparseCheckout pattern as screen-shot-and-record. Pinned at the most
  # recent commit touching the plugin folder; bump `rev` (clear `hash`, Nix
  # will print the correct value on next build) to update.
  claudeCodePanelPluginSrc = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-plugins";
    rev = "9530cc7be346c022135d61fd8e2cd9c823209733";
    hash = "sha256-aqBAIdo/1xFpNa3vXpae9bPQ7qR4OE01W1GQYma3UCs=";
    sparseCheckout = ["claude-code-panel"];
  };
  # Patch the upstream plugin so:
  #   1) defaultSettings.claude.model in manifest.json is "opus" instead of
  #      "". `opus` is the claude CLI's short alias that always resolves to
  #      the latest Opus model, so this seeded default survives Anthropic
  #      version bumps. Users can still override it via the plugin Settings
  #      panel ("/model <name>") or the Settings.qml field — defaultSettings
  #      only applies on first run when no stored value exists.
  # The two greps are tripwires: the first checks that Main.qml is still
  # wrapping `claude-code-acp` (the Zed-industries ACP bridge); if upstream
  # switches binary names in a future rev the build fails loudly, prompting
  # us to revisit the claudeCodeAcp wrapper below. The second confirms the
  # model sed actually matched, so a future schema change to manifest.json
  # can't silently revert the default back to "".
  claudeCodePanelPlugin = pkgs.runCommand "noctalia-claude-code-panel" {} ''
    set -euo pipefail
    cp -r ${claudeCodePanelPluginSrc}/claude-code-panel $out
    chmod -R u+w $out
    ${pkgs.gnugrep}/bin/grep -q '"which", "claude-code-acp"' $out/Main.qml
    ${pkgs.gnused}/bin/sed -i \
      's|"model": ""|"model": "opus"|' \
      $out/manifest.json
    ${pkgs.gnugrep}/bin/grep -q '"model": "opus"' $out/manifest.json
  '';

  # The plugin's Main.qml hardcodes `which claude-code-acp`, but nixpkgs
  # renamed `claude-code-acp` to `claude-agent-acp` (the binary inside is
  # `claude-agent-acp` too). Provide a thin alias so the plugin keeps
  # finding it on PATH without us having to fork the upstream QML on every
  # bump. `pkgs.claude-agent-acp` already bundles its own `claude` SDK
  # binary inside `@anthropic-ai/claude-agent-sdk-linux-x64/`, so we don't
  # need `pkgs.claude-code` for the plugin to *run* — but we still install
  # it below so the user can do `claude login` once to seed `~/.claude/`,
  # which the ACP bridge then reuses.
  claudeCodeAcp = pkgs.runCommand "claude-code-acp-alias" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.claude-agent-acp}/bin/claude-agent-acp $out/bin/claude-code-acp
  '';
  # Patch the upstream plugin so:
  #   1) ScreenShot.qml always opens the editor (satty), regardless of
  #      whether the region was finalised with LMB or RMB. Upstream uses
  #      LMB=copy / RMB=edit; we want one button, one behaviour.
  #   2) manifest.json defaults `screenshotEditor` to "satty" instead of
  #      "swappy" (acts as the seeded default; user can still flip in the
  #      Noctalia plugin settings GUI).
  # Each sed is followed by a grep so we'll *fail loudly* on the next
  # upstream rev bump if the strings drift, rather than silently reverting
  # to the LMB/RMB behaviour.
  screenShotPlugin = pkgs.runCommand "noctalia-screen-shot-and-record-patched" {} ''
    set -euo pipefail
    cp -r ${screenShotPluginSrc}/screen-shot-and-record $out
    chmod -R u+w $out
    ${pkgs.gnused}/bin/sed -i \
      's|const mode = (root.mouseButton === Qt.RightButton) ? "edit" : "copy"|const mode = "edit"|' \
      $out/ScreenShot.qml
    ${pkgs.gnugrep}/bin/grep -q 'const mode = "edit"' $out/ScreenShot.qml
    ${pkgs.gnused}/bin/sed -i \
      's|"screenshotEditor": "swappy"|"screenshotEditor": "satty"|' \
      $out/manifest.json
    ${pkgs.gnugrep}/bin/grep -q '"screenshotEditor": "satty"' $out/manifest.json
  '';

  # Upstream noctalia plugin: "Clipper" — advanced clipboard manager
  # (history, search, pinned items, notecards, ToDo integration).
  # https://github.com/noctalia-dev/noctalia-plugins/tree/main/clipper
  # Same sparseCheckout pattern as the plugins above. Pinned to the most
  # recent commit touching the clipper/ subdir (v2.4.4); bump `rev` (clear
  # `hash`, Nix prints the right one) to update.
  # Runtime backend `cliphist` is installed (and seeded with the
  # `wl-paste --watch cliphist store` daemon) from
  # modules/desktop/hyprland/{default.nix,lua/autostart.lua}; the plugin
  # itself just talks to cliphist over its CLI.
  clipperPluginSrc = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-plugins";
    rev = "5ea40763c436c52eb7ee862d9b827665af6bd7d5";
    hash = "sha256-c37Bhl8Bj8sfNozDq6v+lN4P0YUUQ/UePitH+v9V3rg=";
    sparseCheckout = ["clipper"];
  };
in {
  # Install tlp-ctl system-wide rather than into the per-user home-manager
  # profile. Noctalia is spawned by Hyprland's autostart.lua before the
  # home-manager profile is necessarily on PATH for the graphical session,
  # so a home.packages install would leave Quickshell's Process unable to
  # find `tlp-ctl` (the bar widget would stay stuck on the bolt/"…"
  # placeholder and clicks would silently no-op). /run/current-system/sw/bin
  # is always on PATH, and is where `tlp` itself lives.
  #
  # Same reasoning for the claude-code-panel plugin's runtime: the plugin
  # shells out to `which claude-code-acp` at QML init, before the
  # home-manager PATH is necessarily set up for the graphical session.
  # `claudeCodeAcp` exposes the renamed `claude-agent-acp` binary under the
  # plugin's expected name; `claude-code` ships the standalone `claude` CLI
  # so the user can run `claude` once to seed `~/.claude/` auth (the ACP
  # bridge reuses that auth state).
  environment.systemPackages = [
    tlpCtl
    claudeCodeAcp
    pkgs.claude-code
  ];

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

      # Ship the upstream screen-shot-and-record plugin the same way. The
      # whole subdirectory is mounted recursively (it has ~13 QML/sh/json
      # files plus an i18n/ folder), so we don't have to enumerate them.
      # Bound to SUPER+P in lua/binds.lua via:
      #   noctalia-shell ipc call plugin:screen-shot-and-record screenshot
      xdg.configFile."noctalia/plugins/screen-shot-and-record" = {
        source = screenShotPlugin;
        recursive = true;
      };

      # Ship the upstream claude-code-panel plugin. Same recursive mount;
      # see `claudeCodePanelPlugin` above for what's inside. Bound to
      # SUPER+SHIFT+C in lua/binds.lua via:
      #   noctalia-shell ipc call plugin:claude-code-panel toggle
      # Runtime deps (`claude-code-acp` alias + `claude` CLI) are wired
      # into environment.systemPackages above. First-time auth requires
      # running `claude` once interactively to populate ~/.claude/.
      xdg.configFile."noctalia/plugins/claude-code-panel" = {
        source = claudeCodePanelPlugin;
        recursive = true;
      };

      # Ship the upstream clipper plugin. Same recursive mount as the
      # other upstream plugins above. Bound to SUPER+V in lua/binds.lua via:
      #   noctalia-shell ipc call plugin:clipper toggle
      # Backed by `cliphist` (added to home.packages in hyprland/default.nix)
      # and a `wl-paste --watch cliphist store` daemon started from
      # lua/autostart.lua so clipboard history is actually captured.
      xdg.configFile."noctalia/plugins/clipper" = {
        source = clipperPluginSrc + "/clipper";
        recursive = true;
      };

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
            screen-shot-and-record = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
            claude-code-panel = {
              enabled = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
            clipper = {
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
                # Show the NixOS snowflake instead of Noctalia's bundled owl
                # logo. `useDistroLogo` makes the widget read LOGO= from
                # /etc/os-release (set to "nix-snowflake" by NixOS) and resolve
                # it via /run/current-system/sw/share/icons/hicolor/.../apps/,
                # where nixos-icons ships nix-snowflake.svg. Colorization stays
                # off (registry default) so the rainbow SVG renders in its
                # native colours rather than being flattened to a single tint.
                {id = "ControlCenter"; useDistroLogo = true;}
                {id = "Workspace"; showApplications = true; hideUnoccupied = false; colorizeIcons = false;}
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
            name = "Malmö, Sweden";
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
