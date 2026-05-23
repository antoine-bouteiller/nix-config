{config, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkLocalCaddyVirtualHost;
in {
  local.media.localServices.prowlarr.localDns.enable = true;

  services.prowlarr = {
    enable = true;
    dataDir = constants.prowlarr.dataDir;

    settings = {
      auth.method = "external";
      postgres = {
        host = "/run/pgbouncer";
        port = 5432;
        user = "prowlarr";
        mainDb = "prowlarr";
        logDb = "prowlarr-log";
      };
    };
  };

  systemd.services.prowlarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
  };

  services.caddy.virtualHosts = mkLocalCaddyVirtualHost {
    domain = config.local.media.localServices.prowlarr.localDomain;
    port = config.services.prowlarr.settings.server.port;
  };
}
