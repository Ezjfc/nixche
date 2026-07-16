# Builds Neovim wrappers that automatically calls `:lua loadfile()` on launch.
#
# `nvimAutoRun` accepts a derivation which is a .lua file. The script will be executed when `nvim`
# starts and similar to `pkgs.runCommand`, the script can access most attributes defined in the
# derivation through vararg:
# ```lua
# local env = ...
# vim.print(env.buildInputs)
# ```
#
# If the derivation has a `src` attribute (e.g. built with `pkgs.runCommand`), `src` is loaded as
# the .lua file instead of the derivation output itself.

{
  neovim,
  lib,
  writeText,
  runCommand,
  makeWrapper,
}: let
  # Mirrors how derivation attributes become environment variables during a
  # build: values coerce to strings and lists join with spaces. Attributes
  # that cannot coerce (functions, plain attrsets...) are dropped.
  coercible = value:
    builtins.isString value ||
    builtins.isPath value ||
    builtins.isInt value ||
    builtins.isFloat value ||
    builtins.isBool value ||
    value ? outPath ||
    value ? __toString ||
    (builtins.isList value && builtins.all coercible value);

  autoRun = env: let
    luaFile = if env ? src then env.src else env;
    envAttrs = lib.mapAttrs (_: toString) (
      lib.filterAttrs (_: coercible) (env.drvAttrs or {})
    ) // { out = "${env}"; };
    envFile = writeText "neovim-auto-run-env.lua"
      ("return " + lib.generators.toLua {} envAttrs);
    startScript = writeText "neovim-auto-run-start.lua" ''
      loadfile("${luaFile}")(dofile("${envFile}"))
    '';
    nvimAutoRun = runCommand "neovim-auto-run" {
      buildInputs = [ env ];
      nativeBuildInputs = [ makeWrapper ];
    } ''
      mkdir -p "$out/bin"
      ln -s -t "$out" "${neovim}/share"
      makeWrapper "${neovim}/bin/nvim" "$out/bin/nvim" \
        --add-flags '-c "source ${startScript}"'
    '';
  in nvimAutoRun;
in {
  inherit autoRun;
}
