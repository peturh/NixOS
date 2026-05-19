{pkgs, ...}: let
  # Upstream `teams-for-linux` ships only an `app.asar` and reuses the bare
  # `electron` binary at runtime. On Wayland, Chromium/Ozone derives the
  # xdg-toplevel `app_id` from `package.json`'s `desktopName` (and only falls
  # back to `name` in very recent Electron versions); the upstream
  # `package.json` defines neither, so the running window advertises itself as
  # `electron`. Hyprland faithfully reports the class as `electron`, and our
  # Noctalia Workspace widget (`showApplications = true`) then asks the GTK
  # icon theme for an `electron` icon. Papirus has no such file, so Quickshell
  # falls through to `IconImageProvider::missingPixmap()` — the magenta-and-
  # black quadrant placeholder rendered next to the workspace number badge.
  #
  # Slack and Cursor avoid this because their nixpkgs packages ship their own
  # `slack`/`cursor` ELF launchers that exec into Electron; argv[0]'s basename
  # then matches the icon they ship.
  #
  # Fix tracked upstream as NixOS/nixpkgs#512444. Until that lands, patch
  # `package.json` in `postPatch` (the asar is rebuilt by electron-builder in
  # the package's build phase, so this propagates into the final asar) to
  # inject `desktopName = "teams-for-linux.desktop"`. Electron then sets
  # app_id to `teams-for-linux`, Hyprland reports that as the class, and
  # Papirus's `teams-for-linux.svg` (already shipped at every hicolor size by
  # the package itself, plus in Papirus-Dark) resolves cleanly.
  #
  # The matched-string check (`--replace-fail`) is deliberate: if upstream
  # ever reorders package.json or adds desktopName themselves, the build
  # fails loudly instead of silently no-oping and leaving us with the same
  # "electron" app_id.
  teams-for-linux = pkgs.teams-for-linux.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace package.json \
          --replace-fail '"name": "teams-for-linux",' '"desktopName": "teams-for-linux.desktop",
        "name": "teams-for-linux",'
      '';
  });
in {
  home-manager.sharedModules = [
    (_: {
      home.packages = [teams-for-linux];
    })
  ];
}
