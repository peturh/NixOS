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
    ../../modules/hardware/networking/wwan.nix
    ../../modules/hardware/networking/work-hosts.nix
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
    ../../modules/programs/misc/lact
    ../../modules/programs/misc/porttelefon
    ../../modules/programs/hardware/modem
    ../../modules/programs/security/microsoft-intune
    ../../modules/programs/development/node
    ../../modules/programs/development/python3
    ../../modules/programs/development/go
    ../../modules/programs/development/webengage-release
    ../../modules/programs/security/cpyvpn
    ../../modules/programs/gaming/steam
  ];

  # T14s-specific: AMD kernel param
  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
  ];

  # T14s-specific: Logitech wireless device support
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # T14s-specific: 8BitDo controller udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5750", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", ATTR{idProduct}=="5750", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", TAG+="uaccess"
  '';

  # T14s-specific packages
  environment.systemPackages = with pkgs; [
    solaar
    gnome-firmware
    pkgs."8bitdo-updater"
  ];

  services.intune.enable = true;
  programs.cpyvpn.enable = true;
  programs.webengage-release.enable = true;
  programs.porttelefon.enable = true;

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = ["docker"];

  networking.hostName = hostname;
}
