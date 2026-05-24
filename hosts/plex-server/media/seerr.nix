{config, ...}: let
  constants = import ./constants.nix;
in {
  services.seerr = {
    enable = true;
    configDir = constants.seerr.dataDir;
  };

  local.media.seerr = {
    host = "";
    port = config.services.seerr.port;
    auth = true;
    public = true;
  };

  systemd.services.seerr = {
    environment = {
      LOG_LEVEL = "info";
    };
  };
}
