{pkgs, ...}: {
  # Celeste is a GTK4 GUI sync client (rclone-based) that can two-way sync
  # local folders with Google Drive, Dropbox, Nextcloud, pCloud, ProtonDrive,
  # WebDAV, etc. After installing, launch "Celeste" from the app launcher,
  # add a Google Drive remote, then add folder sync pairs.
  home-manager.sharedModules = [
    (_: {
      home.packages = with pkgs; [
        celeste
      ];
    })
  ];
}
