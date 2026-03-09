{
  globals,
  pkgs,
  lib,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      (
        lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${globals.user}/.ssh/config_external"
      )
      (
        lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${globals.user}/.ssh/config_external"
      )
    ];
    matchBlocks = {
      "*" = {
        sendEnv = ["LANG" "LC_*"];
        hashKnownHosts = true;
      };
    };
  };
}
