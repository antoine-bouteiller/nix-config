{
  inputs,
  globals,
  self,
}: let
  inherit (inputs) nixpkgs darwin home-manager sops-nix;
  commonSpecialArgs = {inherit inputs globals;};
in {
  mkDarwinHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }:
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.darwinModules.home-manager
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            networking.hostName = hostname;
          }
          (self + "/hosts/${name}")
        ]
        ++ extraModules;
    };

  mkNixosHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          {networking.hostName = nixpkgs.lib.mkDefault hostname;}
          (self + "/hosts/${name}")
        ]
        ++ extraModules;
    };
}
