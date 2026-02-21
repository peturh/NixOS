# NixOS Configuration Context

This document provides context about this NixOS configuration that isn't immediately obvious from reading the Nix code.

## Hardware

This config manages **3 ThinkPad laptops**, each with different hardware and slightly different software sets. Per-host configuration lives in `hosts/<hostname>/configuration.nix`, with shared config in `hosts/common.nix`.

| Machine | GPU | Video Driver | Role |
| ------- | --- | ------------ | ---- |
| **T14s** | AMD | amdgpu | Primary work machine (Intune, VPN, WWAN, Logitech, 8BitDo) |
| **T470p** | Nvidia | nvidia | Personal / secondary |
| **T450** | Intel | intel | Personal / secondary |

- **CPU Scheduler**: scx_lavd (sched-ext rust scheduler for responsiveness)
- **Kernel**: linux-zen for better desktop performance
- **T14s peripherals**: Logitech wireless devices (Solaar), 8BitDo controller, WWAN modem

### Per-Host Differences

| Feature | T14s | T470p | T450 |
| ------- | ---- | ----- | ---- |
| Browser (default) | Microsoft Edge | Google Chrome | Google Chrome |
| Microsoft Intune | Yes | No | No |
| Check Point VPN (cpyvpn) | Yes | No | No |
| WWAN / Modem | Yes | No | No |
| Logitech / Solaar | Yes | No | No |
| 8BitDo controller | Yes | No | No |
| Porttelefon | Yes | No | No |
| Webengage Release | Yes | No | No |
| Work hosts file | Yes | No | No |

All three share: Hyprland, Kitty, Cursor, Firefox, Chrome, Steam, Docker, and the full CLI/media/misc module set.

### Known Quirks / Workarounds
- T14s: `amdgpu.dcdebugmask=0x10` kernel param for AMD display

## Workflow

- **Primary Use**: T14s is the work development machine; T470p and T450 are personal
- **Languages**: Node.js, Python 3, Go
- **Containerization**: Docker enabled on all machines
- **Work Tools** (T14s only):
  - VPN via cpyvpn (Check Point VPN)
  - Microsoft Intune for device management
  - Jira and Azure DevOps (credentials in sops secrets)
  - Slack, Signal for communication

### Typical Commands
- Rebuild: `SUPER+U` launches `scripts/rebuild.sh` in Kitty, which runs `sudo nixos-rebuild switch --flake ~/NixOS#<hostname>`
- Update flake inputs: `nix flake update`
- Garbage collection: Automatic via nh (keeps 7 days, 3 generations)

## Conventions

### Module Organization
- **Hardware modules**: `modules/hardware/` (video, audio, networking)
- **Desktop environments**: `modules/desktop/` (hyprland, gnome, i3-gaps)
- **Programs**: `modules/programs/` organized by category:
  - `browser/` - web browsers
  - `cli/` - command-line tools
  - `development/` - dev toolchains
  - `editor/` - code editors
  - `gaming/` - games
  - `media/` - media apps
  - `misc/` - utilities
  - `security/` - VPN, Intune
  - `shell/` - bash, zsh configs
  - `terminal/` - terminal emulators
- **Themes**: `modules/themes/` with wallpapers
- **Custom packages**: `pkgs/` for packages not in nixpkgs
- **Overlays**: `overlays/` for package modifications

### Multi-Host Architecture
- `flake.nix` defines `commonSettings` shared by all hosts, with per-host overrides in `hostSettings`
- Each host has its own `hosts/<name>/configuration.nix` that imports the modules it needs
- T14s imports work-specific modules (Intune, cpyvpn, WWAN, etc.) that the other two don't
- The `browser` setting is `"microsoft-edge"` for T14s and `"google-chrome"` for T470p/T450
- When adding a package to all machines, add it to `hosts/common.nix`; for a specific machine, add it to that host's `configuration.nix`

### Installing New Packages
When I ask for you to install new application and packages:
1. Search for the application on `nixpkgs`. 
   1. Createa new flake for the installation
   2. Make it avaialble directly so I can use it.
2. If you cant find it on `nixpkgs`, install it from source on github.
   1. Create the derivation in `pkgs/<name>.nix`
   2. Register it in `pkgs/default.nix` via `callPackage`
   3. **Always** add it to `environment.systemPackages` in `hosts/common.nix` so it's actually available

### Flake Settings
Central configuration in `flake.nix` under `settings`:
- `username`, `editor`, `browser`, `terminal` - easily swappable
- `videoDriver`, `hostname`, locale settings - system-level
- Per-host overrides in `hostSettings` (e.g. browser, videoDriver)

### Home-Manager vs System
- Currently: Most program configs are home-manager, services are system-level

## Known Pain Points

_Fill in issues you frequently encounter:_
- 
- 
- 

## Future Goals

- Going through shared modules, home modules and other things to make the installation prettier
- 

## Quick Reference

| Item            | Value                                             |
| --------------- | ------------------------------------------------- |
| Config location | `~/NixOS`                                         |
| Rebuild command | `SUPER+U` → `rebuild.sh` → `nixos-rebuild switch` |
| Formatter       | Alejandra                                         |
| Secrets         | sops-nix with age key at `~/NixOS/age.key`        |
| State version   | 23.11                                             |
| Nixpkgs channel | unstable                                          |
| Hosts           | t14s (AMD), t470p (Nvidia), t450 (Intel)          |

### Current Preferences (from flake.nix)
- **Editor**: Cursor
- **Browser**: Microsoft Edge on T14s, Google Chrome on T470p/T450 (Firefox also installed on all)
- **Terminal**: Kitty
- **File Manager**: Yazi
- **Shell**: zsh with Starship prompt
- **Theme/Wallpaper**: thinkpad
- **SDDM Theme**: purple_leaves
