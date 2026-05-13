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

YELLOW='\033[1;33m'

# Run nixos-rebuild switch; if the pre-switch inhibitor blocks it (e.g. a
# dbus/systemd/init swap that can't be done live), fall back to `boot` and
# offer to reboot. We tee stderr so we can both show it to the user and
# inspect it for the inhibitor message.
rebuild_log=$(mktemp)
trap 'rm -f "$rebuild_log" ; stty sane 2>/dev/null || true' EXIT

# Refresh the sudo timestamp now, with a clean tty. If we let sudo prompt
# for the password from inside the `2> >(tee ...)` process substitution
# below, sudo's tty handling can leave the terminal in `-onlcr` mode,
# which produces staircased output for everything that follows.
sudo -v

if sudo nixos-rebuild switch --flake "$flake#$hostName" 2> >(tee "$rebuild_log" >&2); then
  switch_ok=1
else
  switch_ok=0
fi

# Defensive: ensure the terminal is back in a sane state in case the
# password prompt above (or anything else) left it in raw mode.
stty sane 2>/dev/null || true

if [ "$switch_ok" -eq 0 ] && grep -q -E "switchInhibitors|Pre-switch check" "$rebuild_log"; then
  echo
  echo -e "${YELLOW}Live switch was blocked by a critical-component change.${NC}"
  echo -e "${YELLOW}Staging the new configuration for next boot instead...${NC}"
  if sudo nixos-rebuild boot --flake "$flake#$hostName"; then
    echo
    read -rp "$(echo -e "${YELLOW}Reboot now to activate the new configuration? [y/N] ${NC}")" answer
    case "$answer" in
      [yY]|[yY][eE][sS]) sudo systemctl reboot ;;
      *) echo -e "${GREEN}New configuration will activate on next reboot.${NC}" ;;
    esac
  else
    echo -e "${RED}nixos-rebuild boot also failed. See output above.${NC}"
    exit 1
  fi
elif [ "$switch_ok" -eq 0 ]; then
  exit 1
fi

echo
read -rsn1 -p"$(echo -e "${GREEN}Press any key to continue${NC}")"
