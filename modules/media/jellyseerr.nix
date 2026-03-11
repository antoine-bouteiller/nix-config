{config, ...}: let
  cfg = config.mediaServer;
in {
  services.jellyseerr = {
    enable = true;
    configDir = cfg.jellyseerr.dataDir;
  };

  services.caddy.virtualHosts."${cfg.network.domain}" = {
    extraConfig = "reverse_proxy localhost:${toString cfg.jellyseerr.port}";
  };
}
