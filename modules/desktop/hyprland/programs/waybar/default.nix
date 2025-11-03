{pkgs, ...}: {
  fonts.packages = with pkgs.nerd-fonts; [jetbrains-mono];
  home-manager.sharedModules = [
    (_: {
      programs.waybar = {
        enable = true;
        systemd = {
          enable = false;
          target = "graphical-session.target";
        };
        settings = [
          {
            layer = "top";
            position = "top";
            mode = "dock"; # Fixes fullscreen issues
            height = 32; # 35
            exclusive = true;
            passthrough = false;
            gtk-layer-shell = true;
            ipc = true;
            fixed-center = true;
            margin-top = 10;
            margin-left = 10;
            margin-right = 10;
            margin-bottom = 0;
            

            modules-left-left = ["custom/launcher"];
            modules-left = ["hyprland/workspaces"];
            # modules-center = ["idle_inhibitor" "clock" "custom/notification"];
            modules-center = ["clock"];
            # modules-center = ["wlr/taskbar"];
            modules-right = ["bluetooth" "network" "tray"];
            #"tray"

            "custom/launcher" = {
              format = " ";
              on-click = "${../../scripts/rofi.sh}";
            };
            

            "wlr/taskbar"= {
                format = "{icon}";
                icon-size = 14;
                all-outputs = false;
                icon-theme = "Numix-Circle";
                tooltip-format = "{title}";
                on-click = "activate";
                on-click-middle = "close";
                ignore-list = [
                  "Alacritty"
                ];
            };

            "hyprland/workspaces" = {
              disable-scroll = false;
              all-outputs = true;
              active-only = false;
              on-click = "activate";
              on-scroll-up = "hyprctl dispatch workspace e+1";
              on-scroll-down = "hyprctl dispatch workspace e-1";
              persistent-workspaces = {
                "*" = [1 2 3 4 5 6 7 8 9 10];
              };
              format = "{name}";
            };

            "hyprland/window" = {
              format = "{}";
              separate-outputs = true;
              rewrite = {
                "harvey@hyprland =(.*)" = "$1 ";
                "(.*) — Mozilla Firefox" = "$1 󰈹";
                "(.*)Mozilla Firefox" = " Firefox 󰈹";
                "(.*) - Visual Studio Code" = "$1 󰨞";
                "(.*)Visual Studio Code" = "Code 󰨞";
                "(.*)Cursor" = "Code 󰨞";
                "(.*) — Dolphin" = "$1 󰉋";
                "(.*)Spotify" = "Spotify 󰓇";
                "(.*)Spotify Premium" = "Spotify 󰓇";
                "(.*)Steam" = "Steam 󰓓";
                "(.*)Edge" = "$1 ";
                "(.*)Chrome" = "$1 ";
                "(.*)Slack" = "$1 ";
              };
              max-length = 1000;
            };

             "clock" = {
              format = "{:%a %d %b %R}";
              # format = "{:%R 󰃭 %d·%m·%y}";
              format-alt = "{:%I:%M %p}";
              tooltip-format = "<tt>{calendar}</tt>";
              calendar = {
                mode = "month";
                mode-mon-col = 3;
                on-scroll = 1;
                on-click-right = "mode";
                format = {
                  months = "<span color='#ffead3'><b>{}</b></span>";
                  weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                  today = "<span color='#ff6699'><b>{}</b></span>";
                };
              };
              actions = {
                on-click-right = "mode";
                on-click-forward = "tz_up";
                on-click-backward = "tz_down";
                on-scroll-up = "shift_up";
                on-scroll-down = "shift_down";
              };
            };


            "network" = {
              on-click-right = "networkmanager_dmenu";
              # "interface" = "wlp2*"; # (Optional) To force the use of this interface
              format-wifi = "󰤨  {signalStrength}%";
              # format-wifi = " {bandwidthDownBits}  {bandwidthUpBits}";
              # format-wifi = "󰤨 {essid}";
              format-ethernet = "󱘖  {ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}";
              # format-ethernet = " {bandwidthDownBits}  {bandwidthUpBits}";
              format-linked = "󱘖 {ifname} (No IP)";
              format-disconnected = "󰤮 Off";
              # format-disconnected = "󰤮 Disconnected";
              format-alt = "󰤨 {signalStrength}% {ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}";
              tooltip-format = "󱘖 {ipaddr}  {bandwidthUpBytes}  {bandwidthDownBytes}";
              #on-click-right = "nm-connection-editor";
            };

            "bluetooth" = {
              format = "";
              format-alt = " {device_alias}";
              # format-disabled = ""; # an empty format will hide the module
              format-connected = " {num_connections}";
              tooltip-format = " {device_alias}";
              tooltip-format-connected = "{device_enumerate}";
              tooltip-format-enumerate-connected = " {device_alias}";
              # on-click = "blueman-manager";
              on-click-right = "blueman-manager";
            };

            "tray" = {
              icon-size = 12;
              spacing = 5;
            };
          }
           {
            layer = "bottom";
            position = "bottom";
            mode = "dock"; # Fixes fullscreen issues
            height = 32; # 35
            exclusive = true;
            passthrough = false;
            gtk-layer-shell = true;
            ipc = true;
            fixed-center = true;
            margin-top = 1;
            margin-left = 10;
            margin-right = 10;
            margin-bottom = 0;

            modules-left = ["pulseaudio#microphone" "pulseaudio" "cava" "mpris"];
            # modules-center = ["idle_inhibitor" "clock" "custom/notification"];
            modules-center = ["hyprland/window"];
            modules-right = ["custom/tlp" "cpu" "memory" "backlight" "battery" "temperature"];

            "custom/tlp" = { 
              format = "{icon}";
              format-icons = {
                battery = "󰄌 ";
                ac = "󰚥 ";
              };
              exec = "${../../scripts/tlp-ctl.sh} get --json";
              exec-on-event = true;
              return-type = "json";
              # We need to run every now and then in case there are outside changes.
              interval = 5;
              on-click = "${../../scripts/tlp-ctl.sh}  toggle";
              on-click-right = "${../../scripts/tlp-ctl.sh}  set auto";
           };
           #"power-profiles-daemon" 
            # "power-profiles-daemon" = {
            #   format = "{icon}";
            #   tooltip-format= "Power profile: {profile}\nDriver: {driver}";
            #   tooltip = true;
            #   format-icons = {
            #     default = "󱐋";
            #     performance = "󱐋";
            #     balanced = " ";
            #     power-saver = "󱙷 ";i
            #   };
            # };

            "custom/notification" = {
              tooltip = false;
              format = "{icon}";
              format-icons = {
                notification = "<span foreground='red'><sup></sup></span>";
                none = "";
                dnd-notification = "<span foreground='red'><sup></sup></span>";
                dnd-none = "";
                inhibited-notification = "<span foreground='red'><sup></sup></span>";
                inhibited-none = "";
                dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
                dnd-inhibited-none = "";
              };
              return-type = "json";
              exec-if = "which swaync-client";
              exec = "swaync-client -swb";
              on-click = "swaync-client -t -sw";
              on-click-right = "swaync-client -d -sw";
              escape = true;
            };

            "custom/colour-temperature" = {
              format = "{} ";
              exec = "wl-gammarelay-rs watch {t}";
              on-scroll-up = "busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n +100";
              on-scroll-down = "busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n -100";
            };

            "custom/cava_mviz" = {
              exec = "${../../scripts/WaybarCava.sh}";
              format = "{}";
            };
            "cava" = {
              hide_on_silence = false;
              framerate = 60;
              bars = 10;
              format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
              input_delay = 1;
              # "noise_reduction" = 0.77;
              sleep_timer = 5;
              bar_delimiter = 0;
              on-click = "playerctl play-pause";
            };
            "custom/gpuinfo" = {
              exec = "${../../scripts/gpuinfo.sh}";
              return-type = "json";
              format = " {}";
              interval = 5; # once every 5 seconds
              tooltip = true;
              max-length = 1000;
            };
            "custom/icon" = {
              # format = " ";
              exec = "echo ' '";
              format = "{}";
            };
            "mpris" = {
              format = "{player_icon} {title} - {artist}";
              format-paused = "{status_icon} <i>{title} - {artist}</i>";
              player-icons = {
                default = "▶";
                spotify = "";
                mpv = "󰐹";
                vlc = "󰕼";
                firefox = "";
                chromium = "";
                kdeconnect = "";
                mopidy = "";
              };
              status-icons = {
                paused = "⏸";
                playing = "";
              };
              ignored-players = ["firefox" "chromium"];
              max-length = 30;
            };
            "temperature" = {
              hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
              critical-threshold = 83;
              format = "{icon} {temperatureC}°C";
              format-icons = ["" "" ""];
              interval = 10;
            };
            "hyprland/language" = {
              format = "{short}"; # can use {short} and {variant}
              on-click = "${../../scripts/keyboardswitch.sh}";
            };
            "hyprland/workspaces" = {
              disable-scroll = false;
              all-outputs = true;
              active-only = false;
              on-click = "activate";
              on-scroll-up = "hyprctl dispatch workspace e+1";
              on-scroll-down = "hyprctl dispatch workspace e-1";
              persistent-workspaces = {
                "*" = [1 2 3 4 5 6 7 8 9 10];
              };
              format = "{id} {windows}";
              format-window-separator = " ";
              window-rewrite-default = "";
              window-rewrite = {
                "firefox" = "󰈹";
                "google-chrome" = "";
                "microsoft-edge" = "󰇩";
                "code" = "󰨞";
                "cursor" = "󰨞";
                "kitty" = "";
                "alacritty" = "";
                "wezterm" = "";
                "discord" = "󰙯";
                "slack" = "󰒱";
                "spotify" = "󰓇";
                "vlc" = "󰕼";
                "mpv" = "";
                "nautilus" = "󰉋";
                "thunar" = "󰉋";
                "steam" = "󰓓";
                "obs" = "󰐌";
                "gimp" = "";
                "signal" = "󰍡 ";
                "telegram" = "";
              };            
            };

            "hyprland/window" = {
              # format = "  {}";
              format = "{}";
              separate-outputs = true;
              rewrite = {
                "harvey@hyprland =(.*)" = "$1 ";
                "(.*) — Mozilla Firefox" = "$1 󰈹";
                "(.*)Mozilla Firefox" = " Firefox 󰈹";
                "(.*) - Visual Studio Code" = "$1 󰨞";
                "(.*)Visual Studio Code" = "Code 󰨞";
                "(.*) — Dolphin" = "$1 󰉋";
                "(.*)Spotify" = "Spotify 󰓇";
                "(.*)Spotify Premium" = "Spotify 󰓇";
                "(.*)Steam" = "Steam 󰓓";
                "(.*)Edge" = "$1 - Edge ";
                "(.*)Chrome" = "$1 - Chrome ";

              };
              max-length = 1000;
            };

            "idle_inhibitor" = {
              format = "{icon}";
              format-icons = {
                activated = "󰥔";
                deactivated = "";
              };
            };

            "cpu" = {
              interval = 10;
              format = "󰻠 {usage}%";
              format-alt = "{icon0}{icon1}{icon2}{icon3}";
              format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
            };

            "memory" = {
              interval = 30;
              format = "󰾆 {percentage}%";
              format-alt = "󰾅 {used}GB";
              max-length = 10;
              tooltip = true;
              tooltip-format = " {used:.1f}GB/{total:.1f}GB";
            };

            "backlight" = {
              format = "{icon} {percent}%";
              format-icons = ["" "" "" "" "" "" "" "" ""];
              on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set 2%+";
              on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 2%-";
            };


            "bluetooth" = {
              format = "";
              # format-disabled = ""; # an empty format will hide the module
              format-connected = " {num_connections}";
              tooltip-format = " {device_alias}";
              tooltip-format-connected = "{device_enumerate}";
              tooltip-format-enumerate-connected = " {device_alias}";
              on-click = "blueman-manager";
            };

            "pulseaudio" = {
              format = "{icon} {volume}";
              format-muted = " ";
              on-click = "pavucontrol -t 3";
              tooltip-format = "{icon} {desc} // {volume}%";
              scroll-step = 4;
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                portable = "";
                car = "";
                default = ["" "" ""];
              };
            };

            "pulseaudio#microphone" = {
              format = "{format_source}";
              format-source = " {volume}%";
              format-source-muted = "";
              on-click = "pavucontrol -t 4";
              tooltip-format = "{format_source} {source_desc} // {source_volume}%";
              scroll-step = 5;
            };

            "tray" = {
              icon-size = 12;
              spacing = 5;
            };

            "battery" = {
              states = {
                good = 95;
                warning = 30;
                critical = 20;
              };
              format = "{icon} {capacity}%";
              # format-charging = " {capacity}%";
              format-charging = " {capacity}%";
              format-plugged = " {capacity}%";
              format-alt = "{time} {icon}";
              format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
            };

            "custom/power" = {
              format = "{}";
              on-click = "wlogout -b 4";
              interval = 86400; # once every day
              tooltip = true;
            };
          }
        ];
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font";
            font-size: 14px;
            font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
            margin: 0px;
            padding: 0px;
          }

          @define-color base   #1e1e2e;
          @define-color mantle #181825;
          @define-color crust  #11111b;

          @define-color text     #cdd6f4;
          @define-color subtext0 #a6adc8;
          @define-color subtext1 #bac2de;

          @define-color surface0 #313244;
          @define-color surface1 #45475a;
          @define-color surface2 #585b70;

          @define-color overlay0 #6c7086;
          @define-color overlay1 #7f849c;
          @define-color overlay2 #9399b2;

          @define-color blue      #89b4fa;
          @define-color lavender  #b4befe;
          @define-color sapphire  #74c7ec;
          @define-color sky       #89dceb;
          @define-color teal      #94e2d5;
          @define-color green     #a6e3a1;
          @define-color yellow    #f9e2af;
          @define-color peach     #fab387;
          @define-color maroon    #eba0ac;
          @define-color red       #f38ba8;
          @define-color mauve     #cba6f7;
          @define-color pink      #f5c2e7;
          @define-color flamingo  #f2cdcd;
          @define-color rosewater #f5e0dc;

          window#waybar {
            transition-property: background-color;
            transition-duration: 0.5s;
            background: transparent;
            /*border: 2px solid @overlay0;*/
            /*background: @theme_base_color;*/
            border-radius: 10px;
          }

          window#waybar.hidden {
            opacity: 0.2;
          }

          tooltip {
            background: #1e1e2e;
            border-radius: 8px;
          }

          tooltip label {
            color: #cad3f5;
            margin-right: 5px;
            margin-left: 5px;
          }


          /* This section can be use if you want to separate waybar modules */

           .modules-left-left {
          	background: @theme_base_color;
           	border: 1px solid @blue;
          	padding-right: 15px;
          	padding-left: 2px;
          	border-radius: 10px;
          }

          .modules-left {
          	background: @theme_base_color;
           	border: 1px solid @blue;
          	padding-right: 15px;
          	padding-left: 2px;
          	border-radius: 10px;
          }
          .modules-center {
          	background: @theme_base_color;
            border: 0.5px solid @overlay0;
          	padding-right: 5px;
          	padding-left: 5px;
          	border-radius: 10px;
          }
          .modules-right {
          	background: @theme_base_color;
           	border: 1px solid @blue;
          	padding-right: 15px;
          	padding-left: 15px;
          	border-radius: 10px;
          }

          #backlight,
          #backlight-slider,
          #battery,
          #bluetooth,
          #clock,
          #cpu,
          #disk,
          #idle_inhibitor,
          #keyboard-state,
          #memory,
          #mode,
          #mpris,
          #network,
          #pulseaudio,
          #pulseaudio-slider,
          #taskbar button,
          #taskbar,
          #temperature,
          #tray,
          #window,
          #wireplumber,
          #workspaces,
          #custom-backlight,
          #custom-cycle_wall,
          #custom-keybinds,
          #custom-keyboard,
          #custom-light_dark,
          #custom-lock,
          #custom-menu,
          #custom-tlp,
          #custom-power_vertical,
          #custom-power,
          #custom-swaync,
          #custom-updater,
          #custom-weather,
          #custom-weather.clearNight,
          #custom-weather.cloudyFoggyDay,
          #custom-weather.cloudyFoggyNight,
          #custom-weather.default,
          #custom-weather.rainyDay,
          #custom-weather.rainyNight,
          #custom-weather.severe,
          #custom-weather.showyIcyDay,
          #custom-weather.snowyIcyNight,
          #custom-weather.sunnyDay {
          	padding-top: 3px;
          	padding-bottom: 3px;
          	padding-right: 6px;
          	padding-left: 6px;
          }

          #idle_inhibitor {
            color: @blue;
          }

          #bluetooth,
          #backlight {
            color: @blue;
          }

          #battery {
            color: @green;
          }

          @keyframes blink {
            to {
              color: @surface0;
            }
          }

          #battery.critical:not(.charging) {
            background-color: @red;
            color: @theme_text_color;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
            box-shadow: inset 0 -3px transparent;
          }

          #custom-updates {
            color: @blue
          }

          #custom-tlp {
            padding-right: 2px;
            color: @peach;
          }

          #power-profiles-daemon {
            padding-right: 2px;
          }

          #power-profiles-daemon.performance {
            color: @red
          }
          #power-profiles-daemon.balanced {
            color: @blue  
          }
          #power-profiles-daemon.power-saver {
            color: @green
          }

          #custom-notification {
            color: #dfdfdf;
            padding: 0px 5px;
            border-radius: 5px;
          }

          #language {
            color: @blue
          }

          #clock {
            color: @yellow;
          }

          #custom-icon {
            font-size: 15px;
            color: #cba6f7;
          }

          #custom-gpuinfo {
            color: @maroon;
          }

          #cpu {
            color: @yellow;
          }

          #custom-keyboard,
          #memory {
            color: @green;
          }

          #disk {
            color: @sapphire;
          }

          #temperature {
            color: @teal;
          }

          #temperature.critical {
            background-color: @red;
          }

          #tray > .passive {
            -gtk-icon-effect: dim;
          }
          #tray > .needs-attention {
            -gtk-icon-effect: highlight;
          }

          #keyboard-state {
            color: @flamingo;
          }

          #workspaces {
            background: transparent;
            margin: 5px;
            padding: 0px;
            border-radius: 10px;
          }

          #workspaces button {
              font-size: 16px;
              font-weight: bold;
              padding: 0px 8px;
              margin: 0px 2px;
              border-radius: 8px;
              color: @subtext0;
              background: transparent;
              transition: all 0.3s ease;
          }

          #workspaces button:hover {
              color: @text;
              background: @surface0;
          }

          #workspaces button.active {
              color: @crust;
              background: @mauve;
              padding: 0px 10px;
          }

          #workspaces button.urgent {
              color: @crust;
              background: @red;
          }

          #taskbar button.active {
              padding-left: 8px;
              padding-right: 8px;
              animation: gradient_f 20s ease-in infinite;
              transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
          }

          #taskbar button:hover {
              padding-left: 2px;
              padding-right: 2px;
              animation: gradient_f 20s ease-in infinite;
              transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
          }

          #custom-cava_mviz {
          	color: @pink;
          }

          #cava {
          	color: @pink;
          }

          #mpris {
          	color: @pink;
          }

          #custom-menu {
            color: @rosewater;
          }

          #custom-power {
            color: @red;
          }

          #custom-updater {
            color: @red;
          }

          #custom-light_dark {
            color: @blue;
          }

          #custom-weather {
            color: @lavender;
          }

          #custom-lock {
            color: @maroon;
          }

          #pulseaudio {
            color: @lavender;
          }

          #pulseaudio.bluetooth {
            color: @pink;
          }
          #pulseaudio.muted {
            color: @red;
          }

          #window {
            color: @mauve;
          }

          #custom-waybar-mpris {
            color:@lavender;
          }

          #network {
            color: @sapphire;
          }
          #network.disconnected,
          #network.disabled {
            background-color: @surface0;
            color: @text;
          }
          #pulseaudio-slider slider {
          	min-width: 0px;
          	min-height: 0px;
          	opacity: 0;
          	background-image: none;
          	border: none;
          	box-shadow: none;
          }

          #pulseaudio-slider trough {
          	min-width: 80px;
          	min-height: 5px;
          	border-radius: 5px;
          }

          #pulseaudio-slider highlight {
          	min-height: 10px;
          	border-radius: 5px;
          }

          #backlight-slider slider {
          	min-width: 0px;
          	min-height: 0px;
          	opacity: 0;
          	background-image: none;
          	border: none;
          	box-shadow: none;
          }

          #backlight-slider trough {
          	min-width: 80px;
          	min-height: 10px;
          	border-radius: 5px;
          }

          #backlight-slider highlight {
          	min-width: 10px;
          	border-radius: 5px;
          }
        '';
      };
    })
  ];
}
