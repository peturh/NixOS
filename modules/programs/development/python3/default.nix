{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    python3
  ];
}
