{
  lib,
  pkgs,
  ...
}: let
  shared = import ../_shared.nix {inherit pkgs;};
in {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["code-cursor"];
  home-manager.sharedModules = [
    (_: {
      # Home Manager split each VSCode fork into its own dedicated module.
      # `programs.vscode` now always writes to upstream VSCode paths
      # (~/.config/Code/User), regardless of the package, so Cursor would
      # silently lose its config. Use `programs.cursor` so settings land at
      # ~/.config/Cursor/User where Cursor actually reads them.
      programs.cursor = {
        enable = true;
        profiles.default = {
          inherit (shared) extensions keybindings userSettings;
        };
      };
    })
  ];
}
