{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        baobab # GNOME Disk Usage Analyzer
        dnsutils # dig, nslookup
        killall
        lm_sensors
        jq
        rsync
        unimatrix
      ];
    })
  ];
}
