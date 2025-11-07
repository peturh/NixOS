{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    go
  ];
}

