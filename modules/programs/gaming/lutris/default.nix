{pkgs, ...}: {
  # Lutris: game launcher used to install Battle.net (e.g. WoW Forever) via its own Wine/umu runners
  environment.systemPackages = with pkgs; [
    lutris
    winetricks
  ];

  # 32-bit graphics are required by the Battle.net launcher
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  home-manager.sharedModules = [
    (_: {
      # Direct launcher for the Lutris-managed Battle.net install, so it can be
      # started from the app menu without opening Lutris first.
      # `battlenet` is the Lutris game slug (see `lutris -l`); the icon is the
      # one Lutris drops into ~/.local/share/icons when the game is installed.
      xdg.desktopEntries.battlenet = {
        name = "Battle.net";
        genericName = "Game Launcher";
        comment = "Launch Battle.net through Lutris";
        exec = "lutris lutris:rungame/battlenet";
        icon = "lutris_battlenet";
        terminal = false;
        categories = ["Game"];
        settings.StartupWMClass = "steam_app_default";
      };
    })
  ];
}
