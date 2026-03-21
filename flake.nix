{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    comment-checker-src = {
      url = "github:code-yeongyu/go-claude-code-comment-checker";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    autoscan = {
      url = "github:antoine-bouteiller/autoscan";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rtk-src = {
      url = "github:rtk-ai/rtk";
      flake = false;
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    darwin,
    nix-homebrew,
    homebrew-bundle,
    homebrew-core,
    homebrew-cask,
    comment-checker-src,
    home-manager,
    nixpkgs,
    sops-nix,
    autoscan,
    nixos-wsl,
    rtk-src,
  } @ inputs: let
    globals = import ./globals.nix;
    overlays = [
      (import ./overlays/comment-checker.nix {comment-checker-src = comment-checker-src;})
      (import ./overlays/vite-plus.nix)
      (import ./overlays/rtk.nix {inherit rtk-src;})
    ];
    linuxSystems = ["x86_64-linux"];
    darwinSystems = ["aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
    devShell = system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = with pkgs;
        mkShell {
          nativeBuildInputs = with pkgs; [bashInteractive git];
          shellHook = ''
            export EDITOR=vim
          '';
        };
    };
    mkApp = scriptName: system: {
      type = "app";
      program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
        #!/usr/bin/env bash
        PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
        echo "Running ${scriptName} for ${system}"
        exec ${self}/apps/${system}/${scriptName}
      '')}/bin/${scriptName}";
    };
    mkApps = system: {
      "apply" = mkApp "apply" system;
      "clean" = mkApp "clean" system;
    };
  in {
    devShells = forAllSystems devShell;
    apps = nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) mkApps;

    darwinConfigurations.pelico = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {inherit inputs globals;};
      modules = [
        {nixpkgs.overlays = overlays;}
        home-manager.darwinModules.home-manager
        nix-homebrew.darwinModules.nix-homebrew
        ./hosts/pelico
      ];
    };

    nixosConfigurations = {
      plex-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs globals;};
        modules = [
          {nixpkgs.overlays = overlays;}
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          autoscan.nixosModules.default
          ./hosts/plex-server
        ];
      };

      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs globals;};
        modules = [
          {nixpkgs.overlays = overlays;}
          home-manager.nixosModules.home-manager
          nixos-wsl.nixosModules.default
          ./hosts/wsl
        ];
      };
    };
  };
}
