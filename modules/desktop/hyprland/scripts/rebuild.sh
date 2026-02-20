#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [[ $EUID -eq 0 ]]; then
  echo "This script should not be executed as root! Exiting..."
  exit 1
fi

if [[ ! "$(grep -i nixos </etc/os-release)" ]]; then
  echo "This installation script only works on NixOS! Download an iso at https://nixos.org/download/"
  echo "Keep in mind that this script is not intended for use while in the live environment."
  exit 1
fi

if [ -f "$HOME/NixOS/flake.nix" ]; then
  flake=$HOME/NixOS
elif [ -f "/etc/nixos/flake.nix" ]; then
  flake=/etc/nixos
else
  echo "Error: flake not found. ensure flake.nix exists in either $HOME/NixOS or /etc/nixos"
  exit 1
fi
echo -e "${GREEN}Rebuilding from $flake${NC}"
currentUser=$(logname)

# replace username variable in flake.nix with $USER
sudo sed -i -e "s/username = \".*\"/username = \"$currentUser\"/" "$flake/flake.nix"

hostName=$(hostname)
hostDir="$flake/hosts/$hostName"
if [ ! -d "$hostDir" ]; then
  echo -e "${RED}No host config for '$hostName'. Available hosts:${NC}"
  hosts=($(ls -d "$flake"/hosts/*/configuration.nix 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {}))
  for i in "${!hosts[@]}"; do
    echo "  $((i+1))) ${hosts[$i]}"
  done
  while true; do
    read -p "Select host (1-${#hosts[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#hosts[@]}" ]; then
      hostName="${hosts[$((choice-1))]}"
      hostDir="$flake/hosts/$hostName"
      break
    fi
    echo "Invalid choice."
  done
fi

if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
  cat "/etc/nixos/hardware-configuration.nix" | sudo tee "$hostDir/hardware-configuration.nix" >/dev/null
else
  sudo nixos-generate-config --show-hardware-config | sudo tee "$hostDir/hardware-configuration.nix" >/dev/null
fi

sudo git -C "$flake" add "$hostDir/hardware-configuration.nix"

sudo nixos-rebuild switch --flake "$flake#$hostName"

echo
read -rsn1 -p"$(echo -e "${GREEN}Press any key to continue${NC}")"
