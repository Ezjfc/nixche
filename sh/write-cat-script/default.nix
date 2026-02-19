{
  writeShellScript,
  writeShellScriptBin,

  colour ? "\\e[0;35m", # Dark purple.
}: let
  reset = "\\e[0m";
  base = f: name: script: f name ''
    echo -e "${colour}"
    cat "$0" >&2
    echo -e "${reset}"

    ${script}
  '';

in {
  writeCatScript = base writeShellScript;
  writeCatScriptBin = base writeShellScriptBin;
}
