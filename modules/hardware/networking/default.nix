{...}: {
  networking.networkmanager.enable = true;

  # Samba client support for network shares
  services.samba.enable = true;

  # Avahi for local network service discovery (printers, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
