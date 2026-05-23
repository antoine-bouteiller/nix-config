{
  config,
  pkgs,
  ...
}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkLocalCaddyVirtualHost;
in {
  local.media.localServices.radarr.localDns.enable = true;

  services.radarr = {
    enable = true;
    dataDir = constants.radarr.dataDir;
    group = constants.libraryOwner.group;

    settings = {
      server.bindAddress = "*";
      auth.method = "external";
      postgres = {
        host = "/run/pgbouncer";
        port = 5432;
        user = "radarr";
        mainDb = "radarr";
        logDb = "radarr-log";
      };
    };
  };

  systemd.services.radarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    serviceConfig.UMask = pkgs.lib.mkForce "002";
  };

  services.caddy.virtualHosts = mkLocalCaddyVirtualHost {
    domain = config.local.media.localServices.radarr.localDomain;
    port = config.services.radarr.settings.server.port;
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/torrents/radarr' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.radarr.extraGroups = [constants.libraryOwner.group];
}
