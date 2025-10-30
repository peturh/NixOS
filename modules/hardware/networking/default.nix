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

  # Enable debug logging for FCC unlock script
  systemd.services.ModemManager.environment = {
    FCC_UNLOCK_DEBUG_LOG = "1";
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

