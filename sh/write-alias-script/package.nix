# Drop-in replacements for writeShellScript and writeShellScriptBin meant for
# emulating bash aliases, which nix-direnv cannot export
# (https://github.com/direnv/direnv/issues/73). The argument is the
# alias text exactly as it would appear in `alias name='text'`: it is pasted
# verbatim and, mirroring alias expansion, whatever is typed after the command
# is appended behind it. So
#
#   writeAliasScriptBin "ls" "ls --color=auto"
#
# behaves like `alias ls='ls --color=auto'` — do not add "$@" yourself.
#
# To keep an alias named after the command it wraps from calling itself, the
# generated script first removes the PATH entry it was resolved from, so the
# lookup falls through to the next match in PATH.
#
# Caveats:
#  - The removed entry is the directory the script was *found in* ($0). When
#    the script sits directly in a devShell/store bin folder (the nix-direnv
#    case) that is exactly right. When it is symlinked into a merged profile
#    (e.g. home-manager's buildEnv), the whole profile bin is dropped for the
#    duration of the alias, which also hides sibling commands from that
#    profile.
#  - When the script is reached through another wrapper by absolute path
#    (e.g. makeWrapper), $0 is not the PATH entry the user hit and nothing is
#    stripped; the *outer* wrapper must strip its own directory instead by
#    embedding strip-self.sh (see neovim/neovim-auto-run).
{
  lib,
  writeShellScript,
  writeShellScriptBin,
}: let
  stripSelf = builtins.readFile ./strip-self.sh;
  base = f: name: alias: f name ''
    ${stripSelf}
    ${lib.trim alias} "$@"
  '';
in {
  writeAliasScript = base writeShellScript;
  writeAliasScriptBin = base writeShellScriptBin;
}
