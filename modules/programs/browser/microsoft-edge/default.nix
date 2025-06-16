{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    microsoft-edge
  ];
}
