{
  globals,
  pkgs,
  ...
}: let
  user = globals.user;
in {
  imports = [
    ../base-nixos.nix
  ];

  wsl = {
    enable = true;
    defaultUser = user;
  };

  # WSL doesn't use systemd-boot
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  networking.hostName = "wsl";

  # Home manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit globals;
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
    openssh.authorizedKeys.keys = globals.sshKeys;
  };

  system.stateVersion = "25.11";
}
