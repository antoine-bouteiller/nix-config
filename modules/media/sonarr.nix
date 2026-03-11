{
  pkgs,
  config,
  ...
}: let
  cfg = config.mediaServer;
in {
  services.sonarr = {
    enable = true;
    dataDir = cfg.sonarr.dataDir;
    group = cfg.libraryOwner.group;

    settings = {
      server.bindAddress = "*";
      auth.method = "external";
      postgres = {
        host = "/run/postgresql";
        port = 5432;
        user = "sonarr";
        mainDb = "sonarr";
        logDb = "sonarr-log";
      };
    };
  };

  services.caddy.virtualHosts."sonarr.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.sonarr.port} {
        header_down -Access-Control-Allow-Origin
      }
    '';
  };

  services.postgresql = {
    ensureDatabases = ["sonarr" "sonarr-log"];
    ensureUsers = [
      {
        name = "sonarr";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.postgresql-setup.script = pkgs.lib.mkAfter ''
    psql -tAc "ALTER DATABASE \"sonarr-log\" OWNER TO sonarr"
  '';

  systemd.services.sonarr = {
    after = ["postgresql-setup.service"];
    requires = ["postgresql-setup.service"];
    serviceConfig.UMask = pkgs.lib.mkForce "002";
  };

  systemd.tmpfiles.rules = [
    "d '${cfg.paths.mediaDir}/torrents/sonarr' 0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
  ];

  users.users.sonarr.extraGroups = [cfg.libraryOwner.group];
}
