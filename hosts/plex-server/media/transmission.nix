{pkgs, ...}: let
  constants = import ./constants.nix;
  downloadDir = "${constants.paths.mediaDir}/torrents";
in {
  local.adguard.localDnsServices = ["transmission"];

  services.transmission = {
    enable = true;
    user = constants.transmission.user;
    group = constants.transmission.group;
    openRPCPort = false;
    openPeerPorts = false;
    webHome = pkgs.flood-for-transmission;

    settings = {
      download-dir = downloadDir;

      incomplete-dir-enabled = true;
      incomplete-dir = "${downloadDir}/.incomplete";

      watch-dir-enabled = true;
      watch-dir = "${downloadDir}/.watch";

      rpc-port = 9092;
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;

      ratio-limit-enabled = true;
      ratio-limit = 0;
      umask = "002";

      utp-enabled = false;
      encryption = 1;
      port-forwarding-enabled = false;

      peer-port = 51413;

      anti-brute-force-enabled = true;
      anti-brute-force-threshold = 10;
    };
  };

  systemd.tmpfiles.rules = [
    "d '${downloadDir}'             0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${downloadDir}/.incomplete' 0755 ${constants.transmission.user} ${constants.transmission.group} - -"
    "d '${downloadDir}/.watch'      0755 ${constants.transmission.user} ${constants.transmission.group} - -"
  ];
}
