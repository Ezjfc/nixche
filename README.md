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
- `withLsps'`: Provides more control.

### Write Alias Script (`sh/write-alias-script`)
Shell script wrappers for emulating bash aliases, which nix-direnv cannot
export (see [direnv/direnv#73](https://github.com/direnv/direnv/issues/73)).
The argument is the alias text exactly as it would appear in
`alias name='text'`: it is pasted verbatim and, mirroring alias expansion,
any arguments are appended behind it (do not add `"$@"` yourself). The
generated script removes the `PATH` entry it was resolved from before running
the alias text, so a script named after the command it wraps does not recurse
into itself.

Usage:

```nix
let
  write-alias-script = pkgs.callPackage ./sh/write-alias-script/package.nix {};
in {
  packages = [
    # Behaves like `alias ls='ls --color=auto'`:
    (write-alias-script.writeAliasScriptBin "ls" "ls --color=auto")
  ];
}
```

Functions:
- `writeAliasScript`: `writeShellScript`, but with alias semantics as above.
- `writeAliasScriptBin`: same for `writeShellScriptBin`.

Caveats:
- The directory the script was *found in* (`$0`) is removed. In a devShell or
  plain store bin folder that is exactly the alias package; in a merged
  profile (e.g. home-manager's `buildEnv`) it hides the whole profile bin for
  the duration of the alias.
- When the alias script is reached through another wrapper by absolute path
  (e.g. `makeWrapper`), the outer wrapper must strip *its* directory instead;
  embed `sh/write-alias-script/strip-self.sh` in it the way
  `neovim/neovim-auto-run` does.

### Write Cat Script (`sh/write-cat-script`)
Shell script wrappers that echo the script content to stderr before execution.

Call-package arguments:
- `colour`: terminal colour code, defaults to dark purple.

Functions:
- `writeCatScript`: Wraps `writeShellScript` to print the script content to stderr before running it.
- `writeCatScriptBin`: Wraps `writeShellScriptBin` to print the script content to stderr before running it.
