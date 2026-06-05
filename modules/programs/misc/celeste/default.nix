{pkgs, ...}: let
  # Celeste's tray SVGs are GNOME-symbolic-style: the actual icon paths are
  # left fill-less and meant to be recolored by the consumer via a mask/filter
  # dance. QtSvg (Quickshell/DMS) doesn't grok that recoloring, so the visible
  # paths render with their default fill — black — and you get a black square
  # in the tray. Inject an explicit white fill on the visible (top-level)
  # paths so Qt renders them legibly on the dark tray bar. The `^    <path d=`
  # anchor only matches the in-viewBox paths; the masked recoloring paths are
  # deeper-indented and untouched.
  celestePatched = pkgs.celeste.overrideAttrs (old: {
    postFixup =
      (old.postFixup or "")
      + ''
        for icon in "$out"/share/icons/hicolor/symbolic/apps/com.hunterwittenborn.Celeste.CelesteTray*-symbolic.svg; do
          sed -i 's|^    <path d=|    <path fill="#ffffff" d=|' "$icon"
        done
      '';
  });
in {
  home-manager.sharedModules = [
    (_: {
      home.packages = [celestePatched];
    })
  ];
}
