{
  pkgs,
  videoDriver,
  hostname,
  username,
  browser,
  editor,
  terminal,
  terminalFileManager,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/video/${videoDriver}.nix # Enable gpu drivers defined in flake.nix
    ../../modules/hardware/drives

    ../common.nix
    ../../modules/scripts

    ../../modules/desktop/hyprland # Enable hyprland window manager
    # ../../modules/desktop/i3-gaps # Enable i3 window manager

#    ../../modules/programs/games
  #  ../../modules/programs/browser/firefox # Set browser defined in flake.nix
   ../../modules/programs/browser/floorp
    ../../modules/programs/terminal/${terminal} # Set terminal defined in flake.nix
    ../../modules/programs/editor/${editor} # Set editor defined in flake.nix
    ../../modules/programs/cli/${terminalFileManager} # Set file-manager defined in flake.nix
    ../../modules/programs/cli/starship
    ../../modules/programs/cli/tmux
    ../../modules/programs/cli/direnv
    ../../modules/programs/cli/lazygit
    ../../modules/programs/cli/cava
    ../../modules/programs/cli/btop
    ../../modules/programs/shell/bash
    ../../modules/programs/shell/zsh
    ../../modules/programs/media/discord
    ../../modules/programs/media/spicetify
    # ../../modules/programs/media/youtube-music
    # ../../modules/programs/media/thunderbird
    # ../../modules/programs/media/obs-studio
    ../../modules/programs/media/mpv
    ../../modules/programs/misc/tlp
    ../../modules/programs/misc/thunar
    ../../modules/programs/misc/lact # GPU fan, clock and power configuration
    # ../../modules/programs/misc/nix-ld
    # ../../modules/programs/misc/virt-manager
    ../../modules/programs/security/microsoft-intune
  ];

  # Home-manager config
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        # pokego # Overlayed
        # krita
 #       github-desktop
        # gimp
      ];
    })
  ];

  # Define system packages here
  environment.systemPackages = with pkgs; [
    google-chrome
    slack
    # intune-portal
    python3
  ];

  # services.intune.enable = true;

  networking.extraHosts = 
    "
    10.47.26.11 app-kibana.puzzel.com
    172.16.200.21 grafana.prod.local
    10.47.30.48 p1elk01.prod.local
    172.16.151.11 devapp-kibana.puzzel.com
    10.7.24.10 uk-kibana.puzzel.com
    10.47.26.11 unleash.prod.local
    "
  ;

  # In /etc/nixos/configuration.nix
  virtualisation.docker = {
    enable = true;
  };

# Optional: Add your user to the "docker" group to run docker without sudo
  users.users.${username}.extraGroups = [ "docker" ];

  networking.hostName = hostname; # Set hostname defined in flake.nix
}
