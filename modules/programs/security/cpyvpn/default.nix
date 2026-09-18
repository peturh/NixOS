{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.programs.cpyvpn;

  # Fixed tunnel interface name so we can attach per-link DNS to it.
  tunIface = "cpvpn0";

  # Create a wrapper script that reads secrets and calls cpyvpn
  vpnScript = pkgs.writeShellScriptBin "vpn" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Read secrets from sops
    SERVER=$(cat /run/secrets/vpn-server)
    REALM=$(cat /run/secrets/vpn-realm)
    USERNAME=$(cat /run/secrets/vpn-username)
    PASSWORD=$(cat /run/secrets/vpn-password)

    ${lib.optionalString (cfg.dns.server != null) ''
      # Once the tunnel is up, route internal-domain queries to the work DNS
      # server. resolved drops this per-link config when the tunnel goes down.
      (
        for _ in $(seq 1 60); do
          if ${pkgs.iproute2}/bin/ip link show ${tunIface} &>/dev/null; then
            ${pkgs.systemd}/bin/resolvectl dns ${tunIface} ${cfg.dns.server}
            ${pkgs.systemd}/bin/resolvectl domain ${tunIface} ${lib.concatMapStringsSep " " (d: "'~${d}'") cfg.dns.domains}
            ${pkgs.systemd}/bin/resolvectl default-route ${tunIface} false
            echo "Split DNS active: ${lib.concatStringsSep ", " cfg.dns.domains} -> ${cfg.dns.server}"
            exit 0
          fi
          sleep 1
        done
        echo "Warning: ${tunIface} never appeared, split DNS not configured" >&2
      ) &
    ''}

    # Run cpyvpn with the secrets
    echo "Connecting to VPN at $SERVER..."
    exec ${cfg.package}/bin/cp_client "$SERVER" \
      --realm="$REALM" \
      --user="$USERNAME" \
      --interface=${tunIface} \
      --passwd-on-stdin <<< "$PASSWORD"
  '';
in {
  options.programs.cpyvpn = {
    enable = lib.mkEnableOption "the cpyvpn VPN client wrapper";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cpyvpn;
      description = "The cpyvpn package to use.";
    };

    dns = {
      server = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Internal DNS server to use for dns.domains while the VPN is up.";
      };

      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Domains whose queries are routed to dns.server (matched including subdomains).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Install both the cpyvpn package and the wrapper script
    environment.systemPackages = [
      cfg.package
      vpnScript
    ];

    # Split DNS needs systemd-resolved as the system resolver
    services.resolved.enable = lib.mkIf (cfg.dns.server != null) true;
    networking.networkmanager.dns = lib.mkIf (cfg.dns.server != null) "systemd-resolved";

    # Let the vpn wrapper set per-link DNS via resolvectl without a polkit prompt
    security.polkit.extraConfig = lib.mkIf (cfg.dns.server != null) ''
      polkit.addRule(function(action, subject) {
        var allowed = [
          "org.freedesktop.resolve1.set-dns-servers",
          "org.freedesktop.resolve1.set-domains",
          "org.freedesktop.resolve1.set-default-route",
        ];
        if (allowed.indexOf(action.id) >= 0 && subject.user == "${username}") {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
