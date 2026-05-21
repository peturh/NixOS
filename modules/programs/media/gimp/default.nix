{pkgs, ...}: {
  home-manager.sharedModules = [
    ({lib, ...}: {
      home.packages = with pkgs; [
        gimp
      ];

      # Keep GIMP's bundled "Default" theme but flip prefer-dark-theme to
      # match DMS's current light/dark mode. Out of the box GIMP defaults
      # to prefer-dark=yes regardless of the system, which layers
      # gimp-dark.css on top of an adw-gtk3 *light* base when DMS is in
      # light mode — produces clipped labels and unstyled red radio
      # buttons. Patching the two keys on rebuild keeps the GIMP CSS
      # variant aligned with the system base. The keys are stripped and
      # re-appended (instead of templating the whole file) so the rest of
      # gimprc — which GIMP writes from its Preferences UI — survives.
      home.activation.gimpTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
        gimprc="$HOME/.config/GIMP/3.0/gimprc"
        dmsSession="$HOME/.local/state/DankMaterialShell/session.json"

        preferDark=yes
        if [ -f "$dmsSession" ] \
          && ${pkgs.jq}/bin/jq -e '.isLightMode == true' "$dmsSession" >/dev/null 2>&1; then
          preferDark=no
        fi

        ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$gimprc")"
        [ -f "$gimprc" ] || ${pkgs.coreutils}/bin/touch "$gimprc"

        ${pkgs.gnused}/bin/sed -i \
          -e '/^(theme /d' \
          -e '/^(prefer-dark-theme /d' \
          "$gimprc"

        {
          echo "(theme \"Default\")"
          echo "(prefer-dark-theme $preferDark)"
        } >> "$gimprc"
      '';
    })
  ];
}
