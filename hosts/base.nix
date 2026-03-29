{
  lib,
  pkgs,
  ...
}: {
  imports = [../modules];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    allowInsecure = false;
    allowUnsupportedSystem = true;
  };

  nix = {
    package = pkgs.lixPackageSets.stable.lix;

    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://nix-community.cachix.org" "https://cache.nixos.org"];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      options = lib.mkDefault "--delete-older-than 30d";
    };
  };

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    bat
    openssh
    zip
    unzip

    # Text and terminal utilities
    htop
    jq
    ripgrep
    tree
    tmux
    eza

    # Development tools
    curl
    gh
    lazygit
    alejandra
    nixd
    ffmpeg
  ];
}
