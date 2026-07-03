{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # External Claude Code skills, pinned as non-flake sources.
    ast-grep-skill = {
      url = "github:ast-grep/claude-skill";
      flake = false;
    };
    agent-browser-skill = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
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
      "update-claude" = mkApp "update-claude" system;
    };
  in {
    apps = nixpkgs.lib.genAttrs allSystems mkApps;

    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
        {
          comment-checker = pkgs.callPackage ./pkgs/comment-checker.nix {};
          vite-plus = pkgs.callPackage ./pkgs/vite-plus {};
          whitesur-icon-theme = pkgs.callPackage ./pkgs/whitesur-icon-theme.nix {
            overlay = ./home-manager/themes/WhiteSur-icon-overlay;
          };
          claude-code = pkgs.callPackage ./pkgs/claude-code {};
          sonarqube-cli = pkgs.callPackage ./pkgs/sonarqube-cli {};
          caddy-cloudflare = pkgs.callPackage ./pkgs/caddy-cloudflare {};
          fff-mcp = pkgs.callPackage ./pkgs/fff-mcp {};
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          nearby-file-share = pkgs.callPackage ./pkgs/nearby-file-share.nix {};
        }
    );

    # treefmt (alejandra/deadnix/statix/typos/oxfmt/renovate-validator).
    # Run with `nix fmt`; also invoked by the git pre-commit hook.
    formatter = forAllSystems (
      system: (inputs.treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix).config.build.wrapper
    );

    # `nix develop` installs gitleaks + treefmt as a pre-commit hook (run once).
    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
      };
    });

    checks = forAllSystems (
      system: let
        pre-commit-check = inputs.git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # No built-in gitleaks hook; scan staged changes with our config.
            gitleaks = {
              enable = true;
              name = "gitleaks";
              entry = "${nixpkgs.legacyPackages.${system}.gitleaks}/bin/gitleaks protect --staged --config .gitleaks.toml";
              pass_filenames = false;
            };
            treefmt = {
              enable = true;
              package = self.formatter.${system};
            };
          };
        };
        darwinChecks = nixpkgs.lib.optionalAttrs (builtins.elem system darwinSystems) (
          nixpkgs.lib.mapAttrs (_: cfg: cfg.system) self.darwinConfigurations
        );
        nixosChecks = nixpkgs.lib.optionalAttrs (builtins.elem system linuxSystems) (
          nixpkgs.lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) self.nixosConfigurations
        );
      in
        darwinChecks // nixosChecks // {inherit pre-commit-check;}
    );

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
