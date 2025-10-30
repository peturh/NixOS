{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        slack
      ];

      # Apply Catppuccin Mocha theme to Slack
      home.file.".slack-theme".text = ''
        # Catppuccin Mocha for Slack
        # Copy this into Slack's custom theme settings: Preferences > Themes > Create a custom theme
        #1e1e2e,#313244,#cba6f7,#cdd6f4,#313244,#cdd6f4,#a6e3a1,#f38ba8,#1e1e2e,#cdd6f4
      '';

      # Custom CSS for Slack (if using slack-theme injector)
      xdg.configFile."slack-theme/custom.css".text = ''
        /* Catppuccin Mocha Theme for Slack */
        :root {
          --base: #1e1e2e;
          --mantle: #181825;
          --crust: #11111b;
          --surface0: #313244;
          --surface1: #45475a;
          --surface2: #585b70;
          --text: #cdd6f4;
          --subtext0: #a6adc8;
          --subtext1: #bac2de;
          --overlay0: #6c7086;
          --overlay1: #7f849c;
          --overlay2: #9399b2;
          --mauve: #cba6f7;
          --pink: #f5c2e7;
          --maroon: #eba0ac;
          --red: #f38ba8;
          --peach: #fab387;
          --yellow: #f9e2af;
          --green: #a6e3a1;
          --teal: #94e2d5;
          --sky: #89dceb;
          --sapphire: #74c7ec;
          --blue: #89b4fa;
          --lavender: #b4befe;
        }

        /* Apply theme colors */
        .p-client_container {
          background-color: var(--base) !important;
        }

        .c-message:hover {
          background-color: var(--surface0) !important;
        }

        .c-message_kit__background--hovered {
          background-color: var(--surface0) !important;
        }
      '';
    })
  ];
}

