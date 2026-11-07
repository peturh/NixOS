{pkgs, ...}: {
  systemd = {
    packages = with pkgs; [lact];
    services.lactd = {
      wantedBy = ["multi-user.target"];
      # lactd segfaults in libdrm_amdgpu when the GPU set changes under it
      # (logout, sleep, eGPU detach) and leaves /run/lactd.sock behind; the
      # upstream unit then fails every restart with "socket already exists"
      # until the start limit is hit. Clear it before each start.
      serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/rm -f /run/lactd.sock";
    };
  };
  environment.systemPackages = with pkgs; [lact];
}
