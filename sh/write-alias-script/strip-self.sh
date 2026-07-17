# Removes the PATH entry this script was resolved from ($0's directory), so a
# command of the same name falls through to the next match in PATH instead of
# recursing into this script. Pasted verbatim into generated wrappers; every
# identifier is namespaced and unset again to keep the environment clean.
__nixche_self_dir=${0%/*}
IFS=: read -r -a __nixche_path_dirs <<< "$PATH"
__nixche_new_path=
for __nixche_dir in "${__nixche_path_dirs[@]}"; do
  if [[ "$__nixche_dir" != "$__nixche_self_dir" ]]; then
    __nixche_new_path="${__nixche_new_path:+$__nixche_new_path:}$__nixche_dir"
  fi
done
export PATH=$__nixche_new_path
unset __nixche_self_dir __nixche_path_dirs __nixche_new_path __nixche_dir
