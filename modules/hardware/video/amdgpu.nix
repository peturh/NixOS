{pkgs, ...}: {
  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
      vulkan-loader
      vulkan-extension-layer
    ];
  };
  environment.variables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };
}
