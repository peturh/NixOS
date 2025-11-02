{pkgs, ...}: {
  # Enable Steam with all the bells and whistles
  programs.steam = {
    enable = true;
    
    # Enable Steam Remote Play
    remotePlay.openFirewall = true;
    
    # Enable Steam Dedicated Server
    dedicatedServer.openFirewall = true;
    
    # Enable GameScope session for gaming mode
    gamescopeSession.enable = true;
    
    # Extra compatibility tools
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Enable GameMode for better gaming performance
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };

  # Install additional gaming utilities
  environment.systemPackages = with pkgs; [
    mangohud      # Performance overlay
    gamescope     # SteamOS session compositing window manager
    gamemode      # Optimize system performance for gaming
    protontricks  # Run Winetricks commands for Proton games
  ];

  # Enable 32-bit support for graphics drivers (required for most games)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}

