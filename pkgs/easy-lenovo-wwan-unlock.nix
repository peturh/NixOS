{ stdenvNoCC, fetchurl, lib }:
stdenvNoCC.mkDerivation rec {

      #name = "lenovo-wwan-unlock-${version}";
      pname = "lenovo-wwan-unlock-easy";
      version = "2.0.0";
      
      src = ./wwan-unlock.sh;

      # I like to keep the file locally in my repo, but you can also download it from here
      # this PR, specifically: https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/merge_requests/1141/diffs?commit_id=2734ac25191264e6d786af8a9577fb51519cb846
      
      
      /*src = fetchurl {
        url = "https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/raw/2734ac25191264e6d786af8a9577fb51519cb846/data/dispatcher-fcc-unlock/8086";
        hash = "sha256-QuAC2a0renRZQsZvWfTEE9a/Pj6G+ZhGEmYtVagaurE=";
      };*/

      dontUnpack = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin/
        cp -v $src $out/bin/fcc_unlock.sh
        chmod +x $out/bin/fcc_unlock.sh
        patchShebangs $out/bin/fcc_unlock.sh
        runHook postInstall
      '';


      meta = with lib; {
        homepage = "https://gist.github.com/BohdanTkachenko/3f852c352cb2e02cdcbb47419e2fcc74";
        description = "Easy unlock for Lenovo PC wwan.";
        license = licenses.cc0;
        platforms = platforms.linux;
        maintainers = [ "The Internet's Beloved Princess Grace" ];
      };
  }