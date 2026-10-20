{
  lib,
  appimageTools,
  fetchurl,
}: let
  pname = "photocraft";
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-x86_64.AppImage";
    sha256 = "483a9a79200e0c0864bb54cf3faa6a55e2b79c1433dacfcb153d3862e78f32bc";
  };

  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # AppRun otherwise copies its own .desktop + icons into ~/.local/share on
    # every launch; Nix installs them below, so skip that to avoid duplicates.
    profile = ''
      export PHOTOCRAFT_NO_DESKTOP_INTEGRATION=1
    '';

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/usr/share/applications/ai.storyteller.photocraft.desktop \
        $out/share/applications/ai.storyteller.photocraft.desktop
      cp -r ${appimageContents}/usr/share/icons $out/share/icons
    '';

    meta = with lib; {
      description = "Open-source photo editor written from scratch in Rust";
      homepage = "https://github.com/storytold/photocraft";
      license = with licenses; [asl20 mit];
      platforms = ["x86_64-linux"];
      mainProgram = "photocraft";
    };
  }
