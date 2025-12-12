{ config, lib, pkgs, ... }:

let
  cfg = config.programs.porttelefon;

  # Bundle the Dockerfile and JNLP into a derivation
  porttelefon-docker-src = pkgs.stdenv.mkDerivation {
    name = "porttelefon-docker-src";
    src = ./.;
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out
      cp $src/Dockerfile $out/
      cp $src/vaka-Brf_Brita_6.jnlp $out/
    '';
  };

  # Script to launch the porttelefon application
  porttelefon-script = pkgs.writeShellScriptBin "porttelefon" ''
    #!/usr/bin/env bash
    set -euo pipefail

    IMAGE_NAME="porttelefon"
    CONTAINER_NAME="porttelefon"
    VNC_PORT="5900"

    cleanup() {
      echo "Stopping porttelefon container..."
      ${pkgs.docker}/bin/docker stop "$CONTAINER_NAME" 2>/dev/null || true
      ${pkgs.docker}/bin/docker rm "$CONTAINER_NAME" 2>/dev/null || true
    }

    # Set up cleanup on exit
    trap cleanup EXIT

    # Build the Docker image if it doesn't exist
    if ! ${pkgs.docker}/bin/docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
      echo "Building porttelefon Docker image (this may take a few minutes)..."
      ${pkgs.docker}/bin/docker build -t "$IMAGE_NAME" "${porttelefon-docker-src}"
    fi

    # Remove any existing container
    ${pkgs.docker}/bin/docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

    # Start the container
    echo "Starting porttelefon container..."
    ${pkgs.docker}/bin/docker run -d \
      --name "$CONTAINER_NAME" \
      -p "$VNC_PORT:5900" \
      "$IMAGE_NAME"

    # Wait a moment for container to initialize
    sleep 2

    # Verify container is running
    if ! ${pkgs.docker}/bin/docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
      echo "ERROR: Container failed to start. Checking logs..."
      ${pkgs.docker}/bin/docker logs "$CONTAINER_NAME" 2>&1 || true
      echo ""
      echo "Container status:"
      ${pkgs.docker}/bin/docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.Status}}\t{{.Ports}}"
      exit 1
    fi

    echo "Container is running. Waiting for VNC server to be ready..."

    # Wait for VNC to be ready with timeout
    VNC_READY=false
    for i in $(seq 1 60); do
      # Check if container is still running
      if ! ${pkgs.docker}/bin/docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "ERROR: Container stopped unexpectedly. Logs:"
        ${pkgs.docker}/bin/docker logs "$CONTAINER_NAME" 2>&1 || true
        exit 1
      fi

      if ${pkgs.netcat}/bin/nc -z localhost "$VNC_PORT" 2>/dev/null; then
        echo "VNC server is ready!"
        VNC_READY=true
        break
      fi
      echo "Waiting for VNC... ($i/60)"
      sleep 1
    done

    if [ "$VNC_READY" = false ]; then
      echo "ERROR: VNC server did not become ready in time."
      echo "Container logs:"
      ${pkgs.docker}/bin/docker logs "$CONTAINER_NAME" 2>&1 || true
      exit 1
    fi

    # Give it a moment to fully initialize
    sleep 2

    # Launch Remmina with VNC connection
    echo "Launching Remmina..."
    ${pkgs.remmina}/bin/remmina -c vnc://localhost:"$VNC_PORT"

    # Cleanup happens via trap on exit
  '';

  # Desktop entry for the application
  porttelefon-desktop = pkgs.makeDesktopItem {
    name = "porttelefon";
    desktopName = "Porttelefon";
    comment = "Vaka-Brf Brita 6 Door Phone System";
    exec = "${porttelefon-script}/bin/porttelefon";
    icon = "phone";
    terminal = false;
    type = "Application";
    categories = [ "Network" "Utility" ];
  };

in
{
  options.programs.porttelefon = {
    enable = lib.mkEnableOption "the Porttelefon door phone application";
  };

  config = lib.mkIf cfg.enable {
    # Ensure Docker is available
    virtualisation.docker.enable = true;

    # Install the script and desktop entry
    environment.systemPackages = [
      porttelefon-script
      porttelefon-desktop
      pkgs.remmina
      pkgs.netcat
    ];
  };
}

