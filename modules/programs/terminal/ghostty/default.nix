{pkgs, ...}: {
  fonts.packages = with pkgs.nerd-fonts; [jetbrains-mono];
  home-manager.sharedModules = [
    (_: {
      programs.ghostty = {
        enable = true;

        # Colours are driven by DMS's matugen pipeline. With
        # matugenTemplateGhostty=true in dms/settings.json, DMS regenerates
        #   ~/.config/ghostty/themes/dankcolors
        # on every wallpaper change or dark/light toggle (terminalsAlwaysDark
        # in DMS controls whether the dark variant is forced). DMS then sends
        # SIGUSR2 to every running ghostty so existing windows pick up the new
        # palette without a restart — that's why no kitty-style theme-watcher
        # systemd path unit is needed here.
        #
        # We deliberately do *not* declare programs.ghostty.themes.dankcolors:
        # home-manager would then own that file and clobber matugen's writes.
        settings = {
          font-family = "JetBrainsMono Nerd Font";
          font-size = 12;

          # Pull in DMS's matugen output. We import via `config-file` rather
          # than `theme = dankcolors` because the latter is strict — on the
          # very first home-manager activation (before DMS has had a chance
          # to render the template) `ghostty +validate-config` exits 1 with
          # "theme not found", which would fail HM activation. The `?`
          # prefix on `config-file` makes the include optional, so a missing
          # file is silently skipped and ghostty falls back to its defaults
          # until DMS writes the file. The path is relative to this config
          # (i.e. resolves to ~/.config/ghostty/themes/dankcolors).
          config-file = "?themes/dankcolors";

          # Mirror of the kitty config knobs so the two terminals feel
          # interchangeable when one is launched as a fallback.
          copy-on-select = "clipboard";
          mouse-hide-while-typing = true;
          confirm-close-surface = false;
          window-padding-x = 0;
          window-padding-y = 0;
          scrollback-limit = 10000000; # bytes, ghostty's default unit
          shell-integration-features = "no-cursor";

          # Suppress the toasts that fire on every clipboard copy and on
          # SIGUSR2-driven config reloads (DMS triggers a reload on every
          # wallpaper change; without this each one would spam a notification).
          app-notifications = "no-clipboard-copy,no-config-reload";

          # Keybinds chosen to match the kitty module so muscle memory carries
          # over. Use `keybind = "clear"` upfront only if you want to drop the
          # ghostty defaults — kept here to layer on top of them instead.
          keybind = [
            "ctrl+y=paste_from_clipboard"
            "alt+w=copy_to_clipboard"
            # tmux-sessionizer: type the command then press Enter via \n.
            # Ghostty's text: action handles the escape sequence directly.
            "ctrl+t=text:tmux-sessionizer\\n"
            "ctrl+alt+n=new_window"
            "alt+one=goto_tab:1"
            "alt+two=goto_tab:2"
            "alt+three=goto_tab:3"
            "alt+four=goto_tab:4"
            "alt+five=goto_tab:5"
            "alt+six=goto_tab:6"
            "alt+seven=goto_tab:7"
            "alt+eight=goto_tab:8"
            "alt+nine=goto_tab:9"
            "alt+zero=goto_tab:10"
            # Mirrors kitty's `ctrl+shift+left/right = no_op` so the
            # default tab-switch bindings don't conflict with terminal apps.
            "ctrl+shift+left=unbind"
            "ctrl+shift+right=unbind"
          ];
        };
      };
    })
  ];
}
