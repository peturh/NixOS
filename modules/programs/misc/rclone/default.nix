{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.obsidian-sync;

  pairsArg = lib.concatStringsSep " " (map (p: "${p.remote}::${p.local}") cfg.pairs);

  obsidianSync = pkgs.writeShellScriptBin "obsidian-sync" ''
    set -uo pipefail
    base="$HOME/Documents/Obsidian"
    mkdir -p "$base"
    failed=0
    for entry in ${pairsArg}; do
      remote="''${entry%%::*}"
      local="''${entry##*::}"
      mkdir -p "$base/$local"
      sentinel="$HOME/.local/state/rclone-bisync/$local.initialized"
      mkdir -p "$(dirname "$sentinel")"
      args=(
        bisync "$remote" "$base/$local"
        --create-empty-src-dirs
        --compare size,modtime,checksum
        --slow-hash-sync-only
        --resilient
        --recover
        --max-lock 2m
        --conflict-resolve newer
        --conflict-loser num
        --conflict-suffix rc-conflict
        --log-level INFO
      )
      if [ ! -f "$sentinel" ]; then
        args+=(--resync)
      fi
      if ${pkgs.rclone}/bin/rclone "''${args[@]}"; then
        touch "$sentinel"
      else
        echo "obsidian-sync: bisync failed for $local" >&2
        failed=1
      fi
    done
    exit $failed
  '';
in {
  options.programs.obsidian-sync = {
    enable = lib.mkEnableOption "rclone bisync for Obsidian vaults";
    pairs = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          remote = lib.mkOption {
            type = lib.types.str;
            description = "rclone remote spec, e.g. \"gdrive-personal:Familj\".";
          };
          local = lib.mkOption {
            type = lib.types.str;
            description = "Subdirectory under ~/Documents/Obsidian/ to sync into.";
          };
        };
      });
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.rclone obsidianSync];

    home-manager.sharedModules = [
      (_: {
        systemd.user.services.obsidian-sync = {
          Unit.Description = "rclone bisync for Obsidian vaults";
          Service = {
            Type = "oneshot";
            ExecStart = "${obsidianSync}/bin/obsidian-sync";
          };
        };
        systemd.user.timers.obsidian-sync = {
          Unit.Description = "Periodic rclone bisync for Obsidian";
          Timer = {
            OnBootSec = "2min";
            OnUnitActiveSec = "5min";
            Persistent = true;
          };
          Install.WantedBy = ["timers.target"];
        };
      })
    ];
  };
}
