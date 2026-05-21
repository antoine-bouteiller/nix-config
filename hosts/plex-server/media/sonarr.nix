{pkgs, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCloudflaredIngress;
in {
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

  services.cloudflared.tunnels.${constants.cloudflared.tunnelId}.ingress = mkCloudflaredIngress {
    name = "sonarr";
    port = constants.sonarr.port;
  };

  systemd.services.sonarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    serviceConfig.UMask = pkgs.lib.mkForce "002";
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/torrents/sonarr' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.sonarr.extraGroups = [constants.libraryOwner.group];
}
