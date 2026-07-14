# Test file for write-alias-script
# Run with: nix-instantiate --eval --strict test.nix

let
  # Mock pkgs for testing
  mockPkgs = rec {
    writeShellScript = name: script: ''
      #!/usr/bin/env bash
      ${script}
    '';
    writeShellScriptBin = name: script: writeShellScript name script;
  };

  write-alias-utils = import ./default.nix {
    inherit (mockPkgs) writeShellScript writeShellScriptBin;
  };

  # An alias calling the very command it is named after
  test1 = write-alias-utils.writeAliasScript "ls" ''
    ls --color=auto "$@"
  '';

  test2 = write-alias-utils.writeAliasScriptBin "grep" ''
    grep --line-number "$@"
  '';

in {
  inherit test1 test2;

  # Simple assertion tests
  assertions = {
    test1StripsSelfDir = builtins.match ".*__nixche_self_dir=\\$\\{0%/\\*}.*" test1 != null;
    test1ExportsPath = builtins.match ".*export PATH=\\$__nixche_new_path.*" test1 != null;
    test1KeepsScript = builtins.match ".*ls --color=auto \"\\$@\".*" test1 != null;
    test1StripsBeforeScript =
      builtins.match ".*export PATH=.*ls --color=auto.*" test1 != null;
    test2KeepsScript = builtins.match ".*grep --line-number \"\\$@\".*" test2 != null;
  };
}
