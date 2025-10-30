{ config, lib, pkgs, ... }:

let
  cfg = config.programs.webengage-release;
  
  # Create a wrapper script that reads secrets and runs the Docker container
  webengageReleaseScript = pkgs.writeShellScriptBin "webengage-release" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Read secrets from sops
    JIRA_USERNAME=$(cat /run/secrets/jira-username)
    JIRA_PASSWORD=$(cat /run/secrets/jira-password)
    DEVOPS_USERNAME=$(cat /run/secrets/devops-username)
    DEVOPS_PASSWORD=$(cat /run/secrets/devops-password)
    
    # Pull the latest Docker image
    echo "Pulling latest Docker image..."
    ${pkgs.docker}/bin/docker pull vergicbackend.azurecr.io/puzzel-create-jira-release
    
    # Create a temporary directory and YAML file
    TEMP_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
    TEMP_YAML="$TEMP_DIR/jira-release-secure.yaml"
    
    # Cleanup function
    cleanup() {
      rm -rf "$TEMP_DIR"
    }
    trap cleanup EXIT
    
    # Create the YAML file with credentials
    cat > "$TEMP_YAML" <<EOF
jira_username: $JIRA_USERNAME
jira_password: $JIRA_PASSWORD
devops_username: $DEVOPS_USERNAME
devops_password: $DEVOPS_PASSWORD
EOF
    
    # Run the Docker container
    echo "Starting Jira release container..."
    ${pkgs.docker}/bin/docker run \
      --volume "$TEMP_YAML:/root/.secure/jira-release-secure.yaml" \
      --interactive \
      --tty \
      --rm \
      vergicbackend.azurecr.io/puzzel-create-jira-release \
      --interactive \
      "$@"
  '';
in
{
  options.programs.webengage-release = {
    enable = lib.mkEnableOption "the webengage-release Jira release tool wrapper";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = webengageReleaseScript;
      description = "The webengage-release package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the wrapper script
    environment.systemPackages = [ 
      cfg.package
    ];
    
    # Ensure Docker is available
    assertions = [
      {
        assertion = config.virtualisation.docker.enable;
        message = "webengage-release requires Docker to be enabled. Set virtualisation.docker.enable = true;";
      }
    ];
  };
}

