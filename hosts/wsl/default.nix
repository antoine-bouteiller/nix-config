{
  globals,
  inputs,
  pkgs,
  ...
}: let
  inherit (globals) user;
in {
  imports = [
    ../base-nixos.nix
  ];

  flakePath = "/home/${user}/.dotfiles";

  wsl = {
    enable = true;
    defaultUser = user;
  };

  # WSL doesn't use systemd-boot
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  # Users
  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    isNormalUser = true;
    description = globals.name;
    extraGroups = ["wheel"];
  };

  system.stateVersion = "25.11";
}
