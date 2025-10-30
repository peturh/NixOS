{
  pkgs,
  lib,
  terminal,
  ...
}: let
  inherit (lib) getExe;
in {
  home-manager.sharedModules = [
    (_: {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        terminal = "${getExe pkgs.${terminal}}";
        plugins = with pkgs; [
          rofi-emoji # https://github.com/Mange/rofi-emoji 🤯
          rofi-games # https://github.com/Rolv-Apneseth/rofi-games 🎮
        ];
      };
      xdg.configFile."rofi/config-music.rasi".source = ./config-music.rasi;
      xdg.configFile."rofi/config-long.rasi".source = ./config-long.rasi;
      xdg.configFile."rofi/config-wallpaper.rasi".source = ./config-wallpaper.rasi;
      xdg.configFile."rofi/launchers" = {
        source = ./launchers;
        recursive = true;
      };
      xdg.configFile."rofi/colors" = {
        source = ./colors;
        recursive = true;
      };
      xdg.configFile."rofi/assets" = {
        source = ./assets;
        recursive = true;
      };
      xdg.configFile."rofi/resolution" = {
        source = ./resolution;
        recursive = true;
      };
      
      # Configure networkmanager_dmenu to use rofi with matching theme
    #   xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    #     [dmenu]
    #     dmenu_command = rofi -dmenu -theme ~/.config/rofi/launchers/type-2/style-2.rasi
    #     compact = True
    #     wifi_chars = ▂▄▆█
    #     wifi_icons = 󰤯󰤟󰤢󰤥󰤨
    #     format = {name}  {sec}  {bars}
    #     pinentry = /run/current-system/sw/bin/pinentry

    #     [editor]
    #     terminal = ${getExe pkgs.${terminal}}
    #     gui_if_available = True
    #   '';
    })
  ];
}
