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
    })
  ];
}
