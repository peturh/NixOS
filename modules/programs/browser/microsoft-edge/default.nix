{
  pkgs,
  inputs,
  ...
}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        microsoft-edge
      ];

      # Set Microsoft Edge as the default browser for all web links
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "microsoft-edge.desktop";
          "x-scheme-handler/http" = "microsoft-edge.desktop";
          "x-scheme-handler/https" = "microsoft-edge.desktop";
          "x-scheme-handler/about" = "microsoft-edge.desktop";
          "x-scheme-handler/unknown" = "microsoft-edge.desktop";
        };
      };
    })
  ];
}
