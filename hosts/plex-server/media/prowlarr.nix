{...}: let
  constants = import ./constants.nix;
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
}
