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
          
          # Audio visualization - cava-style spectrum
          # Automatically show visualization for audio-only files
          audio-display = "attachment";
        };
        
        # Profiles for different visualization styles
        profiles = {
          # Cava-style spectrum analyzer (press 'c' to activate)
          "visualizer-spectrum" = {
            profile-desc = "Cava-style spectrum visualizer";
            video-sync = "display-resample";
            lavfi-complex = "[aid1]asplit[ao][a1];[a1]avectorscope=s=1920x1080:r=60:zoom=1.5:draw=line:scale=log:rc=40:gc=200:bc=40[vo]";
          };
          
          # Frequency spectrum (like cava bars)
          "visualizer-cava" = {
            profile-desc = "Cava-like frequency bars";
            video-sync = "display-resample";
            lavfi-complex = "[aid1]asplit[ao][a1];[a1]showfreqs=s=1920x1080:mode=bar:ascale=log:fscale=log:win_size=2048:rate=60:colors=0x94e2d5|0x89dceb|0x74c7ec|0x89b4fa|0xcba6f7|0xf5c2e7|0xeba0ac|0xf38ba8[vo]";
          };
          
          # Waveform visualization
          "visualizer-wave" = {
            profile-desc = "Audio waveform";
            video-sync = "display-resample";
            lavfi-complex = "[aid1]asplit[ao][a1];[a1]showwaves=s=1920x1080:mode=line:rate=60:colors=0x89b4fa[vo]";
          };
          
          # CQT (Constant Q Transform) - Beautiful spectrum
          "visualizer-showcqt" = {
            profile-desc = "CQT spectrum analyzer";
            video-sync = "display-resample";
            lavfi-complex = "[aid1]asplit[ao][a1];[a1]showcqt=s=1920x1080:rate=60:bar_g=2:sono_g=4:bar_v=9:sono_v=17:sono_h=0:timeclamp=0.5:basefreq=20:endfreq=20000:tlength='st(0,0.17); 384*tc / (384 / ld(0) + tc*f/(1-ld(0))) + 384*tc / (tc*f / ld(0) + 384 /(1-ld(0)))':count=30[vo]";
          };
        };
        
        # Enhanced scripts and visualizers
        scripts = with pkgs.mpvScripts; [
          mpris              # Media player controls integration
          visualizer         # Audio visualizer
          quality-menu       # Quality selection for streams
          autoload           # Auto-load playlist from directory
        ];
        
        # Custom keybindings for enhanced features
        bindings = {
          # Cava-style visualizers (different modes)
          "c" = "apply-profile visualizer-cava";      # Cava-like frequency bars
          "C" = "apply-profile visualizer-showcqt";   # Beautiful CQT spectrum
          "Alt+v" = "apply-profile visualizer-wave";  # Waveform
          "Alt+s" = "apply-profile visualizer-spectrum"; # Vector scope
          "Alt+c" = "set lavfi-complex \"\"";         # Clear visualization (normal mode)
          
          # Visualizer controls (press 'v' to cycle visualizers)
          "v" = "script-binding visualizer/cycle-visualizer";
          
          # Stats overlay (Shift+i for detailed stats, i for simple)
          "i" = "script-binding stats/display-stats-toggle";
          "I" = "script-binding stats/display-page-1";
          
          # Audio controls
          "=" = "add audio-delay 0.1";           # Sync audio forward
          "-" = "add audio-delay -0.1";          # Sync audio backward
          "Ctrl+=" = "add volume 2";             # Volume up
          "Ctrl+-" = "add volume -2";            # Volume down
          
          # Quality menu (F5 for stream quality)
          "F5" = "script-binding quality_menu/video_formats_toggle";
          
          # Playback speed
          "[" = "multiply speed 0.9091";         # Decrease speed
          "]" = "multiply speed 1.1";            # Increase speed
          "{" = "multiply speed 0.5";            # Half speed
          "}" = "multiply speed 2.0";            # Double speed
          "BS" = "set speed 1.0";                # Reset speed (Backspace)
        };
      };
      
      # Install visualizer dependencies
      home.packages = with pkgs; [
        ffmpeg-full  # For audio visualization filters
      ];
    })
  ];
}

