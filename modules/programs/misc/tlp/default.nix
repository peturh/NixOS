{pkgs, ...}: {
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave"; # schedutil powersave, ondemand

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power"; #power, balance_power
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;

      # Protect battery
      START_CHARGE_THRESH_BAT0 = 82;
      STOP_CHARGE_THRESH_BAT0 = 95;
      START_CHARGE_THRESH_BAT1 = 82;
      STOP_CHARGE_THRESH_BAT1 = 95;
    };
  };

  # Allow password-less TLP mode toggling for users in the power group
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.policykit.exec" &&
             action.lookup("program") == "${pkgs.tlp}/bin/tlp") &&
            subject.isInGroup("power")) {
            return polkit.Result.YES;
        }
    });
  '';

  # Create power group and add user to it
  users.groups.power = {};
  users.users.petur.extraGroups = ["power"];
}
