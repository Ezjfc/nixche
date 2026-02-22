# nixche
A collection of niche Nix utilities that fulfil quite specific tasks.

## Utilities

### NetBeans Java Platform (`java/create-netbeans-java-platform`)
Utilities for managing NetBeans Java Platform configurations.

- `mkNetBeansJavaPlatform`: Creates a NetBeans Java Platform XML configuration (string).
- `installNetBeansJavaPlatform`: Generates a shell script (string) to install Java Platform configuration to NetBeans.

### Neovim With LSPs (`neovim/neovim-with-lsps`)
A Nixpkgs overlay that patches Neovim to automatically enable Native LSPs on startup.
Requires Neovim 0.11.0 or above (which introduced the built-in LSP client).

Usage: apply the overlay and call `pkgs.neovim.withLsps` with an attrset mapping
server names to their packages, e.g.:

```nix
packages = with pkgs; [
  (pkgs.neovim.withLsps {
    lua_ls = pkgs.lua-language-server;
    nixd   = pkgs.nixd;
  })
];
```

- `withLsps`: Wraps `nvim` with `-c` flags that call `vim.lsp.enable()` for each server, and adds the server packages to the environment.

### Write Cat Script (`sh/write-cat-script`)
Shell script wrappers that echo the script content to stderr before execution.

Call-package arguments:
- `colour`: terminal colour code, defaults to dark purple.

Functions:
- `writeCatScript`: Wraps `writeShellScript` to print the script content to stderr before running it.
- `writeCatScriptBin`: Wraps `writeShellScriptBin` to print the script content to stderr before running it.
