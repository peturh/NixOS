{ config, lib, pkgs, ... }:

let
  cfg = config.programs.cpyvpn;
  
  # Create a wrapper script that reads secrets and calls cpyvpn
  vpnScript = pkgs.writeShellScriptBin "vpn" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Read secrets from sops
    SERVER=$(cat /run/secrets/vpn-server)
    REALM=$(cat /run/secrets/vpn-realm)
    USERNAME=$(cat /run/secrets/vpn-username)
    PASSWORD=$(cat /run/secrets/vpn-password)
    
    # Run cpyvpn with the secrets
    echo "Connecting to VPN at $SERVER..."
    ${cfg.package}/bin/cp_client "$SERVER" \
      --realm="$REALM" \
      --user="$USERNAME" \
      --passwd-on-stdin <<< "$PASSWORD"
  '';
in
{
  options.programs.cpyvpn = {
    enable = lib.mkEnableOption "the cpyvpn VPN client wrapper";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cpyvpn;
      description = "The cpyvpn package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install both the cpyvpn package and the wrapper script
    environment.systemPackages = [ 
      cfg.package
      vpnScript
    ];
  };
}
