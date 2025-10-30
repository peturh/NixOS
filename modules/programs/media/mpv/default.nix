{pkgs, ...}: {
  home-manager.sharedModules = [
    (_: {
      programs.mpv = {
        enable = true;
        config = {
          # Video settings
          profile = "gpu-hq";
          vo = "gpu";
          hwdec = "auto-safe";
          
          # Quality
          scale = "ewa_lanczossharp";
          cscale = "ewa_lanczossharp";
          
          # Performance
          video-sync = "display-resample";
          interpolation = true;
          tscale = "oversample";
          
          # UI - Catppuccin Mocha colors
          osd-font-size = 32;
          osd-bar-h = 2;
          osd-bar-align-y = 0.5;
          osd-color = "#cdd6f4";           # Text (Catppuccin text)
          osd-border-color = "#1e1e2e";    # Border (Catppuccin base)
          osd-shadow-color = "#11111b";    # Shadow (Catppuccin crust)
          osd-back-color = "#1e1e2e";      # Background (Catppuccin base)
          osd-border-size = 2;
          
          # Progress bar colors
          osd-playing-msg-duration = 2000;
          osd-bar-w = 60;
          
          border = false;
          
          # Save position on quit
          save-position-on-quit = true;
          
          # Screenshot settings
          screenshot-format = "png";
          screenshot-png-compression = 8;
          screenshot-directory = "~/Pictures/Screenshots";
        };
        
        # Modern OSC (on-screen controller) with better theming
        scripts = with pkgs.mpvScripts; [
          mpris        # Media player controls integration
          thumbnail    # Video thumbnail previews
        ];
      };
    })
  ];
}

