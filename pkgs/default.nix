{
  pkgs,
  inputs,
  ...
}: {
  # these will be overlayed in nixpkgs automatically.
  # for example: environment.systemPackages = with pkgs; [pokego];
  pokego = pkgs.callPackage ./pokego.nix {};
  # Self-contained ThinkPad-branded SDDM themes. Two variants share the same
  # QML (Keyitdev's astronaut) but differ in wallpaper, palette, and form
  # placement to suit the dark and light ThinkPad wallpapers respectively.
  # Both are installed; a systemd oneshot (see hosts/common.nix) picks which
  # one SDDM uses at each greeter start based on the current hour.
  sddm-thinkpad-dark = pkgs.callPackage ./sddm-themes/thinkpad.nix {
    variant = "dark";
    wallpaper = ../modules/themes/wallpapers/thinkpad-dark.png;
  };
  sddm-thinkpad-light = pkgs.callPackage ./sddm-themes/thinkpad.nix {
    variant = "light";
    wallpaper = ../modules/themes/wallpapers/thinkpad-light.png;
  };
  lenovo-wwan-unlock = pkgs.callPackage ./easy-lenovo-wwan-unlock.nix {};
  cpyvpn = import ./cpyvpn.nix {inherit pkgs inputs;};
  extract-xiso = pkgs.callPackage ./extract-xiso.nix {};
  "8bitdo-updater" = pkgs.callPackage ./8bitdo-updater.nix {};
  iptvnator = pkgs.callPackage ./iptvnator.nix {};
  makerom = pkgs.callPackage ./makerom.nix {};
  ctrtool = pkgs.callPackage ./ctrtool.nix {};
  # DMS Agent plugin — installs the github.com/Francisdelca/dms-agent tree
  # under share/DankMaterialShell/plugins/dmsAgent so the DMS module can
  # symlink it into ~/.config/DankMaterialShell/plugins/dmsAgent.
  dms-agent = pkgs.callPackage ./dms-agent.nix {inherit inputs;};
}
