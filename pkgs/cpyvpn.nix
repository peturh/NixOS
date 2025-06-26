
{ pkgs, ... }:

pkgs.python3Packages.buildPythonApplication rec {
  pname = "cpyvpn";
  version = "0.1.0"; # Or another version you prefer

  src = pkgs.fetchFromGitLab {
    owner = "cpvpn";
    repo = "cpyvpn";
    # A recent commit hash from the master branch
    rev = "31968d9046c4f9f65c1926639d1b72a6b472e0d3";
    hash = "sha256-4c4hW/T+bF+zRzW1r5752G4M03d8+F+K1n8zI1lK7x4=";
  };

  # Dependencies are automatically handled by the buildPythonApplication hook
  # from the requirements.txt file in the source.

  # Metadata for the package
  meta = with pkgs.lib; {
    description = "Check Point VPN client";
    homepage = "https://gitlab.com/cpvpn/cpyvpn";
    license = licenses.gpl3Only; # As stated in the repository
    maintainers = with maintainers; [ ]; # Add your GitHub username here if you like
    platforms = platforms.linux;
  };
}