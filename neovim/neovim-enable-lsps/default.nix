# This is a Nixpkgs overlay that patches Neovim to automatically enable Native
# LSPs.
# Note: this overlay is created for NvChad but should work for general Neovim
# setups with some small changes. More passthru functions might be needed when
# the current is not enought to suit my needs, like "configLsps"...

# References:
# - https://github.com/NixOS/nixpkgs/blob/19eeef59bc3f75b5a9ffa17ab86a3d9512d505e5/pkgs/by-name/pu/pulumi/with-packages.nix

final: prev: {
  neovim = prev.neovim.overrideAttrs { passthru = (prev.passthru or {}) // {
    enableLsps = servers: let
      inherit (prev) lib;
      inherit (prev) neovim;

      needVersion = "0.11.0";
      supportLsp = (builtins.compareVersions neovim.version needVersion) > -1;

      msgScope = "nixche/neovim/neovim-enable-lsps";
      enableArgs = [
        "-c"
        "'lua print(\"${msgScope}: enabling ${serverNamesDisplay}\")'"
      ] ++ serverArgs;
      serverArgs = builtins.concatMap (serverName: [
        "-c"
        "'lua vim.lsp.enable(\"${serverName}\")'"
      ]) serverNames;

      serverNames = builtins.attrNames servers;
      serverPackages = builtins.attrValues servers;
      serverNamesDisplay = lib.concatStringsSep " " serverNames;
      patch = prev.runCommand "neovim-enable-lsps" {
        inherit neovim;

        buildInputs = serverPackages;
        makeWrapperArgs = [
          "--add-flags"
          (lib.concatStringsSep " " enableArgs)
        ];
        __structuredAttrs = true;
        nativeBuildInputs = [ prev.makeWrapper ];
      } ''
        mkdir -p "$out/bin"
        ln -s -t "$out" "$neovim/share"
        makeWrapper "$neovim/bin/nvim" "$out/bin/nvim" "''${makeWrapperArgs[@]}"
      '';
    in assert lib.assertMsg
      (supportLsp)
      (
        "Neovim ${neovim.version} does not support Native LSP. " +
        "Please upgrade to ${needVersion} or above"
      );
    prev.buildEnv {
      inherit (neovim) pname version meta;
      paths = [ patch ] ++ serverPackages;
    };
  };};
}
