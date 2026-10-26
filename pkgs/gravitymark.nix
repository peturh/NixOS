{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  unzip,
  libx11,
  libxext,
  libxrandr,
  libxcb,
  libglvnd,
  vulkan-loader,
  xdg-utils,
}: let
  pname = "gravitymark";
  version = "1.89";
in
  stdenv.mkDerivation {
    inherit pname version;

    # Upstream ships a Makeself self-extracting .run. Rather than execute it,
    # unpackPhase reads the line count from the stub's own `head -n N` and
    # untars the gzip payload that follows it.
    src = fetchurl {
      url = "https://tellusim.com/download/GravityMark_${version}.run";
      hash = "sha256-3gkMe55A8Q8iXZOT8s9zpmCtTtwh9rMz7qMZCoci4AU=";
    };

    nativeBuildInputs = [autoPatchelfHook makeWrapper copyDesktopItems unzip];

    buildInputs = [
      stdenv.cc.cc.lib
      libx11
      libxext
      libxrandr
      libxcb
    ];

    # Loaded with dlopen at runtime, so autoPatchelf can't see them.
    runtimeLibs = lib.makeLibraryPath [vulkan-loader libglvnd];

    unpackPhase = ''
      runHook preUnpack
      skip=$(grep -a -m1 -oE 'head -n [0-9]+' "$src" | awk '{print $3}')
      [ -n "$skip" ] || { echo "could not find makeself payload offset"; exit 1; }
      mkdir source
      tail -n +"$((skip + 1))" "$src" | tar xz -C source
      cd source
      runHook postUnpack
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # The binaries resolve data.zip / browser.zip relative to bin/, so keep
      # the upstream tree intact and chdir into it from the wrappers.
      app=$out/share/gravitymark
      mkdir -p $app $out/bin $out/share/doc/gravitymark
      cp -r bin data.zip browser.zip $app/
      cp Acknowledgements.txt GravityMark_*.pdf $out/share/doc/gravitymark/
      chmod +x $app/bin/GravityMark.x64 $app/bin/Browser.x64

      unzip -q -j browser.zip browser/images/gravitymark.svg -d .
      install -Dm444 gravitymark.svg $out/share/icons/hicolor/scalable/apps/gravitymark.svg

      # Launcher: serves the configuration UI on localhost and opens it with xdg-open.
      makeWrapper $app/bin/Browser.x64 $out/bin/gravitymark \
        --chdir $app/bin \
        --prefix LD_LIBRARY_PATH : "$runtimeLibs" \
        --prefix PATH : ${lib.makeBinPath [xdg-utils]} \
        --add-flags "-root browser/ ../browser.zip"

      # Direct benchmark binary; accepts the flags from upstream's run_*.sh
      # (e.g. gravitymark-cli -vk -fullscreen 1 -benchmark 1 -close 1).
      makeWrapper $app/bin/GravityMark.x64 $out/bin/gravitymark-cli \
        --chdir $app/bin \
        --prefix LD_LIBRARY_PATH : "$runtimeLibs"

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "gravitymark";
        desktopName = "GravityMark";
        comment = "GPU benchmark";
        exec = "gravitymark";
        icon = "gravitymark";
        categories = ["System" "Utility"];
      })
    ];

    meta = with lib; {
      description = "Cross-platform GPU benchmark by Tellusim (Vulkan, OpenGL, OpenGL ES)";
      homepage = "https://gravitymark.tellusim.com/";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "gravitymark";
    };
  }
