{
  config,
  pkgs,
  ...
}: let
  constants = import ./constants.nix;
in {
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

  local.media.radarr = {
    port = config.services.radarr.settings.server.port;
    auth = true;
  };

  systemd.services.radarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    serviceConfig.UMask = pkgs.lib.mkForce "002";
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/torrents/radarr' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.radarr.extraGroups = [constants.libraryOwner.group];
}
