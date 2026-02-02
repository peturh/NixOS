{pkgs, ...}: {
  # Work-related host entries for internal services
  networking.extraHosts = ''
    10.47.26.11 app-kibana.puzzel.com
    172.16.200.21 grafana.prod.local
    10.47.30.48 p1elk01.prod.local
    172.16.151.11 devapp-kibana.puzzel.com
    10.7.24.10 uk-kibana.puzzel.com
    10.47.26.11 unleash.prod.local
  '';

  # ModemManager configuration for WWAN
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = true;

  # Persistent mobile broadband connection (survives rebuilds)
  networking.networkmanager.ensureProfiles.profiles = {
    "Telenor WWAN" = {
      connection = {
        id = "Telenor WWAN";
        type = "gsm";
        autoconnect = "false";
      };
      gsm = {
        apn = "internet.telenor.se";
      };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        method = "auto";
      };
    };
  };

  # Enable debug logging for FCC unlock script
  systemd.services.ModemManager.environment = {
    FCC_UNLOCK_DEBUG_LOG = "1";
  };

  # Auto-register modem with Telenor after boot
  systemd.services.wwan-auto-register = {
    description = "Auto-register WWAN modem with Telenor";
    after = [ "ModemManager.service" "network.target" ];
    wants = [ "ModemManager.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10"; # Wait for modem to initialize
      ExecStart = pkgs.writeShellScript "wwan-register" ''
        # Wait for modem to be available
        for i in $(seq 1 30); do
          if ${pkgs.modemmanager}/bin/mmcli -L 2>/dev/null | grep -q "Modem"; then
            break
          fi
          sleep 2
        done
        
        # Enable modem if disabled
        ${pkgs.modemmanager}/bin/mmcli -m 0 --enable 2>/dev/null || true
        sleep 3
        
        # Register with Telenor (24008)
        ${pkgs.modemmanager}/bin/mmcli -m 0 --3gpp-register-in-operator=24008 2>/dev/null || true
        
        echo "WWAN modem registered"
      '';
    };
  };

  # FCC unlock script for Lenovo WWAN module
  networking.modemmanager.fccUnlockScripts = [
    {
      id = "8086:7560"; 
      path = "${pkgs.lenovo-wwan-unlock}/bin/fcc_unlock.sh";
    }
  ];

  # Samba client support for network shares
  services.samba.enable = true;

  # Avahi for local network service discovery (printers, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}

