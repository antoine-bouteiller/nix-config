{config, ...}: let
  constants = import ./constants.nix;
in {
  services.immich = {
    enable = true;
    mediaLocation = "${constants.paths.mediaDir}/immich";

    # cloudflared on loopback forwards real client IPs via X-Forwarded-For;
    # trust the loopback hop so logs / brute-force counters see actual IPs.
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

  local.media.immich = {
    host = "photo";
    port = config.services.immich.port;
    public = true;
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
