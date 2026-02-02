# NixOS Configuration Context

This document provides context about this NixOS configuration that isn't immediately obvious from reading the Nix code.

## Hardware

- **Machine**: ThinkPad (model: _fill in your specific model_)
- **GPU**: AMD (using amdgpu driver)
- **CPU Scheduler**: scx_lavd (sched-ext rust scheduler for responsiveness)
- **Kernel**: linux-zen for better desktop performance
- **Peripherals**: Logitech wireless devices (Solaar for management)

### Known Quirks / Workarounds
- `amd_pmc.enable_stb=1` kernel param enables System Trace Buffer for better AMD s2idle suspend/resume
- _Add any suspend/resume issues you've encountered_
- _Add any hardware that needed special configuration_

## Workflow

- **Primary Use**: Work development machine (_confirm if also personal use_)
- **Languages**: Node.js, Python 3, Go
- **Containerization**: Docker enabled
- **Work Tools**: 
  - VPN via cpyvpn (Check Point VPN)
  - Microsoft Intune for device management
  - Jira and Azure DevOps (credentials in sops secrets)
  - Slack, Signal for communication

### Typical Commands
- Rebuild: `nh os switch` (flake at `~/NixOS`)
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

### Flake Settings
Central configuration in `flake.nix` under `settings`:
- `username`, `editor`, `browser`, `terminal` - easily swappable
- `videoDriver`, `hostname`, locale settings - system-level

### Home-Manager vs System
- _Add your preference: when do you use home-manager vs system config?_
- Currently: Most program configs are home-manager, services are system-level

## Known Pain Points

_Fill in issues you frequently encounter:_
- 
- 
- 

## Future Goals

_What are you planning to change or add?_
- 
- 
- 

## Quick Reference

| Item            | Value                                      |
| --------------- | ------------------------------------------ |
| Config location | `~/NixOS`                                  |
| Rebuild command | `nh os switch`                             |
| Formatter       | Alejandra                                  |
| Secrets         | sops-nix with age key at `~/NixOS/age.key` |
| State version   | 23.11                                      |
| Nixpkgs channel | unstable                                   |

### Current Preferences (from flake.nix)
- **Editor**: Cursor
- **Browser**: Microsoft Edge (Firefox, Chrome also installed)
- **Terminal**: Kitty
- **File Manager**: Yazi
- **Shell**: zsh with Starship prompt
- **Theme/Wallpaper**: thinkpad
- **SDDM Theme**: purple_leaves
