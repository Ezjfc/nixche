# This is a Nixpkgs overlay that patches Neovim to automatically enable Native
# LSPs.
#
# Note: this overlay is created for NvChad but should work for general Neovim
# setups with some small changes. More passthru functions might be needed when
# the current is not enought to suit my needs, like "withLspsAndConfigs"...
#
# References:
# - https://github.com/NixOS/nixpkgs/blob/19eeef59bc3f75b5a9ffa17ab86a3d9512d505e5/pkgs/by-name/pu/pulumi/with-packages.nix

final: prev: let
  inherit (prev) neovim
                 lib
                 writeText
                 runCommand
                 makeBinaryWrapper;
  needVersion = "0.11.0";
  msgScope = "nixche/neovim/neovim-enable-lsps";

  mkServerArgs = serverNames: lib.concatStringsSep " " (
    builtins.map (serverName: let
      enableScript = writeText "enable-${serverName}.lua" ''
        vim.lsp.enable("${serverName}")
      '';
    in "-c \"source ${enableScript}\"" serverNames)
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
      ln -t "$out" "${serverPackage}/bin/${program}"
    '') serverPackages
  );

  withLsps = servers: let
    supportLsp = (builtins.compareVersions neovim.version needVersion) > -1;

    serverNames = builtins.attrNames servers;
    serverPackages = builtins.attrValues servers;

    nvimAndLsps = runCommand "neovim-with-lsps" {
      buildInputs = serverPackages;
      nativeBuildInputs = [ makeBinaryWrapper ];
    } ''
      mkdir -p "$out/bin"
      ln -s -t "$out" "${neovim}/share"
      makeWrapper "${neovim}/bin/nvim" "$out/bin/nvim"

      ${mkServerLinks serverPackages}
    '';
  in assert lib.assertMsg
    (supportLsp)
    (
      msgScoe +
      "Neovim ${neovim.version} does not support Native LSP. " +
      "Please upgrade to ${needVersion} or above"
    ) nvimAndLsps;
  neovim' = neovim.overrideAttrs { passthru = (neovim.passthru or {}) // {
    inherit withLsps;
  }; };
  overlay = { neovim = neovim'; };
in overlay;
