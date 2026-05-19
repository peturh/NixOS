{pkgs, ...}: {
  # Valent — GNOME-platform-libraries reimplementation of the KDE Connect
  # protocol. Installed so DMS's first-party "Phone Connect" plugin
  # (DankKDEConnect, see https://github.com/AvengeMedia/dms-plugins/tree/master/DankKDEConnect)
  # has a D-Bus service to talk to. The plugin discovers Valent on the
  # session bus (name `ca.andyholmes.Valent`) and exposes phone battery,
  # notifications, clipboard sync, and file transfer in the bar.
  #
  # Why Valent and not `kdePackages.kdeconnect-kde`: kdeconnect-kde pulls
  # most of the Plasma stack (kio, plasma-framework, kirigami, …) into
  # the closure. Valent provides the same protocol via GLib/libsoup and
  # is a much smaller dependency footprint on a non-Plasma system.
  #
  # No firewall rules are needed here — KDE Connect/Valent uses UDP/TCP
  # 1714–1764, and `networking.firewall.enable = false` in hosts/common.nix
  # already lets that through. If the firewall is ever re-enabled, add:
  #   networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  #   networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  #
  # Valent ships a `ca.andyholmes.Valent.service` D-Bus activation file
  # and a `DBusActivatable=true` .desktop file, but neither is enough on
  # its own here: DankKDEConnect calls `dbusListNames("session", …)` and
  # only looks for names that are *already* on the bus — it doesn't
  # request the name, so D-Bus activation never fires and the plugin
  # permanently reports "Phone Connect unavailable".
  #
  # Fix: run `valent --gapplication-service` as a user systemd unit
  # wanted by `graphical-session.target` (Hyprland pulls that target up
  # via `wayland.windowManager.hyprland.systemd.enable = true` in
  # modules/desktop/hyprland/default.nix). This guarantees the well-known
  # name `ca.andyholmes.Valent` is on the session bus by the time DMS
  # starts and runs `detectBackend()`.
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        valent
      ];

      systemd.user.services.valent = {
        Unit = {
          Description = "Valent — KDE Connect-compatible device bridge";
          Documentation = ["https://valent.andyholmes.ca/"];
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "dbus";
          BusName = "ca.andyholmes.Valent";
          ExecStart = "${pkgs.valent}/bin/valent --gapplication-service";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    })
  ];
}
