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
    ../../modules/hardware/networking
    ../common.nix
    ../../modules/scripts
    ../../modules/desktop/hyprland # Enable hyprland window manager
    ../../modules/programs/browser/${browser}
    ../../modules/programs/browser/google-chrome
    ../../modules/programs/terminal/${terminal} # Set terminal defined in flake.nix
    ../../modules/programs/editor/${editor} # Set editor defined in flake.nix
    ../../modules/programs/cli/${terminalFileManager} # Set file-manager defined in flake.nix
    ../../modules/programs/cli/starship
    ../../modules/programs/cli/tmux
    ../../modules/programs/cli/direnv
    ../../modules/programs/cli/lazygit
    ../../modules/programs/cli/cava
    ../../modules/programs/cli/btop
    ../../modules/programs/cli/micro
    ../../modules/programs/cli/utilities
    ../../modules/programs/cli/wget
    ../../modules/programs/shell/bash
    ../../modules/programs/shell/zsh
    ../../modules/programs/media/discord
    ../../modules/programs/media/slack
    ../../modules/programs/media/signal
    ../../modules/programs/media/spicetify
    ../../modules/programs/media/transmission
    ../../modules/programs/media/vlc
    ../../modules/programs/misc/archive
    ../../modules/programs/misc/gparted
    ../../modules/programs/misc/nautilus
    ../../modules/programs/misc/nix-ld
    ../../modules/programs/misc/tlp
    ../../modules/programs/misc/usbimager
    ../../modules/programs/misc/lact # GPU fan, clock and power configuration
    ../../modules/programs/hardware/modem
    ../../modules/programs/security/microsoft-intune
    ../../modules/programs/development/node
    ../../modules/programs/development/python3
    ../../modules/desktop/hyprland/programs/converse
    ../../modules/programs/security/cpyvpn
  ];


  services.intune.enable = true;

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = ["docker"];

  networking.hostName = hostname;
}
