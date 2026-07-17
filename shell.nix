{
  mkShellNoCC,
  callPackage,
  writeShellScriptBin,

  nixche,
  neovim ? null,
  nil,
}: let
  neovimWithLsps' = (nixche.neovim-with-lsps.override {
    neovim = if neovim == null then (writeShellScriptBin "nvim" ''
      [ -f /usr/bin/nvim ] && /usr/bin/nvim "$@" && exit 0
      [ -f /run/current-system/sw/nvim ] && /run/current-system/sw/nvim "$@" && exit 0

      echo "Neovim is not installed system-wide"
      exit 1
    '') else neovim;
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
