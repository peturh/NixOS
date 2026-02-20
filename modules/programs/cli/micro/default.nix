{pkgs, ...}: let
  # Fetch catppuccin colorschemes for micro from official repo
  catppuccin-micro = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "micro";
    rev = "main";
    hash = "sha256-XbhUwRz21/XLkdOb6VOqLwzxWtehf6qRms0YcepNQ0s=";
  };
in {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        micro
      ];

      xdg.desktopEntries.micro = {
        name = "Micro Editor";
        genericName = "Text Editor";
        exec = "kitty -e micro %F";
        icon = "text-editor";
        terminal = false;
        categories = ["Utility" "TextEditor"];
        mimeType = ["text/plain" "text/x-readme" "text/markdown" "application/x-shellscript" "text/x-csrc" "text/x-chdr" "text/x-c++src" "text/x-c++hdr" "text/x-java" "text/x-python" "text/x-script.python" "application/json" "application/xml" "text/xml" "text/x-yaml" "text/x-toml" "text/css" "text/javascript" "application/javascript" "text/x-lua" "text/x-makefile" "text/x-nix"];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/plain" = "micro.desktop";
        };
      };

      # Install catppuccin colorschemes from themes/ directory
      xdg.configFile."micro/colorschemes/catppuccin-mocha.micro".source = "${catppuccin-micro}/themes/catppuccin-mocha.micro";
      xdg.configFile."micro/colorschemes/catppuccin-macchiato.micro".source = "${catppuccin-micro}/themes/catppuccin-macchiato.micro";
      xdg.configFile."micro/colorschemes/catppuccin-frappe.micro".source = "${catppuccin-micro}/themes/catppuccin-frappe.micro";
      xdg.configFile."micro/colorschemes/catppuccin-latte.micro".source = "${catppuccin-micro}/themes/catppuccin-latte.micro";

      xdg.configFile."micro/settings.json".text = builtins.toJSON {
        colorscheme = "catppuccin-mocha";
        # Other catppuccin variants: catppuccin-macchiato, catppuccin-frappe, catppuccin-latte
        # Built-in themes: monokai, atom-dark, solarized, zenburn, twilight, simple, darcula
        autosu = true;
        mkparents = true;
        scrollbar = true;
        scrollmargin = 3;
        scrollspeed = 2;
        tabsize = 2;
        tabstospaces = true;
        ruler = true;
        colorcolumn = 80;
        cursorline = true;
        infobar = true;
        diff = true;
        saveundo = false;  # Disabled due to version upgrade issues
      };

      # Set environment variable for true color support
      home.sessionVariables = {
        MICRO_TRUECOLOR = "1";
      };
    })
  ];
}

