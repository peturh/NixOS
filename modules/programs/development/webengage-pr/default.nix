{username, ...}: {
  # GitHub classic token (repo scope, SSO-authorized for puzzeltech) used by
  # github-create-pr. Add it with `sops secrets.yaml` as `github_pat` BEFORE
  # rebuilding — a missing key makes sops-install-secrets fail for all secrets.
  # ~/.github-pat becomes a symlink to /run/secrets/github-pat (use `stat -L`).
  sops.secrets."github-pat" = {
    key = "github_pat";
    owner = username;
    mode = "0600";
    path = "/home/${username}/.github-pat";
  };

  home-manager.sharedModules = [
    ({config, ...}: {
      # PR helper for the Claude Code webengage plugin. Out-of-store symlink to
      # the marketplace checkout, not plugins/cache/ (its folder name changes on
      # every plugin update). The target is already 755 in the checkout.
      home.file.".local/bin/github-create-pr".source =
        config.lib.file.mkOutOfStoreSymlink
        "/home/${username}/.claude/plugins/marketplaces/puzzel-agents/teams/webengage/scripts/github-create-pr.sh";

      home.sessionPath = ["$HOME/.local/bin"];
    })
  ];
}
