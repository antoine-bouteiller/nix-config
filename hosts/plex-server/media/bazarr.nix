{config, ...}: let
  constants = import ./constants.nix;
in {
  local.media.bazarr.localDns = {
    enable = true;
    port = config.services.bazarr.listenPort;
  };

  services.bazarr = {
    enable = true;
    group = constants.libraryOwner.group;
    dataDir = constants.bazarr.dataDir;
  };

  systemd.services.bazarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    environment = {
      POSTGRES_ENABLED = "true";
      POSTGRES_HOST = "/run/pgbouncer";
      POSTGRES_PORT = "5432";
      POSTGRES_DATABASE = "bazarr";
      POSTGRES_USERNAME = "bazarr";
    };
  };

  users.users.bazarr.isSystemUser = true;
  users.users.bazarr.group = constants.libraryOwner.group;
}
