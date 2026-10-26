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
    ../../modules/programs/media/photocraft
    ../../modules/programs/media/pdfcraft
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
    ../../modules/programs/development/node
    ../../modules/programs/development/python3
    ../../modules/programs/development/go
    ../../modules/programs/development/dotnet
    ../../modules/programs/development/kubernetes
    ../../modules/programs/development/webengage-release
    ../../modules/programs/development/webengage-pr
    ../../modules/programs/security/cpyvpn
    ../../modules/programs/gaming/steam
    ../../modules/programs/gaming/lutris
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

  # A stalled hibernate entry (amdgpu SMU hang) can keep logind from pinging
  # its 3 min watchdog; systemd then restarts it, the Hyprland session loses
  # its devices and SDDM spawns a greeter over it, leaving the lock screen
  # unusable. A longer limit lets logind survive the stall.
  systemd.services.systemd-logind.serviceConfig.WatchdogSec = "10min";

  powerManagement.enable = true;
  services.power-profiles-daemon.enable = false;

  # T14s-specific: Logitech wireless device support
  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;

  # T14s-specific: Thunderbolt/USB4 device authorization (boltctl) for the
  # AOOSTAR AG02 eGPU enclosure (Radeon RX 9060 XT). Ports are in "user"
  # security mode, so new devices must be enrolled with `boltctl enroll`.
  services.hardware.bolt.enable = true;

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
    # Unstable azure-cli depends on python fabric, marked broken since
    # invoke>=3 (fabric/fabric#2376). Use stable until nixpkgs fixes it.
    stable.azure-cli
  ];

  programs.cpyvpn = {
    enable = true;
    dns = {
      # dev.local DCs (d1dc01/d1dc02): they serve dev.local, forward
      # prod.local, and return the internal split-horizon answers for
      # dev/stag/test/qa *.puzzel.com (the prod DC 10.47.28.16 only knows
      # prod.local and returns public IPs for those).
      servers = ["172.16.150.11" "172.16.150.12"];
      domains = ["puzzel.com" "prod.local" "dev.local"];
    };
  };

  # Names missing from the internal puzzel.com zone: the DCs answer NXDOMAIN
  # and resolved never falls back to public DNS, so pin the public records.
  # Temporary until IT adds them internally (asked 2026-10-20) — the Azure
  # 20.x IPs in particular can change.
  networking.hosts = {
    "212.89.50.28" = ["devagentid.puzzel.com"];
    "20.50.2.74" = ["devagna.puzzel.com" "qaagna.puzzel.com" "stagagna.puzzel.com" "testagna.puzzel.com"];
    "212.89.50.128" = ["devturn.puzzel.com"];
    "212.89.52.177" = ["turn.puzzel.com"];
    "20.108.64.217" = ["ukturn.puzzel.com"];
    "77.243.49.219" = ["dharma.puzzel.com"];
  };
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
