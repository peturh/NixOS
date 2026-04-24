{
  inputs,
  pkgs,
  browser,
  ...
}: {
  environment.systemPackages = [
    inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home-manager.sharedModules = pkgs.lib.optional (browser == "helium") (_: {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
        "x-scheme-handler/about" = "helium.desktop";
        "x-scheme-handler/unknown" = "helium.desktop";
      };
    };
  });
}
