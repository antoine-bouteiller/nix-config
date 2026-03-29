{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
in {
  config = lib.mkIf cfg.enable {
    services.jellyseerr = {
      enable = true;
      configDir = cfg.jellyseerr.dataDir;
    };

    services.caddy.virtualHosts."${cfg.network.domain}" = {
      extraConfig = "reverse_proxy localhost:${toString cfg.jellyseerr.port}";
    };
  };
}
