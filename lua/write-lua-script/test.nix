# Test file for write-lua-script
# Run with: nix-instantiate --eval --strict --expr 'import ./test.nix {}'
# (or, without <nixpkgs> in NIX_PATH:
#  nix eval --impure --expr 'import ./test.nix { lib = (builtins.getFlake "nixpkgs").lib; }')

# The real lib is used instead of a mock: lib.generators.toLua is precisely what is under
# test here, so mocking it would test nothing.
{ lib ? import <nixpkgs/lib> }: let
  # Mock of writeText: coerces to a recognisable store path like the real one, while
  # keeping the written content around for the assertions below.
  mockPkgs = rec {
    writeText = name: text: writeTextFile { inherit name text; };
    writeTextFile = { name, text, destination ? "", ... }: {
      outPath = "/nix/store/mock-${name}";
      inherit text destination;
    };
  };

  # Mock derivation: coerced through outPath, like a real one.
  mockHello = { outPath = "/nix/store/mock-hello"; };

  write-lua-script = import ./package.nix {
    inherit lib;
    inherit (mockPkgs) writeText writeTextFile;
  };

  # Test a plain script with a derivation list attribute.
  test1 = write-lua-script.writeLuaScript {
    name = "greet";
    text = ''
      local env = ...
      print(env.name, env.buildInputs[1])
    '';
    buildInputs = [ mockHello ];
  };

  # Test coercion of scalars and nested attribute sets.
  test2 = write-lua-script.writeLuaScript {
    name = "nested";
    text = "return ...";
    settings = {
      enable = true;
      jobs = 4;
    };
  };

  # Test that attributes which cannot coerce are dropped.
  test3 = write-lua-script.writeLuaScript {
    name = "dropped";
    text = "return ...";
    keep = "yes";
    passthru = _: null;
  };

  # Test the share variant: same wrapper, only placed in a directory.
  test4 = write-lua-script.writeLuaScriptShare {
    name = "greet";
    text = ''
      local env = ...
      print(env.name, env.buildInputs[1])
    '';
    buildInputs = [ mockHello ];
  };

  # POSIX ERE as used by builtins.match rejects backslash-escaped brackets and
  # parentheses, so they are matched through one-character classes instead.
  binding = key: ''.*[[]"${key}"[]] = '';

in {
  inherit (test1) text;
  paths = map toString [ test1 test2 test3 test4 ];

  # Simple assertion tests
  assertions = {
    # What is returned is the wrapper, not the source.
    test1IsWrapper = "${test1}" == "/nix/store/mock-greet.lua";

    test1LoadsSource = builtins.match
      ''.*assert[(]loadfile[(]"/nix/store/mock-greet-source\.lua"[)][)].*'' test1.text != null;
    test1CoercesDerivation = builtins.match
      ''${binding "buildInputs"}[{][^}]*"/nix/store/mock-hello".*'' test1.text != null;
    # `text` is passed verbatim, escaped by toJSON.
    test1PassesText = builtins.match ''${binding "text"}"local env = \.\.\..*'' test1.text != null;
    test1PassesName = builtins.match ''${binding "name"}"greet".*'' test1.text != null;

    # Scalars coerce to strings, attrsets keep their shape.
    test2CoercesBool = builtins.match ''${binding "enable"}"1".*'' test2.text != null;
    test2CoercesInt = builtins.match ''${binding "jobs"}"4".*'' test2.text != null;
    test2KeepsNesting = builtins.match ''${binding "settings"}[{].*'' test2.text != null;

    test3DropsFunction = builtins.match ".*passthru.*" test3.text == null;
    test3KeepsRest = builtins.match ''${binding "keep"}"yes".*'' test3.text != null;

    # The share variant only relocates the wrapper.
    test4IsDirectory = "${test4}" == "/nix/store/mock-greet";
    test4Destination = test4.destination == "/share/greet.lua";
    test4SameWrapper = test4.text == test1.text;
  };
}
