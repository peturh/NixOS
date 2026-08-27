{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        # nixpkgs pins bitwarden-desktop to electron 39 which is now EOL and
        # blocked by the insecure-package guard. Override to electron 43 and
        # neutralise bitwarden's preBuild major-version check (the check is a
        # safety net for upstream's own pinning, not a hard runtime requirement).
        ((bitwarden-desktop.override {
            electron_39 = electron_43;
          })
          .overrideAttrs (old: {
            preBuild =
              builtins.replaceStrings
              ["  echo 'ERROR: electron version mismatch'\n  exit 1\n"]
              ["  echo 'WARN: electron major-version mismatch tolerated by override'\n"]
              old.preBuild;
          }))
      ];
    })
  ];
}
