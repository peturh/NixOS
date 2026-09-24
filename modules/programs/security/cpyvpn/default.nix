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
      # server. cp_client pushes the gateway-provided DNS onto the link shortly
      # after the interface appears and would overwrite anything set earlier,
      # so wait for that push, override it, and reassert for a while.
      # resolved drops this per-link config when the tunnel goes down.
      (
        our_domains="${lib.concatMapStringsSep " " (d: "~${d}") cfg.dns.domains}"

        apply_dns() {
          # Keep gateway-pushed search domains (our server serves those zones
          # too), but drop duplicates of our own routing domains.
          keep=""
          for d in $(${pkgs.systemd}/bin/resolvectl domain ${tunIface} 2>/dev/null | cut -d: -f2-); do
            case " $our_domains " in
              *" $d "*) ;;
              *) keep="$keep $d" ;;
            esac
          done
          ${pkgs.systemd}/bin/resolvectl dns ${tunIface} ${cfg.dns.server}
          ${pkgs.systemd}/bin/resolvectl domain ${tunIface} $keep $our_domains
          ${pkgs.systemd}/bin/resolvectl default-route ${tunIface} false
        }

        up=""
        for _ in $(seq 1 60); do
          if ${pkgs.iproute2}/bin/ip link show ${tunIface} &>/dev/null; then
            up=1
            break
          fi
          sleep 1
        done
        if [ -z "$up" ]; then
          echo "Warning: ${tunIface} never appeared, split DNS not configured" >&2
          exit 1
        fi

        # Wait (briefly) for cp_client's gateway DNS push before overriding it
        for _ in $(seq 1 20); do
          gwdns=$(${pkgs.systemd}/bin/resolvectl dns ${tunIface} 2>/dev/null | cut -d: -f2- | ${pkgs.findutils}/bin/xargs || true)
          [ -n "$gwdns" ] && break
          sleep 1
        done

        apply_dns
        echo "Split DNS active: ${lib.concatStringsSep ", " cfg.dns.domains} -> ${cfg.dns.server}"

        # cp_client may still push gateway DNS after us; watch and reassert
        for _ in $(seq 1 15); do
          sleep 2
          ${pkgs.iproute2}/bin/ip link show ${tunIface} &>/dev/null || exit 0
          current=$(${pkgs.systemd}/bin/resolvectl dns ${tunIface} 2>/dev/null | cut -d: -f2- || true)
          case " $current " in
            *" ${cfg.dns.server} "*) ;;
            *)
              apply_dns
              echo "Split DNS re-applied after gateway DNS overwrite"
              ;;
          esac
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
