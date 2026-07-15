# This is a Nixpkgs overlay that patches Neovim to automatically enable Native
# LSPs. Kept for backward compatibility: the actual builder lives in
# package.nix, which can also be called directly with callPackage.
final: prev: {
  neovim = let
    withLsps = prev.callPackage ./package.nix {};
    passthru' = {
      inherit withLsps;
    };
  in prev.neovim.overrideAttrs {
    passthru = (prev.neovim.passthru or {}) // passthru';
  };
}
