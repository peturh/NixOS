{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        unrar
        p7zip
      ];
    })
  ];
}

