{pkgs, ...}: {
  # Enable file-roller for Nautilus archive integration
  programs.file-roller.enable = true;

  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        # Archive formats
        unzip          # Extract .zip files
        zip            # Create .zip files
        unrar          # Extract .rar files
        p7zip          # Extract .7z and other formats
        gnutar         # Extract .tar files
        gzip           # Extract .gz files
        bzip2          # Extract .bz2 files
        xz             # Extract .xz files
      ];
    })
  ];
}

