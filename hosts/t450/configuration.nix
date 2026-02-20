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
    ../../modules/hardware/video/${videoDriver}.nix
    ../../modules/hardware/networking
    ../../modules/hardware/audio
    ../common.nix
    ../../modules/scripts
    ../../modules/desktop/hyprland
    ../../modules/programs/browser/${browser}
    ../../modules/programs/browser/google-chrome
    ../../modules/programs/browser/firefox
    ../../modules/programs/terminal/${terminal}
    ../../modules/programs/editor/${editor}
    ../../modules/programs/cli/${terminalFileManager}
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
    ../../modules/programs/media/audacity
    ../../modules/programs/media/discord
    ../../modules/programs/media/mpv
    ../../modules/programs/media/radioboat
    ../../modules/programs/media/slack
    ../../modules/programs/media/signal
    ../../modules/programs/media/spicetify
    ../../modules/programs/media/transmission
    ../../modules/programs/media/vlc
    ../../modules/programs/media/gimp
    ../../modules/programs/misc/archive
    ../../modules/programs/misc/gparted
    ../../modules/programs/misc/nautilus
    ../../modules/programs/misc/nix-ld
    ../../modules/programs/misc/tlp
    ../../modules/programs/misc/usbimager
    ../../modules/programs/development/node
    ../../modules/programs/development/python3
    ../../modules/programs/development/go
    ../../modules/programs/gaming/steam
  ];

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = ["docker"];

  networking.hostName = hostname;
}
