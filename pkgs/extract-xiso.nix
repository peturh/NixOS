{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation rec {
  pname = "extract-xiso";
  version = "2.7.1";

  src = fetchFromGitHub {
    owner = "XboxDev";
    repo = "extract-xiso";
    rev = "build-202505152050";
    hash = "sha256-KZxnS63MhpmzwxCPFi+op5l/vM6P9GYc+SXmNFmEyc8=";
  };

  nativeBuildInputs = [cmake];

  meta = with lib; {
    description = "Xbox ISO Creation/Extraction utility";
    homepage = "https://github.com/XboxDev/extract-xiso";
    license = licenses.bsd3;
    platforms = platforms.unix;
    mainProgram = "extract-xiso";
  };
}
