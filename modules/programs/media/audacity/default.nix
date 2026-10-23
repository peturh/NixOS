{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        # Audacity 4.0.0 on unstable fails to compile against the current Qt
        # (ambiguous 'Type' in generated qmlcache). Use stable until fixed.
        stable.audacity # Audio editor and recorder
      ];
    })
  ];
}
