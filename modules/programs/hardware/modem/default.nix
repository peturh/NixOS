{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        modem-manager-gui
      ];
    })
  ];

  # ModemManager system service
  # Already enabled in configuration.nix but included here for context
  # networking.modemmanager.enable = true;
}

