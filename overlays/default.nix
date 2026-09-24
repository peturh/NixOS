{inputs, ...}: {
  # Overlay custom derivations into nixpkgs so you can use pkgs.<name>
  additions = final: _prev:
    import ../pkgs {
      pkgs = final;
      inputs = inputs;
    };

  # https://wiki.nixos.org/wiki/Overlays
  modifications = final: prev: {
    nur = inputs.nur.overlays.default;
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
    # Nixpkgs 0.15.0 predates Hyprland’s Lua socket dispatch protocol; workspace
    # clicks/scroll still send `dispatch workspace …` and silently do nothing.
    # https://github.com/Alexays/Waybar/commit/e17c0d9f0a73acc370df60ec8c532b1ed2385c73
    #
    # Upstream’s libcava.wrap expects `subprojects/cava-0.10.7`; nixpkgs’
    # postUnpack still used `cava-0.10.7-beta`, so we vendor the matching tree.
    waybar = let
      cavaWaybar = prev.fetchFromGitHub {
        owner = "LukashonakV";
        repo = "cava";
        rev = "0.10.7";
        hash = "sha256-zkyj1vBzHtoypX4Bxdh1Vmwh967DKKxN751v79hzmgQ=";
      };
    in
      prev.waybar.overrideAttrs (_oldAttrs: {
        src = prev.fetchFromGitHub {
          owner = "Alexays";
          repo = "Waybar";
          rev = "e17c0d9f0a73acc370df60ec8c532b1ed2385c73";
          hash = "sha256-p5iqMo4JPhbukRqPlYjciaU89wRPDmWSUY9NkxywI+k=";
        };
        postUnpack = ''
          pushd "$sourceRoot"
          cp -R --no-preserve=mode,ownership ${cavaWaybar} subprojects/cava-0.10.7
          patchShebangs .
          popd
        '';
      });
  };
}
