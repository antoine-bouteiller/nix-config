{
  inputs,
  lib,
  pkgs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.system};
in {
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
    wget
    zip

    # Encryption and security tools
    gnupg

    # Node.js development tools
    nodejs_24
    bun

    # Python
    python313

    # Java
    jdk25_headless

    # Text and terminal utilities
    htop
    jq
    ripgrep
    tree
    tmux
    unzip
    eza

    # Shell tools
    zoxide
    carapace
    direnv
    fzf

    # Development tools
    curl
    gh
    lazygit
    alejandra
    nixd
    customPkgs.comment-checker
    ffmpeg
    customPkgs.rtk
    customPkgs._1mcp
  ];
}
