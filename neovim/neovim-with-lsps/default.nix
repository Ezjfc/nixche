# This doc comment is written by Claude Sonnet 4.5, partially edited.
#
# A Nixpkgs overlay that wraps Neovim to automatically enable language servers
# via Neovim's native LSP client (introduced in 0.11.0).
#
# --- Why does this exist? ---
#
# Neovim 0.11+ ships a built-in LSP client that can be configured with
# `vim.lsp.enable("<server-name>")`. However, doing this in the conventional
# ways has drawbacks:
#   - Adding servers to your user/system Neovim config couples project-specific
#     tooling to your global editor setup.
#   - Mason and mason-lspconfig install servers imperatively at runtime,
#     outside of Nix's control, leading to impure and unreproducible environments.
#
# This overlay lets you declare language servers as part of your project's Nix
# expression instead. The resulting derivation handles both enabling the servers
# via `vim.lsp.enable` at startup and making their binaries available to Neovim,
# without touching your global Neovim config.
#
# This overlay solves the problem differently: it gives the Neovim derivation
# a `withLsps` passthru function. Calling it produces a *new* derivation that:
#   1. Wraps the `nvim` binary with `--cmd` flags that call
#      `vim.lsp.enable("<server>")` for every requested server at startup,
#      which is what causes servers to auto-attach to matching buffers.
#   2. Symlinks every server binary into the same `bin/` directory as `nvim`,
#      so they are guaranteed to be on PATH when Neovim runs.
#
# The result is a self-contained package you can put anywhere in a Nix
# environment without needing NixOS modules or Home Manager.
#
# --- Usage ---
#
#   pkgs.neovim.withLsps {
#     lua_ls        = pkgs.lua-language-server;
#     ts_ls         = pkgs.typescript-language-server;
#     rust_analyzer = pkgs.rust-analyzer;
#   }
#
# The attribute *name* must match the server name expected by `vim.lsp.enable`
# (usually the same name you would pass to nvim-lspconfig).
# The attribute *value* is the Nixpkgs package for that server.
#
# --- Requirements ---
#   - Neovim ≥ 0.11.0  (native LSP client with vim.lsp.enable)
#   - The nvim-lspconfig plugin installed in your Neovim config — it supplies
#     the per-language defaults (command, filetypes, settings) that
#     vim.lsp.enable reads. The auto-attachment to buffers is handled by
#     Neovim's native LSP client once vim.lsp.enable is called; lspconfig
#     itself is just a configuration source.
#
# References:
# - vim.lsp.enable docs:  https://neovim.io/doc/user/lsp.html
# - nixpkgs wrapper pattern this is modelled on:
#   https://github.com/NixOS/nixpkgs/blob/19eeef59bc3f75b5a9ffa17ab86a3d9512d505e5/pkgs/by-name/pu/pulumi/with-packages.nix

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
          local mopt = vim.o.mopt
          print("${msgScope}: enabling ${serverNames'}")
          vim.o.mopt = mopt
      '';
    in "-c \"source ${printScript}\"";
    # Currently assume all language servers have meta.mainProgram.
    mkServerLinks = serverPackages: lib.concatStrings (
      builtins.map (serverPackage: let
        program = serverPackage.meta.mainProgram;
      in ''
        ln -s -t "$out/bin" "${serverPackage}/bin/${program}"
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
          --add-flags '${mkServerArgs serverNames} ${mkPrintArg serverNames}'
        ${mkServerLinks serverPackages}
      '';
    in nvimAndLsps;
  in assert lib.assertMsg supportLsp (
    msgScope +
    ": Neovim ${neovim.version} does not support Native LSP. " +
    "Please upgrade to ${needVersion} or above"
  ); neovim.overrideAttrs { passthru = (neovim.passthru or {}) // passthru'; };
}



