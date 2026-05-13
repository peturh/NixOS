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
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      # Temporarily pinned to x1h0's fork while PR #14393 is unmerged. It
      # fixes the Hyprland 0.55.0 multi-monitor regression where the cursor
      # is clamped to the area the first monitor occupied at startup
      # (PointerManager doesn't subscribe to monitor.layoutChanged).
      # PR:    https://github.com/hyprwm/Hyprland/pull/14393
      # Issue: https://github.com/hyprwm/Hyprland/discussions/14382
      # Revert to "github:hyprwm/Hyprland" once the PR is merged upstream.
      url = "github:x1h0/Hyprland/c030716c449fbd9f69e7627aaae5a26c914b973b";
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
      textEditor = "micro"; # micro, nano, vim
      browser = "vivaldi"; # firefox, floorp, zen, microsoft-edge
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
        browser = "helium";
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
