{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        bitwarden-desktop
      ];
    })
  ];
}
