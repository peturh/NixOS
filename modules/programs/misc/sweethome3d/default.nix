{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        sweethome3d.application
      ];
    })
  ];
}
