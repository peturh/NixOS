{pkgs, ...}: {
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    
    # Fix audio underruns with larger buffers for streaming
    extraConfig.pipewire."99-custom" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 2048;        # Larger buffer (default is 1024)
        "default.clock.min-quantum" = 1024;    # Minimum buffer size
        "default.clock.max-quantum" = 8192;    # Maximum buffer size
      };
    };
    
    extraConfig.pipewire-pulse."99-custom" = {
      "pulse.properties" = {
        "pulse.min.req" = "1024/48000";        # Minimum request size
        "pulse.default.req" = "2048/48000";    # Default request size
        "pulse.max.req" = "8192/48000";        # Maximum request size
        "pulse.min.quantum" = "1024/48000";
        "pulse.max.quantum" = "8192/48000";
      };
      "stream.properties" = {
        "node.latency" = "2048/48000";         # ~42ms latency, prevents underruns
        "resample.quality" = 10;               # High quality resampling
      };
    };
    
    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
          bluetooth.autoswitch-to-headset-profile = false
        '')
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-increase-headroom.conf" ''
          monitor.alsa.rules = [
            {
              matches = [
                {
                  node.name = "~alsa_output.*"
                }
              ]
              actions = {
                update-props = {
                  api.alsa.period-size = 2048
                  api.alsa.headroom = 8192
                }
              }
            }
          ]
        '')
      ];
    };
  };
}

