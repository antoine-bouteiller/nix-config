{
  lib,
  hostUser,
  ...
}: {
  imports = [
    ../../home-manager/common.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = hostUser;
    homeDirectory = lib.mkForce "/home/${hostUser}";
    stateVersion = "25.11";
  };
}
