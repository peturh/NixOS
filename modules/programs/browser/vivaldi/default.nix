{
  pkgs,
  inputs,
  ...
}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        # --force-renderer-accessibility makes Chromium expose its full
        # accessibility tree so Orca (and other AT-SPI clients) can read
        # page content. Chromium disables it by default for performance.
        (vivaldi.override {
          commandLineArgs = "--force-renderer-accessibility";
        })
      ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "vivaldi-stable.desktop";
          "x-scheme-handler/http" = "vivaldi-stable.desktop";
          "x-scheme-handler/https" = "vivaldi-stable.desktop";
          "x-scheme-handler/about" = "vivaldi-stable.desktop";
          "x-scheme-handler/unknown" = "vivaldi-stable.desktop";
        };
      };
    })
  ];
}
