{pkgs, ...}: let
  # Script to suspend only when on battery (after 15 min idle)
  suspendOnBattery = pkgs.writeShellScript "suspend-on-battery" ''
    # Check if on AC power
    if cat /sys/class/power_supply/AC*/online 2>/dev/null | grep -q 1; then
      # On AC power - never suspend from idle
      exit 0
    else
      # On battery - suspend
      systemctl suspend
    fi
  '';
in {
  home-manager.sharedModules = [
    (_: {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            ignore_dbus_inhibit = false;
            # Drive DMS's lock via its IPC. dms.service is started by
            # hyprland-session.target, so its IPC socket is up well before
            # any of these timers can fire.
            lock_cmd = "dms ipc call lock lock";
            unlock_cmd = "dms ipc call lock unlock";
            before_sleep_cmd = "dms ipc call lock lock";
            after_sleep_cmd = "sleep 1 && hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
          };
          listener = [
            {
              timeout = 300; # 5 Minutes - lock screen (both AC and battery)
              on-timeout = "dms ipc call lock lock";
            }
            {
              timeout = 600; # 10 Minutes - turn off display (both AC and battery)
              on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
              on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
            }
            {
              timeout = 900; # 15 Minutes - suspend ONLY on battery
              on-timeout = "${suspendOnBattery}";
            }
          ];
        };
      };
    })
  ];

  # Handle lid close - always suspend (both AC and battery)
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend"; # Close lid = always suspend
    HandleLidSwitchDocked = "ignore"; # When docked: keep running
    HandleLidSwitchExternalPower = "suspend"; # On AC with lid closed = suspend
  };
}
