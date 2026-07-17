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
  # The wrapper strips its own directory from PATH before exec, so that when
  # the wrapped nvim resolves "nvim" through PATH again (write-alias-script
  # falling through to an externally installed Neovim) the lookup cannot loop
  # back into this wrapper. Shared with sh/write-alias-script.
  stripSelf = builtins.readFile ../../sh/write-alias-script/strip-self.sh;

  # Mirrors how derivation attributes appear in a structured-attrs build:
  # scalars coerce to strings while lists and attrsets keep their shape (their
  # elements coerced recursively). Attributes that cannot coerce (functions...)
  # are dropped.
  coercible = value:
    builtins.isString value ||
    builtins.isPath value ||
    builtins.isInt value ||
    builtins.isFloat value ||
    builtins.isBool value ||
    value ? outPath ||
    value ? __toString ||
    (builtins.isList value && builtins.all coercible value) ||
    (builtins.isAttrs value && builtins.all coercible (builtins.attrValues value));

  coerce = value:
    if builtins.isAttrs value && !(value ? outPath) && !(value ? __toString)
    then lib.mapAttrs (_: coerce) value
    else if builtins.isList value
    then map coerce value
    else toString value;

  autoRun = env: let
    luaFile = env;
    envAttrs = lib.mapAttrs (_: coerce) (
      lib.filterAttrs (_: coercible) (env.drvAttrs or {})
    ) // { out = "${env}"; };
    envFile = writeText "neovim-auto-run-env.lua"
      ("return " + lib.generators.toLua {} envAttrs);

    startScript = "lua loadfile('${luaFile}')(dofile('${envFile}'))";

    nvimAutoRun = runCommand "neovim-auto-run" {
      nativeBuildInputs = [ makeWrapper ];
    } ''
      mkdir -p "$out/bin"
      ln -s -t "$out" "${neovim}/share"
      makeWrapper "${neovim}/bin/nvim" "$out/bin/nvim" \
        --run ${lib.escapeShellArg stripSelf} \
        --add-flag "-c" \
        --add-flag ${lib.escapeShellArg startScript}
    '';
  in nvimAutoRun;
in {
  inherit autoRun;
}
