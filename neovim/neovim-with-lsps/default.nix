# This is a Nixpkgs overlay that patches Neovim to automatically enable Native
# LSPs.
#
# Note: this overlay is created for NvChad but should work for general Neovim
# setups with some small changes. More passthru functions might be needed when
# the current is not enough to suit my needs, like "withLspsAndConfigs"...
#
# References:
# - https://github.com/NixOS/nixpkgs/blob/19eeef59bc3f75b5a9ffa17ab86a3d9512d505e5/pkgs/by-name/pu/pulumi/with-packages.nix
final: prev: {
  neovim = let
    inherit (prev) neovim
                   lib
                   writeText
                   runCommand
                   makeWrapper;
    needVersion = "0.11.0";
    msgScope = "nixche/neovim/neovim-with-lsps";
    supportLsp = (builtins.compareVersions neovim.version needVersion) > -1;

    mkServerArgs = serverNames: lib.concatStringsSep " " (
      builtins.map (serverName: let
        enableScript = writeText "enable-${serverName}.lua" ''
          vim.lsp.enable("${serverName}")
        '';
      in "-c \"source ${enableScript}\"") serverNames
    );
    mkPrintArg = serverNames: let
      serverNames' = lib.concatStringsSep ", " serverNames;
      printScript = writeText "print-lsps.lua" ''
        print("${msgScope}: enabling ${serverNames'}")
      '';
    in "-c \"source ${printScript}\"";
    # Currently assume all language servers have meta.mainProgram.
    mkServerLinks = serverPackages: lib.concatStrings (
      builtins.map (serverPackage: let
        program = serverPackage.meta.mainProgram;
      in ''
        ln -s -t "$out" "${serverPackage}/bin/${program}"
      '') serverPackages
    );

    passthru' = {
      inherit withLsps;
    };
    withLsps = servers: let
      serverNames = builtins.attrNames servers;
      serverPackages = builtins.attrValues servers;
      nvimAndLsps = runCommand "neovim-with-lsps" {
        buildInputs = serverPackages;
        nativeBuildInputs = [ makeWrapper ];
      } ''
        mkdir -p "$out/bin"
        ln -s -t "$out" "${neovim}/share"
        makeWrapper "${neovim}/bin/nvim" "$out/bin/nvim" \
          --add-flags '${mkPrintArg serverNames} ${mkServerArgs serverNames}'
        ${mkServerLinks serverPackages}
      '';
    in nvimAndLsps;
  in assert lib.assertMsg supportLsp (
    msgScope +
    ": Neovim ${neovim.version} does not support Native LSP. " +
    "Please upgrade to ${needVersion} or above"
  ); neovim.overrideAttrs { passthru = (neovim.passthru or {}) // passthru'; };
}

