{
  stdenv,
  fetchFromGitHub,
  kdePackages,
  lib,
  writeText,
  # "dark" or "light" — selects palette and form placement to suit the
  # corresponding ThinkPad-branded wallpaper without obscuring it.
  variant ? "dark",
  # Path to the wallpaper image to bake into this variant. Copied verbatim into
  # the theme; Qt6's built-in decoders handle png/jpg/jpeg/webp natively.
  wallpaper,
}:
assert lib.assertMsg (variant == "dark" || variant == "light") "thinkpad sddm variant must be 'dark' or 'light'"; let
  # ThinkPad red — same across both palettes so the brand cue stays constant.
  accent = "#E2231A";

  palette =
    {
      dark = {
        formPosition = "right";
        timeText = "#E5E5E5";
        dateText = "#888888";
        headerText = "#E5E5E5";
        loginFieldBg = "#1A1A1A";
        loginFieldText = "#E5E5E5";
        passwordFieldBg = "#1A1A1A";
        passwordFieldText = "#E5E5E5";
        placeholderText = "#888888";
        userIcon = "#E5E5E5";
        passwordIcon = "#E5E5E5";
        hoverUserIcon = accent;
        hoverPasswordIcon = accent;
        loginButtonText = "#FFFFFF";
        loginButtonBg = accent;
        systemButtonsIcons = "#888888";
        hoverSystemButtonsIcons = accent;
        sessionButtonText = "#888888";
        hoverSessionButtonText = accent;
        vkButtonText = "#888888";
        hoverVkButtonText = accent;
        dropdownText = "#E5E5E5";
        dropdownBg = "#1A1A1A";
        dropdownSelectedBg = accent;
        highlightText = "#FFFFFF";
        highlightBg = accent;
        highlightBorder = accent;
        formBg = "#1A1A1A";
        bg = "#000000";
        dimBg = "#000000";
        warning = accent;
      };
      light = {
        formPosition = "left";
        timeText = "#1A1A1A";
        dateText = "#555555";
        headerText = "#1A1A1A";
        loginFieldBg = "#F5F5F5";
        loginFieldText = "#1A1A1A";
        passwordFieldBg = "#F5F5F5";
        passwordFieldText = "#1A1A1A";
        placeholderText = "#777777";
        userIcon = "#1A1A1A";
        passwordIcon = "#1A1A1A";
        hoverUserIcon = accent;
        hoverPasswordIcon = accent;
        loginButtonText = "#FFFFFF";
        loginButtonBg = accent;
        systemButtonsIcons = "#555555";
        hoverSystemButtonsIcons = accent;
        sessionButtonText = "#555555";
        hoverSessionButtonText = accent;
        vkButtonText = "#555555";
        hoverVkButtonText = accent;
        dropdownText = "#1A1A1A";
        dropdownBg = "#F5F5F5";
        dropdownSelectedBg = accent;
        highlightText = "#FFFFFF";
        highlightBg = accent;
        highlightBorder = accent;
        formBg = "#F5F5F5";
        bg = "#FFFFFF";
        dimBg = "#FFFFFF";
        warning = accent;
      };
    }.${
      variant
    };

  themeConf = ''
    [General]
    ScreenWidth="1920"
    ScreenHeight="1080"
    ScreenPadding="60"

    Font="Open Sans"
    FontSize=""

    KeyboardSize="0.4"
    RoundCorners="6"

    Locale=""
    HourFormat="HH:mm"
    DateFormat="dddd d MMMM"

    HeaderText=""

    BackgroundPlaceholder=""
    Background="Backgrounds/thinkpad.png"
    BackgroundSpeed=""
    PauseBackground=""
    DimBackground="0.0"
    CropBackground="true"
    BackgroundHorizontalAlignment="center"
    BackgroundVerticalAlignment="center"

    HeaderTextColor="${palette.headerText}"
    DateTextColor="${palette.dateText}"
    TimeTextColor="${palette.timeText}"

    FormBackgroundColor="${palette.formBg}"
    BackgroundColor="${palette.bg}"
    DimBackgroundColor="${palette.dimBg}"

    LoginFieldBackgroundColor="${palette.loginFieldBg}"
    PasswordFieldBackgroundColor="${palette.passwordFieldBg}"
    LoginFieldTextColor="${palette.loginFieldText}"
    PasswordFieldTextColor="${palette.passwordFieldText}"
    UserIconColor="${palette.userIcon}"
    PasswordIconColor="${palette.passwordIcon}"

    PlaceholderTextColor="${palette.placeholderText}"
    WarningColor="${palette.warning}"

    LoginButtonTextColor="${palette.loginButtonText}"
    LoginButtonBackgroundColor="${palette.loginButtonBg}"
    SystemButtonsIconsColor="${palette.systemButtonsIcons}"
    SessionButtonTextColor="${palette.sessionButtonText}"
    VirtualKeyboardButtonTextColor="${palette.vkButtonText}"

    DropdownTextColor="${palette.dropdownText}"
    DropdownSelectedBackgroundColor="${palette.dropdownSelectedBg}"
    DropdownBackgroundColor="${palette.dropdownBg}"

    HighlightTextColor="${palette.highlightText}"
    HighlightBackgroundColor="${palette.highlightBg}"
    HighlightBorderColor="${palette.highlightBorder}"

    HoverUserIconColor="${palette.hoverUserIcon}"
    HoverPasswordIconColor="${palette.hoverPasswordIcon}"
    HoverSystemButtonsIconsColor="${palette.hoverSystemButtonsIcons}"
    HoverSessionButtonTextColor="${palette.hoverSessionButtonText}"
    HoverVirtualKeyboardButtonTextColor="${palette.hoverVkButtonText}"

    PartialBlur="false"
    FullBlur="false"
    BlurMax="48"
    Blur="2.0"

    HaveFormBackground="true"
    FormPosition="${palette.formPosition}"

    VirtualKeyboardPosition="center"

    HideVirtualKeyboard="false"
    HideSystemButtons="false"
    HideLoginButton="false"

    ForceLastUser="true"
    PasswordFocus="true"
    HideCompletePassword="true"
    AllowEmptyPassword="false"
    AllowUppercaseLettersInUsernames="false"
    BypassSystemButtonsChecks="false"
    RightToLeftLayout="false"

    TranslatePlaceholderUsername=""
    TranslatePlaceholderPassword=""
    TranslateLogin=""
    TranslateLoginFailedWarning=""
    TranslateCapslockWarning=""
    TranslateSuspend=""
    TranslateHibernate=""
    TranslateReboot=""
    TranslateShutdown=""
    TranslateSessionSelection=""
    TranslateVirtualKeyboardButtonOn=""
    TranslateVirtualKeyboardButtonOff=""
  '';

  metadataDesktop = ''
    [SddmGreeterTheme]
    Name=ThinkPad ${variant}
    Description=Minimal ThinkPad-branded SDDM theme (${variant} variant)
    Author=petur
    License=GPLv3
    Type=sddm-theme
    Version=0.1
    Website=
    Screenshot=Backgrounds/thinkpad.png
    MainScript=Main.qml
    ConfigFile=Themes/thinkpad.conf
    TranslationsDirectory=Translations
    Email=
    Theme-Id=sddm-thinkpad-${variant}
    Theme-API=2.0
    QtVersion=6
  '';

  # Materialize the two text files as Nix-store paths so the install phase
  # can just `cp` them in. Avoids any heredoc / indentation footguns.
  themeConfFile = writeText "thinkpad.conf" themeConf;
  metadataFile = writeText "metadata.desktop" metadataDesktop;
in
  stdenv.mkDerivation {
    pname = "sddm-thinkpad-${variant}";
    version = "0.1.0";
    dontBuild = true;
    dontWrapQtApps = true;

    # Reuse Keyitdev's proven Qt6 QML — only the .conf and metadata.desktop
    # are ours. Pinned to the same revision the existing astronaut theme uses.
    src = fetchFromGitHub {
      owner = "Keyitdev";
      repo = "sddm-astronaut-theme";
      rev = "5e39e0841d4942757079779b4f0087f921288af6";
      sha256 = "09vi9dr0n0bhq8cj4jq1h17jw2ssi79zi9lhn0j6kgbxrqk2g8vf";
    };

    propagatedBuildInputs = with kdePackages; [
      qtsvg
      qtmultimedia
      qtvirtualkeyboard
    ];

    installPhase = ''
      runHook preInstall

      themeDir="$out/share/sddm/themes/sddm-thinkpad-${variant}"
      install -dm755 "$themeDir"
      cp -r ./* "$themeDir"

      # Replace upstream subthemes with just ours; keep QML/Components/Fonts.
      rm -rf "$themeDir/Themes"
      install -dm755 "$themeDir/Themes"
      install -m644 ${themeConfFile} "$themeDir/Themes/thinkpad.conf"

      # Overwrite metadata.desktop so SDDM loads our conf.
      install -m644 ${metadataFile} "$themeDir/metadata.desktop"

      # Drop the wallpaper in as Backgrounds/thinkpad.<ext>; keep the original
      # extension so Qt picks the right decoder.
      rm -rf "$themeDir/Backgrounds"
      install -dm755 "$themeDir/Backgrounds"
      src=${wallpaper}
      ext="''${src##*.}"
      install -m644 "$src" "$themeDir/Backgrounds/thinkpad.$ext"
      # Point the conf at the real filename in case the extension isn't png.
      chmod u+w "$themeDir/Themes/thinkpad.conf"
      sed -E -i "s|^Background=.*|Background=\"Backgrounds/thinkpad.$ext\"|" \
        "$themeDir/Themes/thinkpad.conf"
      chmod 644 "$themeDir/Themes/thinkpad.conf"

      # Ship the bundled fonts system-wide so the greeter can render them
      # without depending on whatever the booted user has installed.
      install -dm755 "$out/share/fonts"
      cp -r "$themeDir/Fonts/." "$out/share/fonts" 2>/dev/null || true

      runHook postInstall
    '';

    postFixup = ''
      mkdir -p $out/nix-support
      echo ${kdePackages.qtsvg} >> $out/nix-support/propagated-user-env-packages
      echo ${kdePackages.qtmultimedia} >> $out/nix-support/propagated-user-env-packages
      echo ${kdePackages.qtvirtualkeyboard} >> $out/nix-support/propagated-user-env-packages
    '';

    meta = with lib; {
      description = "Minimal ThinkPad-branded SDDM theme (${variant} variant)";
      platforms = platforms.linux;
      license = licenses.gpl3Only;
    };
  }
