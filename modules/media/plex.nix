{config, ...}: let
  cfg = config.mediaServer;
in {
  services.plex = {
    enable = true;
    dataDir = cfg.plex.dataDir;
  };

  services.caddy.virtualHosts."plex.${cfg.network.domain}" = {
    extraConfig = ''
      reverse_proxy localhost:${toString cfg.plex.port} {
          header_up Host {host}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d '${cfg.paths.mediaDir}/library'        0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    "d '${cfg.paths.mediaDir}/library/movies' 0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    "d '${cfg.paths.mediaDir}/library/tv'     0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    "d '${cfg.paths.mediaDir}/transcode'      0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
  ];

  users.users.plex.extraGroups = [cfg.libraryOwner.group];
}
