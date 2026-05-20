{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        gpu-screen-recorder
        gpu-screen-recorder-gtk
      ];
    })
  ];
}
