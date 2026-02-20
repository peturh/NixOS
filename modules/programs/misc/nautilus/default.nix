{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nautilus
    nautilus-python
    nautilus-open-any-terminal
  ];

  environment.pathsToLink = [
    "/share/nautilus-python/extensions"
  ];

  home-manager.sharedModules = [
    (_: {
      xdg.configFile."xdg-terminals.list".text = "kitty.desktop\n";

      dconf.settings = {
        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          terminal = "kitty";
          keybindings = "";
          new-tab = false;
        };
      };
    })
  ];
}
