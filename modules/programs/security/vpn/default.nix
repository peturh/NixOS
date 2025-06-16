{ config, lib, pkgs, ... }:

let
  vpnScript = pkgs.writeShellScriptBin "vpn" ''
    exec python3 -m cpyvpn.client vpn.puzzel.com \
      --realm="O365 Login" \
      --user="you@example.com" \
      --passwd-on-stdin <<< 'your_password_here'
  '';
in {

  config = lib.mkIf config.services.vpn.enable {
    environment.systemPackages = [ vpnScript ];

    # Optionally, start it as a service (not just CLI)
    # systemd.services.vpn-client = {
    #   description = "Custom VPN client";
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     ExecStart = "${vpnScript}/bin/vpn";
    #     Restart = "on-failure";
    #   };
    # };
  };
}