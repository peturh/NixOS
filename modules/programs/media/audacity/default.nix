{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        audacity  # Audio editor and recorder
      ];
    })
  ];
}

