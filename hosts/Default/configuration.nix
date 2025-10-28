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
    ../../modules/programs/shell/bash
    ../../modules/programs/shell/zsh
    ../../modules/programs/media/discord
    ../../modules/programs/media/spicetify
    ../../modules/programs/media/mpv
    ../../modules/programs/misc/tlp
    # ../../modules/programs/misc/thunar
    ../../modules/programs/misc/lact # GPU fan, clock and power configuration
    ../../modules/programs/security/microsoft-intune
    ../../modules/programs/development/python3
    ../../modules/desktop/hyprland/programs/converse
    ../../modules/programs/security/cpyvpn
  ];

  # Home-manager config
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        # pokego # Overlayed
        # krita
 #       github-desktop
        # gimp
        # converse
      ];
    })
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];


  # Define system packages here
  environment.systemPackages = with pkgs; [
    # google-chrome
    slack
    intune-portal
    nwg-look
    # microsoft-edge
    modem-manager-gui
    nodejs_24
    signal-desktop
    usbimager
    transmission_4-qt
    gparted
    nautilus
    unrar
    wget
    crystal
    p7zip
    modemmanager
    vlc
    # converse
  ];

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
  };
  services.intune.enable = true;
  # services.power-profiles-daemon.enable = true;'
  # services.tlp.enable = true;
  # services.tlp.settings = {
  #       CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #       CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #       CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  #       CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  # };


  networking.networkmanager.enable = true;
  networking.modemmanager.enable = true;

  networking.modemmanager.fccUnlockScripts = [
      {
          id = "8086:7560"; 
          path = "${pkgs.lenovo-wwan-unlock}/bin/fcc_unlock.sh";
      }

   ];

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
services.samba.enable = true;

services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
};
#   hardware.printers = {
#   ensureDefaultPrinter = "Konica Minolta";
#   ensurePrinters = [
#     {
#       deviceUri = "ipp://10.12.3.8/ipp";
#       location = "work";
#       name = "Konica Minolta";
#       model = "C250-PS-P";
#     }
#   ];
# };


  # In /etc/nixos/configuration.nix
  virtualisation.docker = {
    enable = true;
  };

# Optional: Add your user to the "docker" group to run docker without sudo
  users.users.${username}.extraGroups = [ "docker" ];

  networking.hostName = hostname; # Set hostname defined in flake.nix


#   sops = {
#   enable = true;
#   age.keyFile = "/var/lib/sops/age.key";
#   secrets.cpyvpn_config = {
#     # Points to the encrypted file we created
#     sopsFile = ../../secrets.yaml;
#     # Tells sops to format it as a key = value file
#     format = "ini";
#   };
# };

# 2. This block enables the service and points it to the secure config file
# services.cpyvpn = {
#   enable = true;
#   # This path is provided automatically by sops-nix
#   configFile = config.sops.secrets.cpyvpn_config.path;
# };

}
