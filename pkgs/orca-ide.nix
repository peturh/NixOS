{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "orca-ide";
  version = "1.4.230";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-1QOwMWtb/aeyhx2E9m6ZvekYybuvnR9ggcKT+UYVCKs=";
  };

  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/orca-ide.desktop $out/share/applications/orca-ide.desktop
      cp -r ${appimageContents}/usr/share/icons $out/share/icons

      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=orca-ide'
    '';

    meta = with lib; {
      description = "Agent development environment for parallel agentic coding";
      homepage = "https://github.com/stablyai/orca";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "orca-ide";
    };
  }
