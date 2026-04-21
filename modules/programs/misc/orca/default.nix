{pkgs, ...}: {
  # AT-SPI accessibility bus is required for Orca to read GTK/Qt/Chromium UIs.
  # Hyprland (non-GNOME) does not enable it implicitly.
  services.gnome.at-spi2-core.enable = true;

  # Speech synthesis backend. The default eSpeak-NG voice is lightweight and
  # ships with speechd; Piper or RHVoice can be added later for nicer voices.
  services.speechd.enable = true;

  # QT_ACCESSIBILITY makes Qt apps expose their accessibility tree to AT-SPI.
  # GTK apps do this automatically when the bus is running.
  environment.sessionVariables = {
    QT_ACCESSIBILITY = "1";
  };

  environment.systemPackages = with pkgs; [
    orca
    speechd
    espeak-ng
  ];

  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        orca
      ];
    })
  ];
}
