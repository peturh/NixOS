{
  inputs,
  settings,
  ...
}: {
  # Overlay custom derivations into nixpkgs so you can use pkgs.<name>
  additions = final: _prev:
    import ../pkgs {
      pkgs = final;
      inputs = inputs;
      settings = settings;
    };

  # https://wiki.nixos.org/wiki/Overlays
  modifications = final: _prev: {
    nur = inputs.nur.overlays.default;
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
