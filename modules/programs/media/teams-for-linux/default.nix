{pkgs, ...}: let
  # Upstream `teams-for-linux` ships only an `app.asar` and reuses the bare
  # `electron` binary at runtime. On Wayland, Chromium/Ozone derives the
  # xdg-toplevel `app_id` from `package.json`'s `desktopName` (and only falls
  # back to `name` in very recent Electron versions); the upstream
  # `package.json` defines neither, so the running window advertises itself as
  # `electron`. Hyprland faithfully reports the class as `electron`, and our
  # DMS workspace switcher then asks the GTK icon theme for an `electron`
  # icon. Papirus has no such file, so Quickshell falls through to
  # `IconImageProvider::missingPixmap()` — the magenta-and-black quadrant
  # placeholder rendered next to the workspace number badge.
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

  # teams-for-linux's `#configureWayland` sets `disableGpu = true` on native
  # Wayland unless the user set the key themselves ("prevents blank windows").
  # The result was a `--use-gl=disabled` GPU process and
  # `--disable-gpu-compositing` renderers: software compositing, software
  # raster and software WebRTC encode/decode, ~3 cores during calls while
  # Slack/Claude/Bitwarden ran GPU-accelerated on the same render node.
  # Writing the key explicitly opts back in (`isOptionSetByUser` checks
  # `performance.disableGpu` in config.json).
  #
  # `electronCLIFlags` → `app.commandLine.appendSwitch`, which *replaces* an
  # existing switch value. The nixpkgs wrapper already passes
  # `--enable-features=WaylandWindowDecorations,WebRTCPipeWireCapturer`, so
  # those two must be repeated here or Wayland screen sharing breaks. The
  # extra features turn on VA-API video decode/encode (Phoenix iGPU and the
  # RX 9060 XT both expose H.264/HEVC/AV1 enc+dec via radeonsi).
  teamsConfig = {
    performance = {
      disableGpu = false;
      electronCLIFlags = [
        [
          "enable-features"
          (builtins.concatStringsSep "," [
            "WaylandWindowDecorations"
            "WebRTCPipeWireCapturer"
            "AcceleratedVideoDecodeLinuxGL"
            "AcceleratedVideoDecodeLinuxZeroCopyGL"
            "AcceleratedVideoEncoder"
            "VaapiIgnoreDriverChecks"
          ])
        ]
        "enable-gpu-rasterization"
        "enable-zero-copy"
      ];
    };
  };
in {
  home-manager.sharedModules = [
    (_: {
      home.packages = [teams-for-linux];
      xdg.configFile."teams-for-linux/config.json".text = builtins.toJSON teamsConfig;
    })
  ];
}
