# In ~/NixOS/pkgs/converse.nix
# This file defines HOW to build the converse package.

# It receives pkgs and inputs as arguments.
{ pkgs, inputs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "converse";
  version = "0.1.0";

  # This now refers to the input passed from your flake.nix
  src = inputs.converse-src;

  # This hash is necessary for a reproducible build
  cargoHash = "sha256-8hkzwL/NfQR0Un4X1VlbYV0byXXv1cgShLRtLr+kwc4=";

  # These are the build-time dependencies for converse
  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ gtk3 gtk-layer-shell openssl];

  meta = with pkgs.lib; {
    description = "A frontend to LLMs like Gemini, Claude, Cohere and OpenAI models";
    homepage = "https://github.com/vishruth-thimmaiah/converse";
    license = licenses.gpl3Only;
    maintainers = with pkgs.lib.maintainers; [ ]; # Add your name here if you like
  };
}