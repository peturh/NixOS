{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        baobab # GNOME Disk Usage Analyzer
        killall
        lm_sensors
        jq
        rsync
      ];
    })
  ];
}

