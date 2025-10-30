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
}
