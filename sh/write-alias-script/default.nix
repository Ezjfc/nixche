# This is a Nixpkgs overlay that adds writeAliasScript and writeAliasScriptBin,
# drop-in replacements for writeShellScript and writeShellScriptBin meant for
# emulating shell aliases (which nix-direnv cannot export). The generated
# script removes the PATH entry it was resolved from before running the given
# content, so a script named after the command it wraps (e.g. an "ls" script
# that calls "ls --color") falls through to the next match in PATH instead of
# recursing into itself.
#
# Caveat: the removed entry is the *directory the script was found in*. When
# the script sits directly in a devShell/store bin folder (the nix-direnv
# case) that is exactly right. When it is symlinked into a merged profile
# (e.g. home-manager's buildEnv), the whole profile bin is dropped for the
# duration of the alias, which also hides sibling commands from that profile.
final: prev: let
  stripSelf = ''
    __nixche_self_dir=''${0%/*}
    IFS=: read -r -a __nixche_path_dirs <<< "$PATH"
    __nixche_new_path=
    for __nixche_dir in "''${__nixche_path_dirs[@]}"; do
      if [[ "$__nixche_dir" != "$__nixche_self_dir" ]]; then
        __nixche_new_path="''${__nixche_new_path:+$__nixche_new_path:}$__nixche_dir"
      fi
    done
    export PATH=$__nixche_new_path
    unset __nixche_self_dir __nixche_path_dirs __nixche_new_path __nixche_dir
  '';
  base = f: name: script: f name ''
    ${stripSelf}
    ${script}
  '';

in {
  writeAliasScript = base prev.writeShellScript;
  writeAliasScriptBin = base prev.writeShellScriptBin;
}
