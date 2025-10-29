{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        transmission_4-qt
      ];
    })
  ];

  # Transmission daemon service
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
  };
}

