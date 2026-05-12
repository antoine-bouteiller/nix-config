{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  services.immich = {
    enable = true;
    port = constants.immich.port;
    mediaLocation = "${constants.paths.mediaDir}/immich";

    # Trust Caddy on loopback so request.ip / failed-login logs carry the
    # real client IP via X-Forwarded-For — required for the CrowdSec
    # gauth-fr/immich-bf brute-force scenario to ban actual attackers
    # instead of the reverse proxy.
    environment.IMMICH_TRUSTED_PROXIES = "127.0.0.1,::1";

    database = {
      enable = true;
      createDB = false;
      host = "/run/postgresql";
      port = 5432;
      name = "immich";
      user = "immich";
    };
  };

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = "photo.${constants.network.domain}";
    port = constants.immich.port;
  };

  systemd.services.immich-machine-learning = {
    serviceConfig = {
      MemoryMax = "3G";
      MemorySwapMax = "0B";
    };
  };

  systemd.services.immich-server = {
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
  };

  users.users.immich.extraGroups = [constants.libraryOwner.group];
}
