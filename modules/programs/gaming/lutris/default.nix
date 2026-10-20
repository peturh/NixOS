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
}
