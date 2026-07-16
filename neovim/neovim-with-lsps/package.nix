# Builds Neovim wrappers that automatically enable Native LSPs. Call with
# callPackage; the result is the withLsps function, which takes an attrset
# mapping server names to their packages.
#
# Note: this is created for NvChad but should work for general Neovim
# setups with some small changes. More functions might be needed when
# the current is not enough to suit my needs, like "withLspsAndConfigs"...

{
  stdenvNoCC,
  neovim,
  lib,
  srcOnly,

  callPackage,
  autoRun ? (callPackage ../neovim-with-lsps {}).autoRun,
}: let
  needVersion = "0.11.0";
  supportLsp = (builtins.compareVersions neovim.version needVersion) > -1;

  withLsps' = {
    servers,
    runtimeVersionCheck ? true,
  }:let
    autoRunEnv = srcOnly {
      name = "lsps.lua";
      src = ./lsps.lua;
      buildInputs = builtins.attrValues servers;
      stdenv = stdenvNoCC;

      LSPS = servers;
      NEED_VERSION = if lib.runtimeVersionCheck then needVersion else "";
    };
    nvimWithLsps = autoRun autoRunEnv;
  in nvimWithLsps;
in {
  inherit withLsps';

  withLsps = assert lib.assertMsg supportLsp (
    "nixche/neovim/neovim-with-lsps" +
    ": Neovim ${neovim.version} does not support Native LSP. " +
    "Please upgrade to ${needVersion} or above"
  ) (servers: withLsps' {
    inherit servers;
    runtimeVersionCheck = false;
  });
}
