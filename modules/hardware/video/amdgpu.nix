# This module is untested since i don't own an amd gpu!
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
      libva-vdpau-driver
      # vulkan-loader
      # vulkan-extension-layer
      # vulkan-validation-layers
    ];
  };
}
