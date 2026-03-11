{
  lib,
  config,
  ...
}: let
  cfg = config.mediaServer;
in {
  imports = [./custom-def];

  services.prowlarr = {
    enable = true;
    dataDir = cfg.prowlarr.dataDir;

    settings = {
      auth.method = "external";
      postgres = {
        host = "/run/postgresql";
        port = 5432;
        user = "prowlarr";
        mainDb = "prowlarr";
        logDb = "prowlarr-log";
      };
    };
  };

  services.postgresql = {
    ensureDatabases = ["prowlarr" "prowlarr-log"];
    ensureUsers = [
      {
        name = "prowlarr";
      }
    ];
  };

  systemd.services.postgresql-setup.script = lib.mkAfter ''
    psql -tAc "ALTER DATABASE \"prowlarr\" OWNER TO prowlarr"
    psql -tAc "ALTER DATABASE \"prowlarr-log\" OWNER TO prowlarr"
  '';

  systemd.services.prowlarr = {
    after = ["postgresql-setup.service"];
    requires = ["postgresql-setup.service"];
  };

  services.caddy.virtualHosts."prowlarr.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.prowlarr.port} {
        header_down -Access-Control-Allow-Origin
      }
    '';
  };
}
