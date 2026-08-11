# nixche
A collection of niche Nix utilities that fulfil quite specific tasks.

## Utilities

### NetBeans Java Platform (`java/create-netbeans-java-platform`)
Utilities for managing NetBeans Java Platform configurations.

- `mkNetBeansJavaPlatform`: Creates a NetBeans Java Platform XML configuration (string).
- `installNetBeansJavaPlatform`: Generates a shell script (string) to install Java Platform configuration to NetBeans.

### Write Lua Script (`lua/write-lua-script`)
Writes a `.lua` file that hands the Lua script the attribute set it was defined
with, the way a structured-attrs build exposes its derivation attributes to the
builder. The script receives the attributes through vararg.

Usage:

```nix
let
  write-lua-script = pkgs.callPackage ./lua/write-lua-script/package.nix {};
in write-lua-script.writeLuaScript {
  name = "greet";
  text = ''
    local env = ...
    print(env.name, env.buildInputs[1])
  '';
  buildInputs = [ pkgs.hello ];
}
```

`name` and `text` (the Lua source, as a string) are required; every other
attribute is coerced and passed along. The result is a wrapper `.lua` file:

```lua
return assert(loadfile("/nix/store/…-greet-source.lua"))({
  ["buildInputs"] = { "/nix/store/…-hello" },
  ["name"] = "greet",
  ["text"] = "local env = ...\nprint(env.name, env.buildInputs[1])\n"
})
```

Functions:
- `writeLuaScript`: takes the attribute set described above, returns the wrapper
  `.lua` file.

Caveats:
- Coercion mirrors structured attrs: scalars become strings, lists and attrsets
  keep their shape, and attributes that cannot coerce (functions, `null`) are
  dropped.
- Strings are rendered by `lib.generators.toLua` through `toJSON`, so a control
  character other than `\t \r \n \b \f` in any string attribute (including
  `text`) comes out as `\uXXXX`, which LuaJIT cannot parse. Ordinary Lua source
  and store paths are unaffected.
- `text` ends up in the store twice: as `<name>-source.lua`, and as a string
  inside the wrapper's table.

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
