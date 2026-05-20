{pkgs, ...}: {
  fonts.packages = with pkgs.nerd-fonts; [jetbrains-mono];
  home-manager.sharedModules = [
    ({config, ...}: {
      programs.kitty = {
        enable = true;
        font = {
          name = "JetBrainsMono Nerd Font";
          size = 12.0;
        };
        # Theme + tab colours are driven by DMS at runtime. DMS's matugen
        # pipeline (modules/desktop/hyprland/programs/dms/settings.json:
        # matugenTemplateKitty=true, syncModeWithPortal=true,
        # terminalsAlwaysDark=false) regenerates these two files every time
        # the wallpaper changes or the user toggles dark/light mode:
        #   ~/.config/kitty/dank-theme.conf  -- 16-colour palette + cursor/fg/bg
        #   ~/.config/kitty/dank-tabs.conf   -- tab bar colours + layout
        # We deliberately do *not* set `themeFile` so kitty.conf stays free of a
        # static include that would otherwise override the DMS palette.
        settings = {
          # shell = "${getExe pkgs.tmux}";
          # cursor_trail = 3; # Fancy cursor movements (especially in nixvim)
          # cursor_trail_decay = "0.08 0.3"; # Animation speed
          # cursor_trail_start_threshold = "4";
          strip_trailing_spaces = "smart";
          macos_option_as_alt = "yes";
          macos_quit_when_last_window_closed = true;
          copy_on_select = "yes";
          confirm_os_window_close = 0;
          scrollback_lines = 10000;
          enable_audio_bell = false;
          mouse_hide_wait = 60;
          update_check_interval = 0;
          term = "xterm-256color";

          # Enable a per-session control socket so a `kitty @ load-config`
          # call can hot-reload colours on every running window when DMS
          # rewrites dank-theme.conf (without it, only newly-spawned
          # windows pick up the change). See `reload-kitty-config` below.
          allow_remote_control = "socket-only";
          listen_on = "unix:@kitty-${config.home.username}";
        };

        # Tab styling intentionally stays out of `settings` because
        # dank-tabs.conf (included via extraConfig below) sets the same
        # keys. The personal overrides in extraConfig run *after* the
        # include and therefore win kitty's last-write-wins precedence.
        # shellIntegration.mode = "no-sudo";
        keybindings = {
          "ctrl+alt+n" = "launch --cwd=current";
          "alt+w" = "copy_and_clear_or_interrupt";
          "ctrl+y" = "paste_from_clipboard";
          "alt+1" = "goto_tab 1";
          "alt+2" = "goto_tab 2";
          "alt+3" = "goto_tab 3";
          "alt+4" = "goto_tab 4";
          "alt+5" = "goto_tab 5";
          "alt+6" = "goto_tab 6";
          "alt+7" = "goto_tab 7";
          "alt+8" = "goto_tab 8";
          "alt+9" = "goto_tab 9";
          "alt+0" = "goto_tab 10";

          # Tmux
          "ctrl+t" = "launch --cwd=current --type=overlay tmux-sessionizer";
          # "ctrl+t" = "launch --cwd=current --title tmux-sessionizer tmux-sessionizer";
          "ctrl+shift+left" = "no_op";
          "ctrl+shift+right" = "no_op";
        };

        # Trailing config that must run *after* the include of DMS's
        # generated files so the personal tab style preferences (round
        # powerline, minimal `{index}` title, non-bold active tab) win
        # kitty's last-write-wins precedence over the DMS tab template
        # defaults (slanted, elaborate title, bold).
        extraConfig = ''
          # Pulled in via globinclude so missing files (e.g. before DMS
          # has run matugen for the first time) are silently skipped
          # instead of producing a warning or failing the conf load.
          #
          # The pattern is intentionally *relative* — kitty resolves it
          # against the directory holding kitty.conf, i.e.
          # ~/.config/kitty/. Absolute patterns would crash here because
          # kitty 0.46.2 ships with Python 3.13, whose `Path.glob` raises
          # `NotImplementedError: Non-relative patterns are unsupported`
          # for absolute patterns, and kitty's conf parser does not catch
          # it (see kitty/conf/utils.py: `globinclude` handler).
          #
          # Sort order: `dank-tabs.conf` < `dank-theme.conf`. They set
          # disjoint keys so order doesn't matter for correctness.
          globinclude dank-*.conf

          # Personal overrides (must follow the includes so they win
          # kitty's last-write-wins precedence over the DMS tab file).
          tab_bar_style       powerline
          tab_powerline_style round
          tab_title_template  "{index}"
          active_tab_font_style   normal
          inactive_tab_font_style normal
        '';
      };

      # Tiny wrapper that asks every running kitty instance to re-read
      # its config. Triggered automatically by the systemd path unit
      # below; also installed on PATH so it can be invoked manually
      # (e.g. after editing kitty.conf or for debugging).
      home.packages = [
        (pkgs.writeShellApplication {
          name = "reload-kitty-config";
          runtimeInputs = [config.programs.kitty.package];
          text = ''
            sock="@kitty-${config.home.username}"
            if ! kitty @ --to "unix:$sock" ls >/dev/null 2>&1; then
              # No running listener (e.g. first kitty hasn't started
              # since boot); nothing to reload.
              exit 0
            fi
            kitty @ --to "unix:$sock" load-config
          '';
        })
      ];

      # Watch the matugen-generated kitty palette and hot-reload every
      # running kitty window whenever DMS rewrites it (which happens on
      # wallpaper changes and on dark/light mode toggles via the portal
      # sync). Without this, only newly-spawned windows would pick up
      # the new colours; existing windows would stay stuck on whatever
      # palette they read at startup until manually reloaded with
      # Ctrl+Shift+F5.
      #
      # PathChanged fires on close-after-write, which matches matugen's
      # "render to temp file, atomic rename" output pattern. Using
      # PathModified instead would fire mid-write and risk reloading an
      # incomplete file.
      systemd.user.paths."kitty-theme-watcher" = {
        Unit.Description = "Watch DMS-generated kitty palette for changes";
        Install.WantedBy = ["default.target"];
        Path = {
          PathChanged = "%h/.config/kitty/dank-theme.conf";
          Unit = "kitty-theme-reload.service";
        };
      };

      systemd.user.services."kitty-theme-reload" = {
        Unit.Description = "Hot-reload running kitty windows after a DMS palette refresh";
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.profileDirectory}/bin/reload-kitty-config";
        };
      };
    })
  ];
}
