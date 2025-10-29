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

