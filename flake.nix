{
  description = ''
    A collection of niche Nix utilities that fulfil quite specific tasks.
    https://github.com/Ezjfc/nixche | Unlicense
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = {
        create-netbeans-java-platform = pkgs.writeText "create-netbeans-java-platform"
          (builtins.readFile ./java/create-netbeans-java-platform/default.nix);
        write-cat-script = pkgs.writeText "write-cat-script"
          (builtins.readFile ./sh/write-cat-script/default.nix);
      };
    }) // {
      overlays = {
        neovim-enable-lsps = import ./neovim/neovim-enable-lsps/default.nix;
      };
    };
}
