# ~/NixOS/modules/security/cpyvpn.nix

{ config, lib, pkgs, ... }:

let
  cfg = config.services.cpyvpn;
in
{
  # The options section is now much simpler!
  options.services.cpyvpn = {
    enable = lib.mkEnableOption "the CPYVPN client service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cpyvpn;
      description = "The cpyvpn package to use.";
    };

    # This is the important change. We now expect a path to the config file.
    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the cpyvpn configuration file. This can be provided by sops-nix.";
      example = "/run/secrets/cpyvpn-config";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the package
    environment.systemPackages = [ cfg.package ];

    # The systemd service is now cleaner, just pointing to the configFile path
    systemd.services.cpyvpn = {
      description = "CPYVPN Client Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        User = "root";
        Group = "root";
        Type = "simple";
        # It now uses the configFile path directly
        ExecStart = "${cfg.package}/bin/cpyvpn --config ${cfg.configFile}";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}