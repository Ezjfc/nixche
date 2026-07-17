{
  mkShellNoCC,
  callPackage,

  nixche,
  neovim ? null,
  nil,
}: let
  inherit (nixche.write-alias-script) writeAliasScriptBin;
  neovimWithLsps' = (nixche.neovim-with-lsps.override {
    neovim = if neovim == null then (writeAliasScriptBin "nvim" "nvim") else neovim;
  }).withLsps';

  neovimAndLsps = neovimWithLsps' {
    servers = {
      inherit nil;
    };
  };
in mkShellNoCC {
  packages = [
    neovimAndLsps
  ];
}
