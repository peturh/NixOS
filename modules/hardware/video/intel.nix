{pkgs, ...}: {
  services.xserver = {
    enable = true;
    videoDrivers = ["modesetting"];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
  };
}
