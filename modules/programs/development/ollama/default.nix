{pkgs, ...}: {
  # Local LLM server. ROCm backend covers both the Phoenix iGPU (gfx1103)
  # and the RX 9060 XT eGPU (gfx1200) natively on ROCm 7.2 — no
  # HSA_OVERRIDE_GFX_VERSION needed. Falls back to CPU when neither is usable.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    # Keep the ollama binary + models on the default /var/lib/ollama path.
    environmentVariables = {
      # Unload idle models after 30 min instead of the default 5 so a coding
      # session doesn't keep paying the reload cost.
      OLLAMA_KEEP_ALIVE = "30m";
      # Allow a couple of parallel requests from editor/tooling.
      OLLAMA_NUM_PARALLEL = "2";
    };
  };
}
