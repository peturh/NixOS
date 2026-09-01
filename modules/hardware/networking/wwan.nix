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

  # Upstream ModemManager.service is only dbus-activated / pulled in by other
  # units' Wants. Without a real install link, switch-to-configuration stops
  # it on rebuild (when the unit changes) and nothing starts it again — the
  # DMS widget then reports "ModemManager sees no device" until reboot.
  systemd.services.ModemManager.wantedBy = ["multi-user.target"];

  # Auto-register modem with Telenor after boot
  systemd.services.wwan-auto-register = {
    description = "Auto-register WWAN modem with Telenor";
    after = ["ModemManager.service" "network.target"];
    wants = ["ModemManager.service"];
    wantedBy = ["multi-user.target"];

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

        # -m any, not -m 0: the modem's D-Bus index bumps every time MM
        # rediscovers the device (sleep detach/reattach, MM restart).
        ${pkgs.modemmanager}/bin/mmcli -m any --enable 2>/dev/null || true
        sleep 3

        # Automatic registration (despite the flag name): picks Telenor SE at
        # home and a roaming partner abroad. Forcing 24008 here would break
        # registration outside Sweden.
        ${pkgs.modemmanager}/bin/mmcli -m any --3gpp-register-home 2>/dev/null || true

        echo "WWAN modem registered"
      '';
    };
  };

  # The iosm driver (Intel XMM7560) is unstable across s2idle: it asserts the
  # GPIO 9 wake line (aborting suspend / draining battery) and can hard-freeze
  # the system on resume ("iosm: msg timeout"). Detach the PCI device before
  # any sleep and rescan it back on resume.
  systemd.services.wwan-sleep-detach = {
    description = "Detach WWAN modem (iosm) around sleep";
    before = ["sleep.target"];
    wantedBy = ["sleep.target"];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
      TimeoutStopSec = 120;
      ExecStart = pkgs.writeShellScript "wwan-detach" ''
        ${pkgs.coreutils}/bin/timeout 15 ${pkgs.modemmanager}/bin/mmcli -m any --disable 2>/dev/null || true
        for d in /sys/bus/pci/devices/*; do
          if [ "$(${pkgs.coreutils}/bin/cat "$d/vendor")" = "0x8086" ] \
            && [ "$(${pkgs.coreutils}/bin/cat "$d/device")" = "0x7560" ]; then
            # remember the parent bridge so reattach can rescan just that port
            ${pkgs.coreutils}/bin/readlink -f "$d/.." > /run/wwan-detach-bridge
            echo 1 > "$d/remove"
          fi
        done
      '';
      ExecStop = pkgs.writeShellScript "wwan-reattach" ''
        bridge=$(${pkgs.coreutils}/bin/cat /run/wwan-detach-bridge 2>/dev/null)
        if [ -n "$bridge" ] && [ -e "$bridge/rescan" ]; then
          # wake the bridge out of runtime PM before asking it to rescan
          echo on > "$bridge/power/control" 2>/dev/null || true
          ${pkgs.coreutils}/bin/timeout 20 ${pkgs.bash}/bin/sh -c "echo 1 > '$bridge/rescan'" || true
          echo auto > "$bridge/power/control" 2>/dev/null || true
        else
          ${pkgs.coreutils}/bin/timeout 20 ${pkgs.bash}/bin/sh -c 'echo 1 > /sys/bus/pci/rescan' || true
        fi
        # MM may have died or been left stopped (e.g. a rebuild while asleep);
        # make sure it's up before waiting for it to rediscover the modem.
        ${pkgs.systemd}/bin/systemctl start ModemManager.service 2>/dev/null || true
        for i in $(${pkgs.coreutils}/bin/seq 1 15); do
          if ${pkgs.coreutils}/bin/timeout 5 ${pkgs.modemmanager}/bin/mmcli -L 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "/Modem/"; then
            break
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done
        # Enable can hit "Invalid transition" while the modem is still
        # initializing after the PCI rescan — retry a few times.
        for i in $(${pkgs.coreutils}/bin/seq 1 5); do
          if ${pkgs.coreutils}/bin/timeout 20 ${pkgs.modemmanager}/bin/mmcli -m any --enable 2>/dev/null; then
            break
          fi
          ${pkgs.coreutils}/bin/sleep 3
        done
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
