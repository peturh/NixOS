{
  description = "A simple flake for an atomic system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cpyvn = {
      url = "gitlab:cpvpn/cpyvpn";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = {
    self,
    nixpkgs,
    sops-nix,
    ...
  } @ inputs: let
    inherit (self) outputs;

    # Shared settings across all hosts
    commonSettings = {
      # User configuration
      username = "petur"; # automatically set with install.sh and live-install.sh
      editor = "cursor"; # cursor, vscode
      browser = "microsoft-edge"; # firefox, floorp, zen
      terminal = "kitty"; # kitty, alacritty, wezterm
      terminalFileManager = "yazi"; # yazi or lf
      sddmTheme = "purple_leaves"; # astronaut, black_hole, purple_leaves, jake_the_dog, hyprland_kath
      wallpaper = "thinkpad"; # see modules/themes/wallpapers

      # System configuration
      locale = "en_GB.UTF-8"; # CHOOSE YOUR LOCALE
      timezone = "Europe/Stockholm"; # CHOOSE YOUR TIMEZONE
      kbdLayout = "se"; # CHOOSE YOUR KEYBOARD LAYOUT
      kbdVariant = ""; # CHOOSE YOUR KEYBOARD VARIANT (Can leave empty)
      consoleKeymap = "sv-latin1"; # CHOOSE YOUR CONSOLE KEYMAP (Affects the tty?)
    };

    # Per-host overrides
    hostSettings = {
      t14s = commonSettings // {
        hostname = "t14s";
        videoDriver = "amdgpu";
      };
      t470p = commonSettings // {
        hostname = "t470p";
        videoDriver = "nvidia";
        browser = "google-chrome";
      };
      t450 = commonSettings // {
        hostname = "t450";
        videoDriver = "intel";
        browser = "google-chrome";
      };
    };

    mkHost = name: settings: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit self inputs outputs;} // settings;
      modules = [./hosts/${name}/configuration.nix sops-nix.nixosModules.sops];
    };

    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    overlays = import ./overlays {inherit inputs; settings = commonSettings;};
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    nixosConfigurations = {
      t14s = mkHost "t14s" hostSettings.t14s;
      t470p = mkHost "t470p" hostSettings.t470p;
      t450 = mkHost "t450" hostSettings.t450;
    };
  };
}
