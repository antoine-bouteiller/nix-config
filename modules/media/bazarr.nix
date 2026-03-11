{config, ...}: let
  cfg = config.mediaServer;
in {
  services.bazarr = {
    enable = true;
    group = cfg.libraryOwner.group;
    dataDir = cfg.bazarr.dataDir;
  };

  services.postgresql = {
    ensureDatabases = ["bazarr"];
    ensureUsers = [
      {
        name = "bazarr";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.bazarr = {
    after = ["postgresql-setup.service"];
    requires = ["postgresql-setup.service"];
    environment = {
      POSTGRES_ENABLED = "true";
      POSTGRES_HOST = "/run/postgresql";
      POSTGRES_PORT = "5432";
      POSTGRES_DATABASE = "bazarr";
      POSTGRES_USERNAME = "bazarr";
    };
  };

  services.caddy.virtualHosts."bazarr.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.bazarr.port}
    '';
  };

  users.users.bazarr.isSystemUser = true;
  users.users.bazarr.group = cfg.libraryOwner.group;
}
