{config, ...}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "${config.home.homeDirectory}/.ssh/config_external"
    ];
    settings = {
      "*" = {
        SendEnv = ["LANG" "LC_*"];
        HashKnownHosts = true;
      };
    };
  };
}
