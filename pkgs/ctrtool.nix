{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "ctrtool";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "3DSGuy";
    repo = "Project_CTR";
    rev = "ctrtool-v${version}";
    hash = "sha256-wjU/DJHrAHE3MSB7vy+swUDVPzw0Jrv4ymOjhfr0BBk=";
  };

  # Build the bundled dependencies first, then the program
  buildPhase = ''
    cd ctrtool
    make deps
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/ctrtool $out/bin/
  '';

  meta = with lib; {
    description = "CLI tool to read/extract Nintendo 3DS files";
    homepage = "https://github.com/3DSGuy/Project_CTR";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "ctrtool";
  };
}
