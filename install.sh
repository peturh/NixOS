#!/usr/bin/env bash

# If in the live environment then start the live-install.sh script
if [ -d "/iso" ] || [ "$(findmnt -o FSTYPE -n /)" = "tmpfs" ]; then
  sudo ./live-install.sh
  exit 0
fi

# Check if running as root. If root, script will exit.
if [[ $EUID -eq 0 ]]; then
  echo "This script should not be executed as root! Exiting..."
  exit 1
fi

# Check if using NixOS. If not using NixOS, script will exit.
if [[ ! "$(grep -i nixos </etc/os-release)" ]]; then
  echo "This installation script only works on NixOS! Download an iso at https://nixos.org/download/"
  echo "You can either use this script in the live environment or booted into a system."
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

currentUser=$(logname)

# Delete dirs that conflict with home-manager (skip symlinks)
paths=(
  ~/.mozilla/firefox/profiles.ini
  ~/.zen/profiles.ini
  ~/.gtkrc-*
  ~/.config/gtk-*
  ~/.config/cava
)
for file in "${paths[@]}"; do
  for expanded in $file; do
    if [ -e "$expanded" ] && [ ! -L "$expanded" ]; then
      # echo "Removing: $expanded"
      sudo rm -rf "$expanded"
    fi
  done
done

# replace username variable in flake.nix with $USER
sudo sed -i -e "s/username = \".*\"/username = \"$currentUser\"/" "./flake.nix"

hostName=$(hostname)
hostDir="./hosts/$hostName"
if [ ! -d "$hostDir" ]; then
  echo -e "${RED}No host config for '$hostName'. Available hosts:${NC}"
  hosts=($(ls -d ./hosts/*/configuration.nix 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {}))
  for i in "${!hosts[@]}"; do
    echo "  $((i+1))) ${hosts[$i]}"
  done
  while true; do
    read -p "Select host (1-${#hosts[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#hosts[@]}" ]; then
      hostName="${hosts[$((choice-1))]}"
      hostDir="./hosts/$hostName"
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

sudo git -C . add "$hostDir/hardware-configuration.nix"

sudo nixos-rebuild switch --flake ".#$hostName" && \
    echo -e "${GREEN}Success!${NC}" && \
    echo "Make sure to reboot if this is your first time using this script!" || \
    exit 1
