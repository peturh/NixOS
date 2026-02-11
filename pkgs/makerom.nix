{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "makerom";
  version = "0.19.0";

  src = fetchFromGitHub {
    owner = "3DSGuy";
    repo = "Project_CTR";
    rev = "makerom-v${version}";
    hash = "sha256-GvEzv97DqCsaDWVqDpajQRWYe+WM8xCYmGE0D3UcSrM=";
  };

  # Build the bundled dependencies first, then the program
  buildPhase = ''
    cd makerom
    make deps
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/makerom $out/bin/
  '';

  meta = with lib; {
    description = "CLI tool to create Nintendo 3DS CXI/CFA/CCI/CIA files";
    homepage = "https://github.com/3DSGuy/Project_CTR";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "makerom";
  };
}
