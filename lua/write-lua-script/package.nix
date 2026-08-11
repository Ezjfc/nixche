# Writes a .lua file that loads a Lua script and hands it the attribute set the script was
# defined with, mirroring how a structured-attrs build exposes its derivation attributes.
#
# `writeLuaScript` takes a single attribute set: `name` and `text` (the Lua source) are
# required, everything else is passed to the script through vararg:
# ```nix
# writeLuaScript {
#   name = "greet";
#   text = ''
#     local env = ...
#     print(env.name, env.buildInputs[1])
#   '';
#   buildInputs = [ pkgs.hello ];
# }
# ```
#
# The result is a wrapper .lua file; `text` itself is written next to it as a separate
# `<name>-source.lua` and `loadfile`d by the wrapper. Attributes that cannot coerce
# (functions, null...) are dropped, just like in a structured-attrs build.
#
# Caveat: strings are rendered by `lib.generators.toLua` through `toJSON`, so a control
# character other than \t \r \n \b \f in any string attribute (including `text`) comes out
# as \uXXXX, which LuaJIT cannot parse. Ordinary Lua source and store paths are unaffected.

{
  lib,
  writeText,
}: let
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

  writeLuaScript = attrs @ { name, text, ... }: let
    source = writeText "${name}-source.lua" text;
    env = lib.mapAttrs (_: coerce) (lib.filterAttrs (_: coercible) attrs);
  in writeText "${name}.lua" ''
    return assert(loadfile(${builtins.toJSON "${source}"}))(${lib.generators.toLua {} env})
  '';
in {
  inherit writeLuaScript;
}
