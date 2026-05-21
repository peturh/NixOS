{
  lib,
  pkgs,
  ...
}: let
  shared = import ../_shared.nix {inherit pkgs;};
in {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["vscode"];
  home-manager.sharedModules = [
    (_: {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        profiles.default = {
          extensions = shared.extensions ++ [pkgs.vscode-extensions.anthropic.claude-code];
          inherit (shared) keybindings userSettings;
        };
      };
    })
  ];
}
