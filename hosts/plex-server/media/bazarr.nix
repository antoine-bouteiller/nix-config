{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCloudflaredIngress;
in {
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

  services.cloudflared.tunnels.${constants.cloudflared.tunnelId}.ingress = mkCloudflaredIngress {
    name = "bazarr";
    port = constants.bazarr.port;
  };

  users.users.bazarr.isSystemUser = true;
  users.users.bazarr.group = constants.libraryOwner.group;
}
