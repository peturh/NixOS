{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "pdfcraft";
  version = "0.8.0";

  src = fetchurl {
    url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-x86_64.AppImage";
    sha256 = "6b89397ec10ad505e732f18982b6ad171aab085d938ca0c3034a00d4199e38f7";
  };

  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/usr/share/applications/ai.storyteller.pdfcraft.desktop \
        $out/share/applications/ai.storyteller.pdfcraft.desktop
      cp -r ${appimageContents}/usr/share/icons $out/share/icons
      cp -r ${appimageContents}/usr/share/mime $out/share/mime
    '';

    meta = with lib; {
      description = "Open-source PDF reader and editor written from scratch in Rust";
      homepage = "https://github.com/storytold/pdfcraft";
      license = with licenses; [asl20 mit];
      platforms = ["x86_64-linux"];
      mainProgram = "pdfcraft";
    };
  }
