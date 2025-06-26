# ~/NixOS/dev-shells/admin/flake.nix
# This file defines the shell environment for system administration.

{ pkgs, ... }:

pkgs.mkShell {
  name = "nixos-admin-shell";

  # The command-line tools you want available for managing your configuration
  packages = with pkgs; [
    sops
    age
    git
    alejandra # Good to have the formatter here too
  ];

  shellHook = ''
    echo "Entered NixOS Sops Shell."
    echo "Tools available: sops, age, git, alejandra"
  '';
}