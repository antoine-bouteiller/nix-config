{
  config,
  pkgs,
  ...
}: let
  cfg = config.mediaServer;
  downloadDir = "${cfg.paths.mediaDir}/torrents";
in {
  services.transmission = {
    enable = true;
    user = cfg.transmission.user;
    group = cfg.transmission.group;
    openRPCPort = false;
    openPeerPorts = true;
    webHome = pkgs.flood-for-transmission;

    settings = {
      download-dir = downloadDir;

      incomplete-dir-enabled = true;
      incomplete-dir = "${downloadDir}/.incomplete";

      watch-dir-enabled = true;
      watch-dir = "${downloadDir}/.watch";

      rpc-port = cfg.transmission.port;
      rpc-bind-address = "127.0.0.1";
      rpc-host-whitelist-enabled = false;

      ratio-limit-enabled = true;
      ratio-limit = 0;
      umask = "002";

      utp-enabled = false;
      encryption = 1;
      port-forwarding-enabled = false;

      peer-port = cfg.transmission.peerPort;

      anti-brute-force-enabled = true;
      anti-brute-force-threshold = 10;
    };
  };

  systemd.tmpfiles.rules = [
    "d '${downloadDir}'             0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    "d '${downloadDir}/.incomplete' 0755 ${cfg.transmission.user} ${cfg.transmission.group} - -"
    "d '${downloadDir}/.watch'      0755 ${cfg.transmission.user} ${cfg.transmission.group} - -"
  ];

  services.caddy.virtualHosts."torrent.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.transmission.port}
    '';
  };
}
