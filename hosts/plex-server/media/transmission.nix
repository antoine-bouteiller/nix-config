{pkgs, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCloudflaredIngress;
  downloadDir = "${constants.paths.mediaDir}/torrents";
in {
  services.transmission = {
    enable = true;
    user = constants.transmission.user;
    group = constants.transmission.group;
    openRPCPort = false;
    openPeerPorts = true;
    webHome = pkgs.flood-for-transmission;

    settings = {
      download-dir = downloadDir;

      incomplete-dir-enabled = true;
      incomplete-dir = "${downloadDir}/.incomplete";

      watch-dir-enabled = true;
      watch-dir = "${downloadDir}/.watch";

      rpc-port = constants.transmission.port;
      rpc-bind-address = "127.0.0.1";
      rpc-host-whitelist-enabled = false;

      ratio-limit-enabled = true;
      ratio-limit = 0;
      umask = "002";

      utp-enabled = false;
      encryption = 1;
      port-forwarding-enabled = false;

      peer-port = constants.transmission.peerPort;

      anti-brute-force-enabled = true;
      anti-brute-force-threshold = 10;
    };
  };

  systemd.tmpfiles.rules = [
    "d '${downloadDir}'             0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${downloadDir}/.incomplete' 0755 ${constants.transmission.user} ${constants.transmission.group} - -"
    "d '${downloadDir}/.watch'      0755 ${constants.transmission.user} ${constants.transmission.group} - -"
  ];

  services.cloudflared.tunnels.${constants.cloudflared.tunnelId}.ingress = mkCloudflaredIngress {
    name = "torrent";
    port = constants.transmission.port;
  };
}
