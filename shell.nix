{
  mkShellNoCC,
  callPackage,

  nixche,
  neovim ? null,
  nil,
}: let
  inherit (nixche.write-alias-script) writeAliasScriptBin;
  neovimWithLsps' = (nixche.neovim-with-lsps.override {
    neovim = (writeAliasScriptBin "nvim" "nvim");
  }).withLsps';
  # neovim' = if neovim == null then  else neovim;
  # neovim' = if neovim == null then (writeAliasScriptBin "nvim" "nvim") else neovim;

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
