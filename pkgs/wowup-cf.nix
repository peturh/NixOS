# WowUp (CurseForge build): WoW addon manager. Nixpkgs is on 2.24.0, which
# predates WoW Forever client detection (merged upstream 2026-10-18, shipped
# in 2.24.1); this pin shadows it via the `additions` overlay. Drop this file
# once nixpkgs' wowup-cf is >= 2.24.1.
{
  lib,
  appimageTools,
  fetchurl,
}: let
  version = "2.25.4";
  pname = "wowup-cf";

  src = fetchurl {
    url = "https://github.com/WowUp/WowUp.CF/releases/download/v${version}/WowUp-CF-${version}.AppImage";
    hash = "sha256-tKOFboaUo1wgLJ2xjLPOyqHrf8Do+oS0ZzL2fcs8Jc4=";
  };

  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = {
      description = "World of Warcraft addon updater with CurseForge support";
      mainProgram = "wowup-cf";
      homepage = "https://wowup.io/";
      downloadPage = "https://github.com/WowUp/WowUp.CF/releases";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      platforms = ["x86_64-linux"];
    };
  }
