{
  config,
  pkgs,
  ...
}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkLocalCaddyVirtualHost;
in {
  local.media.localServices.sonarr.localDns.enable = true;

  services.sonarr = {
    enable = true;
    dataDir = constants.sonarr.dataDir;
    group = constants.libraryOwner.group;

    settings = {
      server.bindAddress = "*";
      auth.method = "external";
      postgres = {
        host = "/run/pgbouncer";
        port = 5432;
        user = "sonarr";
        mainDb = "sonarr";
        logDb = "sonarr-log";
      };
    };
  };

  systemd.services.sonarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    serviceConfig.UMask = pkgs.lib.mkForce "002";
  };

  services.caddy.virtualHosts = mkLocalCaddyVirtualHost {
    domain = config.local.media.localServices.sonarr.localDomain;
    port = config.services.sonarr.settings.server.port;
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/torrents/sonarr' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.sonarr.extraGroups = [constants.libraryOwner.group];
}
