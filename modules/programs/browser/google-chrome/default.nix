{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    google-chrome
  ];
}
