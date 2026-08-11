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
# `writeLuaScriptShare` is the same, except the wrapper lands in a directory as
# `<out>/share/<name>.lua` instead of being the output file itself.
#
# Caveat: strings are rendered by `lib.generators.toLua` through `toJSON`, so a control
# character other than \t \r \n \b \f in any string attribute (including `text`) comes out
# as \uXXXX, which LuaJIT cannot parse. Ordinary Lua source and store paths are unaffected.

{
  lib,
  writeText,
  writeTextFile,
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

  wrapper = attrs @ { name, text, ... }: let
    source = writeText "${name}-source.lua" text;
    env = lib.mapAttrs (_: coerce) (lib.filterAttrs (_: coercible) attrs);
  in ''
    return assert(loadfile(${builtins.toJSON "${source}"}))(${lib.generators.toLua {} env})
  '';

  base = out: attrs @ { name, ... }: out name (wrapper attrs);
in {
  writeLuaScript = base (name: writeText "${name}.lua");
  writeLuaScriptShare = base (name: text: writeTextFile {
    inherit name text;
    destination = "/share/${name}.lua";
  });
}
