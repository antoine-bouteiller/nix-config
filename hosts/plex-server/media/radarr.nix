{pkgs, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCloudflaredIngress;
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

  services.cloudflared.tunnels.${constants.cloudflared.tunnelId}.ingress = mkCloudflaredIngress {
    name = "radarr";
    port = constants.radarr.port;
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
