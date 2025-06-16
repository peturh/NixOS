{ config, pkgs, lib, inputs, ... }:

let
  # Custom package set with unfree enabled
  legacyPkgs = import NUR {
    system = pkgs.system;
    config.allowBroken = false;
    config.allowUnfree = true;
  };

  # Hardware acceleration flags
  # hardwareAccelerationFlags = "--enable-accelerated-video-decode --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist";

  # # Wrap Microsoft Edge with hardware acceleration flags
  # microsoftEdgeWrapped = pkgs.writeShellScriptBin "microsoft-edge" ''
  #   exec ${oldPkgs.microsoft-edge} ${hardwareAccelerationFlags} "$@"
  # '';

in {
  config = {
    environment.systemPackages = [
      legacyPkgs.nanamiiiii.microsoft-edge
    ];
  };
}