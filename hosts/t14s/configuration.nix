{
  inputs,
  lib,
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
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14s-amd-gen4
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
    ../../modules/programs/browser/microsoft-edge
    ../../modules/programs/browser/google-chrome
    ../../modules/programs/browser/firefox
    ../../modules/programs/browser/helium
    ../../modules/programs/terminal/${terminal}
    ../../modules/programs/editor/${editor}
    ../../modules/programs/cli/${terminalFileManager}
    ../../modules/programs/cli/tmux
    ../../modules/programs/cli/direnv

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
    ../../modules/programs/media/teams-for-linux
    ../../modules/programs/media/signal
    ../../modules/programs/media/spicetify
    ../../modules/programs/media/transmission
    ../../modules/programs/media/vlc
    ../../modules/programs/media/gimp
    ../../modules/programs/media/gpu-screen-recorder
    ../../modules/programs/misc/archive
    ../../modules/programs/misc/calculator
    ../../modules/programs/misc/rclone
    ../../modules/programs/misc/gparted
    ../../modules/programs/misc/nautilus
    ../../modules/programs/misc/nix-ld
    ../../modules/programs/misc/orca
    ../../modules/programs/misc/tlp
    ../../modules/programs/misc/usbimager
    ../../modules/programs/misc/lact
    ../../modules/programs/misc/porttelefon
    ../../modules/programs/hardware/modem
    ../../modules/programs/security/bitwarden
    ../../modules/programs/security/microsoft-intune
    ../../modules/programs/development/node
    ../../modules/programs/development/python3
    ../../modules/programs/development/go
    ../../modules/programs/development/webengage-release
    ../../modules/programs/security/cpyvpn
    ../../modules/programs/gaming/steam
  ];

  boot.initrd.kernelModules = ["amdgpu"];
  # cpuid is needed by amd_s2idle (amd-debug-tools) to check core topology
  boot.kernelModules = ["cpuid"];

  boot.kernelParams = [
    "amdgpu.dcdebugmask=0x10"
    "amd_pstate=active"
    # memfd_secret (used by Electron/Bitwarden) disables hibernation kernel-wide
    "secretmem.enable=0"
    # First physical extent of /var/lib/swapfile (filefrag -v); re-derive if
    # the swapfile is ever recreated.
    "resume_offset=58949632"
  ];

  # Hibernation target: 32G swapfile inside LUKS, replacing the unencrypted 8G
  # swap partition (nvme0n1p2) so the RAM image never hits disk in plaintext.
  # Runtime swapping still goes to zram (higher priority).
  swapDevices = lib.mkForce [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];
  boot.resumeDevice = "/dev/mapper/luks-root";
  # After the swapfile exists, get the offset with:
  #   filefrag -v /var/lib/swapfile | awk 'NR==4 {print $4}'
  # and add "resume_offset=<value>" to boot.kernelParams above.

  # Suspend first; if the lid stays closed, wake and hibernate (zero drain).
  services.logind.settings.Login.HandleLidSwitch = lib.mkForce "suspend-then-hibernate";
  systemd.sleep.settings.Sleep.HibernateDelaySec = "45min";

  powerManagement.enable = true;
  services.power-profiles-daemon.enable = false;

  # T14s-specific: Logitech wireless device support
  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;

  # T14s-specific: 8BitDo controller udev rules
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5750", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", ATTR{idProduct}=="5750", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTR{idVendor}=="2dc8", TAG+="uaccess"
  '';

  # T14s-specific packages
  environment.systemPackages = with pkgs; [
    mkcert
    solaar
  ];

  services.intune.enable = true;
  programs.cpyvpn.enable = true;
  programs.webengage-release.enable = true;
  programs.porttelefon.enable = true;

  programs.obsidian-sync = {
    enable = true;
    pairs = [
      {
        remote = "gdrive-personal:Familj";
        local = "Family";
      }
      {
        remote = "gdrive-personal:Puzzel";
        local = "Puzzel";
      }
    ];
  };

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = ["docker"];

  networking.hostName = hostname;
}
