{
  pkgs,
  username,
  ...
}: let
  # Define radio stations in a CSV format
  radioStations = ''
https://live1.sr.se/p1-aac-320,SR P1 (AAC 320kbps)
https://live1.sr.se/p2-flac,SR P2 (FLAC)
https://live1.sr.se/p3-aac-320,SR P3 (AAC 320kbps)
https://live1.sr.se/p4malm-aac-320,SR P4 Malmö (AAC 320kbps)
  '';
in {
  environment.systemPackages = with pkgs; [
    radioboat
  ];

  # Create the radioboat URLs configuration file
  system.activationScripts.radioboat = ''
    mkdir -p /home/${username}/.config/radioboat
    cat > /home/${username}/.config/radioboat/urls.csv << 'EOF'
    ${radioStations}
    EOF
    chown ${username}:users /home/${username}/.config/radioboat/urls.csv
    chmod 644 /home/${username}/.config/radioboat/urls.csv
  '';
}

