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
          
          # Audio streaming/buffering settings
          cache = true;
          demuxer-max-bytes = "500M";           # Large buffer for network streams
          demuxer-max-back-bytes = "100M";      # Backward buffer
          demuxer-readahead-secs = 60;          # Read ahead 60 seconds
          audio-buffer = 2;                     # 2 second audio buffer
          
          # Stream timing and stability
          hr-seek = "yes";                      # High quality seeking
          force-seekable = true;                # Treat stream as seekable
          stream-buffer-size = "10MiB";         # Network stream buffer
          
          # Audio output settings for PipeWire
          audio-channels = "stereo";
          audio-samplerate = 48000;
          ao = "pipewire,pulse,alsa";           # Try PipeWire first, fallback to others
        };
        
        # Modern OSC (on-screen controller) with better theming
        scripts = with pkgs.mpvScripts; [
          mpris        # Media player controls integration
        ];
      };
    })
  ];
}

