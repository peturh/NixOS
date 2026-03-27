{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        teams-for-linux
      ];
    })
  ];
}
