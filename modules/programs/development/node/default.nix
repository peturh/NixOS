{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    nodejs_24
  ];
}
