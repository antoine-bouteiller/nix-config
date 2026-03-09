{comment-checker-src, ...}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    overlays = [
      (import ../../overlays/comment-checker.nix {inherit comment-checker-src;})
    ];
  };
}
