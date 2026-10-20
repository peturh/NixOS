{pkgs, ...}: let
  # Real runtime root (contains shared/, host/fxr/); the dotnet on PATH is a wrapper.
  dotnetRoot = "${pkgs.dotnet-sdk_10.unwrapped}/share/dotnet";
in {
  environment.systemPackages = [pkgs.dotnet-sdk_10];
  environment.sessionVariables = {
    DOTNET_ROOT = dotnetRoot;
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
  };
  # Apphost fallback when DOTNET_ROOT isn't in the env (systemd units, GUI launches).
  environment.etc."dotnet/install_location".text = dotnetRoot;
  # Apphosts run via nix-ld; icu/openssl/zlib/libstdc++ already come from misc/nix-ld.
  programs.nix-ld.libraries = [pkgs.krb5];
}
