#!/usr/bin/env bash

GREEN='\033[0;32m'
NC='\033[0m'

flake=/home/petur/NixOS
hostName=$(hostname)

echo -e "${GREEN}Rebuilding from $flake#$hostName${NC}"
sudo nixos-rebuild switch --flake "$flake#$hostName"
rc=$?

echo
read -rsn1 -p"$(echo -e "${GREEN}Press any key to continue${NC}")"
exit "$rc"
