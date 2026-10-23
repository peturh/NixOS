# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

A more detailed, hand-written context doc lives at `.cursor/context.md` — treat that as the source of truth for project background. This file only summarizes what's needed to act productively.

## Repository purpose

Personal NixOS flake managing **three ThinkPad laptops** from one config:

| Host  | GPU    | Driver  | Role                                                |
| ----- | ------ | ------- | --------------------------------------------------- |
| t14s  | AMD    | amdgpu  | Primary **work** machine (cpyvpn, WWAN, …)         |
| t470p | Nvidia | nvidia  | Personal                                            |
| t450  | Intel  | intel   | Personal                                            |

Work-only tooling (Check Point VPN, WWAN, Logitech/Solaar, 8BitDo, Porttelefon, Webengage release, work hosts file) is imported **only** from `hosts/t14s/configuration.nix`. Do not add those to `hosts/common.nix` or the other two hosts.

## Build / rebuild

- Rebuild current host: `sudo nixos-rebuild switch --flake ~/NixOS#$(hostname)`
- Bound to **`SUPER+U`** in Hyprland → opens Kitty and runs `modules/desktop/hyprland/scripts/rebuild.sh`.
- Update flake inputs: `nix flake update`
- Format: **Alejandra** (`nix fmt` or `alejandra .`) — `formatter` is set in `flake.nix`.

There is no test suite. Verification = a successful `nixos-rebuild`.

## Architecture

### Flake layout

`flake.nix` defines a `commonSettings` attrset (username, browser, terminal, editor, locale, etc.) and a `hostSettings` map that overrides per host (`hostname`, `videoDriver`, `browser`). `mkHost name settings` builds the NixOS system, threading the settings through `specialArgs` so every module receives them as function arguments (e.g. `{ username, browser, videoDriver, ... }:`).

Adding a new setting means: add it to `commonSettings`, optionally override in `hostSettings`, and destructure it where consumed.

### Module imports happen at the host level

There is no global module list. Each `hosts/<name>/configuration.nix` explicitly imports every module it wants from `modules/...`. Some imports are string-interpolated from settings (e.g. `modules/programs/browser/${browser}`, `modules/hardware/video/${videoDriver}.nix`) — when adding a new browser/driver/terminal/editor option, ensure a matching directory exists.

`hosts/common.nix` is imported by every host and contains: home-manager wiring, sops-nix setup, SDDM (including a `systemd.services.sddm-theme-by-time` oneshot that swaps the ThinkPad SDDM theme between `-dark` and `-light` based on time of day), boot/zram/kernel tuning, `nix.settings` (substituters, trusted keys), and the always-on `environment.systemPackages` baseline.

### Custom packages and overlays

- `pkgs/<name>.nix` — derivations not in nixpkgs. Register each in `pkgs/default.nix` via `pkgs.callPackage`. They become available as `pkgs.<name>` through the `additions` overlay.
- `overlays/default.nix` — two overlays: `additions` (the `pkgs/` re-export) and `modifications` (pinning `stable`, NUR, plus an out-of-tree `waybar` rebuild from a specific upstream commit to fix Lua socket dispatch and a cava subproject path). When touching `waybar`, the pinned commit/hash and the cava `subprojects/cava-0.10.7` rename are both load-bearing — don't drop them without verifying upstream nixpkgs has caught up.

### Adding a package — decision tree

1. **In nixpkgs?**
   - Simple single-binary CLI with no config → append to `modules/programs/cli/utilities/default.nix`.
   - Needs dotfiles/services/theming → new dir `modules/programs/<category>/<name>/default.nix`.
   - Either way it must end up in a `*.packages` list (home-manager `home.packages` or system `environment.systemPackages`) so it's actually installed — module existence alone doesn't install anything.
2. **Not in nixpkgs?** Create `pkgs/<name>.nix`, register via `callPackage` in `pkgs/default.nix`, and **add it to `environment.systemPackages` in `hosts/common.nix`** (or the relevant host) so it's available.
3. Scope packages to the host(s) that need them — work-only tools go in `hosts/t14s/configuration.nix`, never `common.nix`.

### Secrets

`sops-nix` with age key at `~/NixOS/age.key` (gitignored), encrypted bundle at `secrets.yaml`. Secrets are declared in `hosts/common.nix` under `sops.secrets` and exposed as files owned by `${username}`. Currently holds VPN, Jira, and Azure DevOps credentials.

### Home-manager vs system

Program configs (dotfiles, theming, per-user state) live in home-manager. System-level services (sddm, networking, scx, docker, etc.) live in the NixOS module. Home-manager is wired in `hosts/common.nix` with `useGlobalPkgs = true; useUserPackages = true;` — so `pkgs` inside home-manager modules already has the overlays applied.

## Conventions

- Format every `.nix` file with **Alejandra** before committing.
- **Commit and push installs once they build.** When the user asks for something to be installed or configured, and the change has then been built and switched successfully (`nixos-rebuild switch` succeeded, either run by you or confirmed by the user), commit those changes and push them right away. Do not leave them uncommitted in the working tree. Specifically:
  - Commit only the files that belong to that install, plus `flake.lock` if the install changed it. Leave unrelated WIP alone and mention it instead.
  - Write a short conventional message (`feat: add dotnet 10 sdk`, `fix: …`). Never add Claude attribution lines (no `Co-Authored-By`, no "Generated with Claude Code").
  - Never stage `age.key` or any decrypted secret.
  - Push the current branch to `origin` (`git push -u origin <branch>` if it has no upstream yet). If the push fails, report it; never force-push.
  - Before the build, run `git status` and check that the build source (`~/NixOS` or the worktree) matches what's running. Otherwise a rebuild can silently roll back uncommitted work.
- Never change `system.stateVersion` (`23.11`).
