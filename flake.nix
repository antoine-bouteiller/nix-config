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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    autoscan = {
      url = "github:antoine-bouteiller/autoscan";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    globals = import ./globals.nix;
    libHelpers = import ./lib {inherit inputs globals self;};
    inherit (libHelpers) mkDarwinHost mkNixosHost;

    linuxSystems = ["x86_64-linux"];
    darwinSystems = ["aarch64-darwin"];
    allSystems = linuxSystems ++ darwinSystems;
    forAllSystems = f: nixpkgs.lib.genAttrs allSystems f;

    mkApp = scriptName: system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      type = "app";
      program = "${(pkgs.writeScriptBin scriptName ''
        #!/usr/bin/env bash
        PATH=${pkgs.git}/bin:${pkgs.jq}/bin:$PATH
        echo "Running ${scriptName} for ${system}"
        exec ${self}/apps/${system}/${scriptName}
      '')}/bin/${scriptName}";
    };
    mkApps = system: {
      "apply" = mkApp "apply" system;
      "clean" = mkApp "clean" system;
      "update" = mkApp "update" system;
    };
  in {
    apps = nixpkgs.lib.genAttrs allSystems mkApps;

    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      {
        comment-checker = pkgs.callPackage ./pkgs/comment-checker.nix {};
        rtk = pkgs.callPackage ./pkgs/rtk.nix {};
        vite-plus = pkgs.callPackage ./pkgs/vite-plus {};
        _1mcp = pkgs.callPackage ./pkgs/1mcp.nix {};
        whitesur-icon-theme = pkgs.callPackage ./pkgs/whitesur-icon-theme.nix {
          overlay = ./home-manager/themes/WhiteSur-icon-overlay;
        };
      }
      // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
        nearby-file-share = pkgs.callPackage ./pkgs/nearby-file-share.nix {};
        caddy-crowdsec = pkgs.callPackage ./pkgs/caddy-crowdsec.nix {};
      });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    checks = forAllSystems (system: let
      darwinChecks = nixpkgs.lib.optionalAttrs (builtins.elem system darwinSystems) (
        nixpkgs.lib.mapAttrs (_: cfg: cfg.system) self.darwinConfigurations
      );
      nixosChecks = nixpkgs.lib.optionalAttrs (builtins.elem system linuxSystems) (
        nixpkgs.lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.nixosConfigurations
      );
    in
      darwinChecks // nixosChecks);

    nixosModules = {
      default = ./modules;
      autoUpgrade = ./modules/auto-upgrade.nix;
    };

    darwinModules = {
      default = ./modules;
      autoUpgrade = ./modules/auto-upgrade.nix;
    };

    homeModules = {
      default = ./home-manager;
    };

    darwinConfigurations."lv6cfqjl6l-macos" = mkDarwinHost {
      name = "pelico";
      hostname = "lv6cfqjl6l-macos";
      system = "aarch64-darwin";
    };

    nixosConfigurations = {
      plex-server = mkNixosHost {
        hostname = "plex-server";
        system = "x86_64-linux";
        extraModules = [inputs.autoscan.nixosModules.default];
      };

      "antoine-dell" = mkNixosHost {
        name = "dell";
        hostname = "antoine-dell";
        system = "x86_64-linux";
        extraModules = [inputs.nixos-hardware.nixosModules.dell-xps-15-9500-nvidia];
      };

      wsl = mkNixosHost {
        hostname = "wsl";
        system = "x86_64-linux";
        extraModules = [inputs.nixos-wsl.nixosModules.default];
      };
    };
  };
}
