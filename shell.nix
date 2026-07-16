{
  mkShellNoCC,
  callPackage,

  nixche,
  neovim ? null,
  nil,
}: let
  writeAliasScriptBin = (callPackage nixche.packages.write-alias-script {}).writeAliasScriptBin;
  neovimWithLsps' = (callPackage nixche.packages.neovim-with-lsps { neovim = neovim'; }).withLsps';
  neovim' = neovim or (writeAliasScriptBin "nvim" "nvim");

  neovimAndLsps = neovimWithLsps {
    servers = {
      inherit nil;
    }
  };
in mkShellNoCC {
  package = [
    neovimAndLsps
  ];
}
