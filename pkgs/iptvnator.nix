{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "iptvnator";
  version = "0.18.0";

  src = fetchurl {
    url = "https://github.com/4gray/iptvnator/releases/download/v${version}/iptvnator-${version}-linux-x86_64.AppImage";
    hash = "sha256-gf0wTtFKOO3UiPlyXZNUiDnTpfEMx6d7vBH02gE74Hc=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/iptvnator.desktop $out/share/applications/iptvnator.desktop
    install -m 444 -D ${appimageContents}/iptvnator.png $out/share/icons/hicolor/512x512/apps/iptvnator.png

    substituteInPlace $out/share/applications/iptvnator.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=iptvnator'
  '';

  meta = with lib; {
    description = "Cross-platform IPTV player with Xtream Codes and M3U support";
    homepage = "https://github.com/4gray/iptvnator";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "iptvnator";
  };
}
