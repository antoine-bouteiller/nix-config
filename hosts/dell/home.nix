{
  lib,
  hostUser,
  ...
}: {
  imports = [
    ../../home-manager
  ];

  local.home-manager = {
    claudeCode.enable = true;
    tmux.enable = true;
    zed.enable = true;
    ghostty.enable = true;
  };

  home = {
    enableNixpkgsReleaseCheck = false;
    username = hostUser;
    homeDirectory = lib.mkForce "/home/${hostUser}";
    stateVersion = "25.11";
  };
}
