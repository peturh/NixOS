{
  lib,
  python3,
  fetchFromGitHub,
  fwupd,
  makeWrapper,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "8bitdo-updater";
  version = "unstable-2024-12-15";
  format = "other";

  src = fetchFromGitHub {
    owner = "franfermon";
    repo = "8bitdo_update";
    rev = "main";
    hash = "sha256-N2SZKyMX82P0X5xHojpaeZ36oPEtReeS6x0+1bNIUEw=";
  };

  nativeBuildInputs = [makeWrapper];

  propagatedBuildInputs = with python3.pkgs; [
    requests
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/8bitdo-updater

    cp 8bitdo_updater.py $out/share/8bitdo-updater/
    cp 8bitdo_scraper.py $out/share/8bitdo-updater/

    makeWrapper ${python3.interpreter} $out/bin/8bitdo-updater \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --prefix PATH : "${lib.makeBinPath [fwupd]}" \
      --add-flags "$out/share/8bitdo-updater/8bitdo_updater.py"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Firmware updater for 8BitDo gamepads on Linux";
    homepage = "https://github.com/franfermon/8bitdo_update";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "8bitdo-updater";
  };
}
