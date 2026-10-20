{
  config,
  lib,
  pkgs,
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
      # cpyvpn configures the tunnel THROUGH NetworkManager: on every connect
      # it writes the gateway-provided DNS into the ${tunIface} connection
      # profile (nmcli mod ... ipv4.dns) and NM owns the link's DNS from then
      # on, reasserting the profile at will — direct resolvectl writes don't
      # survive. So override at the same layer: rewrite the profile with the
      # internal DNS server and reapply it, and keep watching for the whole
      # session in case cp_client rewrites the profile again.
      (
        nmcli=${pkgs.networkmanager}/bin/nmcli
        our_domains="${lib.concatMapStringsSep " " (d: "~${d}") cfg.dns.domains}"

        apply_dns() {
          # Keep gateway-pushed search domains (our server serves those zones
          # too), but drop duplicates of our own routing domains.
          keep=""
          for d in $($nmcli -g ipv4.dns-search connection show ${tunIface} 2>/dev/null | tr ',' ' '); do
            case " $our_domains " in
              *" $d "*) ;;
              *) keep="$keep $d" ;;
            esac
          done
          $nmcli connection modify ${tunIface} ipv4.dns "${cfg.dns.server}" ipv4.dns-search "$keep $our_domains" \
            && $nmcli device reapply ${tunIface} >/dev/null \
            || echo "Warning: failed to apply split DNS to ${tunIface}" >&2
        }

        # Wait for NM to report the tunnel connected (gateway DNS is written
        # to the profile before activation, so it's in place by then)
        connected=""
        for _ in $(seq 1 120); do
          if $nmcli -g GENERAL.STATE device show ${tunIface} 2>/dev/null | grep -q "^100"; then
            connected=1
            break
          fi
          sleep 1
        done
        if [ -z "$connected" ]; then
          echo "Warning: ${tunIface} never connected, split DNS not configured" >&2
          exit 1
        fi

        # Reassert whenever the internal server drops off the link, until the
        # tunnel goes away
        while ${pkgs.iproute2}/bin/ip link show ${tunIface} &>/dev/null; do
          if ! $nmcli -g IP4.DNS device show ${tunIface} 2>/dev/null | grep -qF "${cfg.dns.server}"; then
            apply_dns
            echo "Split DNS active: ${lib.concatStringsSep ", " cfg.dns.domains} -> ${cfg.dns.server}"
          fi
          sleep 15
        done
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

    # Split DNS (routing domains like ~puzzel.com) needs systemd-resolved as
    # NetworkManager's DNS backend
    services.resolved.enable = lib.mkIf (cfg.dns.server != null) true;
    networking.networkmanager.dns = lib.mkIf (cfg.dns.server != null) "systemd-resolved";
  };
}
