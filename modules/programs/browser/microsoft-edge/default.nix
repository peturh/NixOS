{

  inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

  outputs = inputs@{ self, nixpkgs, ... }:
  {
      environment.systemPackages = with pkgs; [
        microsoft-edge
  ];
  };
}