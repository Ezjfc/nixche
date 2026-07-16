# This is a Nixpkgs overlay that allows Neovim to automatically enable Native
# LSPs.

final: prev: {
  neovim = let
    passthru' = prev.callPackage ./package.nix {};
  in prev.neovim.overrideAttrs {
    passthru = (prev.neovim.passthru or {}) // passthru';
  };
}
