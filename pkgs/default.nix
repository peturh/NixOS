{
  pkgs,
  settings,
  inputs,
  ...
}: {
  # these will be overlayed in nixpkgs automatically.
  # for example: environment.systemPackages = with pkgs; [pokego];
  pokego = pkgs.callPackage ./pokego.nix {};
  sddm-astronaut = pkgs.callPackage ./sddm-themes/astronaut.nix {theme = settings.sddmTheme;};
  lenovo-wwan-unlock = pkgs.callPackage ./easy-lenovo-wwan-unlock.nix { };
  cpyvpn = import ./cpyvpn.nix { inherit pkgs inputs; };
  extract-xiso = pkgs.callPackage ./extract-xiso.nix {};
  "8bitdo-updater" = pkgs.callPackage ./8bitdo-updater.nix {};
  iptvnator = pkgs.callPackage ./iptvnator.nix {};
  makerom = pkgs.callPackage ./makerom.nix {};
  ctrtool = pkgs.callPackage ./ctrtool.nix {};
}
