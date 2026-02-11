{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    nodejs_22
  ];
}
