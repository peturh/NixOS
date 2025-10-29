{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        killall
        lm_sensors
        jq
      ];
    })
  ];
}

