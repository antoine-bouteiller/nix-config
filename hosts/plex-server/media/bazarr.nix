{...}: let
  constants = import ./constants.nix;
in {
  local.adguard.localDnsServices = ["bazarr"];

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
