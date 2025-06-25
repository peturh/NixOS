
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.converse;
in
{
  # Defines the options that you can set
  options.programs.converse = {
    enable = lib.mkEnableOption "the converse GUI application";

    settings = {
      api_key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "API key for the model provider. WARNING: Insecure, use a secrets tool.";
      };
      model_provider = lib.mkOption {
        type = lib.types.enum [ "gemini" "cohere" "claude" "openai" ];
        default = "gemini";
        description = "The Large Language Model provider to use.";
      };
      model = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "The specific model to use (e.g., \"gemini-pro\").";
      };
      theme = lib.mkOption {
        type = lib.types.enum [ "light" "dark" ];
        default = "dark";
        description = "The color theme for the application.";
      };
    };
  };

  # Applies the configuration if enabled
  config = lib.mkIf cfg.enable {
    # Installs the package built by your overlay
    environment.systemPackages = [ pkgs.converse ];

    # Generates the config.toml file from your settings
    environment.etc."converse/config.toml" = {
      source = (pkgs.formats.toml {}).generate "converse-config.toml" cfg.settings;
      mode = "0444"; # Read-only
    };
  };
}