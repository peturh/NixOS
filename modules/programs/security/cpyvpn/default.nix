# ~/NixOS/modules/security/cpyvpn.nix
# This module provides the configuration for the cpyvpn service.

{ config, lib, pkgs, ... }:

let
  # A shortcut to the options we are about to define
  cfg = config.services.cpyvpn;

  # This function formats the settings into the key = value format cpyvpn expects
  format = pkgs.formats.keyValue {
    mkKeyValue = key: value: "${key} = ${toString value}";
  };

  # Generate the configuration file from the settings
  configFile = format.generate "cpyvpn.conf" cfg.settings;
in
{
  # This section defines the user-friendly options for your configuration
  options.services.cpyvpn = {
    enable = lib.mkEnableOption "the CPYVPN client service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cpyvpn;
      description = "The cpyvpn package to use.";
    };

    settings = {
      server = lib.mkOption {
        type = lib.types.str;
        example = "vpn.mycompany.com";
        description = "The hostname or IP address of the VPN server.";
      };
      username = lib.mkOption {
        type = lib.types.str;
        description = "The username for the VPN connection.";
      };
      password = lib.mkOption {
        type = lib.types.str;
        description = "The password for the VPN connection. WARNING: Stored in plaintext in the Nix store.";
        # In a real-world scenario, you would use `sops-nix` or another secrets management tool.
      };
      # You can add other options from the cpyvpn documentation here
    };
  };

  # This section activates when you set 'services.cpyvpn.enable = true;'
  config = lib.mkIf cfg.enable {
    # 1. Install the package to the system profile
    environment.systemPackages = [ cfg.package ];

    # 2. Create a systemd service to run the VPN daemon
    systemd.services.cpyvpn = {
      description = "CPYVPN Client Service";
      wantedBy = [ "multi-user.target" ]; # Start on boot
      after = [ "network.target" ];     # Wait for network to be up

      serviceConfig = {
        # The VPN client needs root privileges to manage network interfaces
        User = "root";
        Group = "root";
        Type = "simple";
        # The command to run, pointing to the generated config file
        ExecStart = "${cfg.package}/bin/cpyvpn --config ${configFile}";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}