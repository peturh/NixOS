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
            lock_cmd = "pidof hyprlock || hyprlock";
            unlock_cmd = "pkill --signal SIGUSR1 hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "sleep 1 && hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300; # 5 Minutes - lock screen (both AC and battery)
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 600; # 10 Minutes - turn off display (both AC and battery)
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
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
    HandleLidSwitch = "suspend";              # Close lid = always suspend
    HandleLidSwitchDocked = "ignore";         # When docked: keep running
    HandleLidSwitchExternalPower = "suspend"; # On AC with lid closed = suspend
  };
}
