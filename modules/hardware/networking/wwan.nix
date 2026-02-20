{pkgs, ...}: {
  # ModemManager configuration for WWAN
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
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      ExecStart = pkgs.writeShellScript "wwan-register" ''
        for i in $(seq 1 30); do
          if ${pkgs.modemmanager}/bin/mmcli -L 2>/dev/null | grep -q "Modem"; then
            break
          fi
          sleep 2
        done
        
        ${pkgs.modemmanager}/bin/mmcli -m 0 --enable 2>/dev/null || true
        sleep 3
        
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
}
