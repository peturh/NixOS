{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        claude-code
      ];

      xdg.desktopEntries.claude-code = {
        name = "Claude Code";
        genericName = "AI Coding Assistant";
        exec = "kitty --class claude-code -e claude";
        icon = "utilities-terminal";
        terminal = false;
        categories = ["Development" "Utility"];
      };
    })
  ];
}
