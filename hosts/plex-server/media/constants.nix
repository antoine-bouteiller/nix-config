{
  network = {
    domain = "antoinebouteiller.fr";
    # Hostnames under this zone are not in public DNS — they're routed
    # through the Cloudflare Tunnel as Zero Trust private resources and
    # only resolve for devices enrolled in WARP.
    internalDomain = "internal.antoinebouteiller.fr";
  };

  paths = {
    app = "/var/lib";
    mediaDir = "/mnt/media";
  };

  libraryOwner = {
    user = "root";
    group = "media";
  };

  autoscan = {
    port = 3030;
    user = "autoscan";
    group = "autoscan";
    dataDir = "/var/lib/autoscan";
  };

  bazarr = {
    port = 6767;
    user = "bazarr";
    group = "media";
    dataDir = "/var/lib/bazarr";
  };

  # The cloudflared tunnel UUID (printed by `cloudflared tunnel create`).
  # The matching credentials JSON is stored in sops as
  # `cloudflared/credentials` and rendered at /run/secrets/.
  cloudflared.tunnelId = "REPLACE_WITH_TUNNEL_UUID";

  coolercontrol.port = 11987;

  byparr.port = 8191;

  homepage.port = 8082;

  immich.port = 2283;

  plex = {
    port = 32400;
    user = "plex";
    group = "media";
    dataDir = "/var/lib/plex";
  };

  postgres.user = "postgres";

  prowlarr = {
    port = 9696;
    user = "prowlarr";
    group = "prowlarr";
    dataDir = "/var/lib/prowlarr";
  };

  radarr = {
    port = 7878;
    user = "radarr";
    group = "media";
    dataDir = "/var/lib/radarr";
  };

  recyclarr = {
    user = "recyclarr";
    group = "recyclarr";
  };

  seerr = {
    port = 5055;
    user = "seerr";
    group = "seerr";
    dataDir = "/var/lib/jellyseerr";
  };

  sonarr = {
    port = 8989;
    user = "sonarr";
    group = "media";
    dataDir = "/var/lib/sonarr";
  };

  transmission = {
    port = 9092;
    peerPort = 51413;
    user = "transmission";
    group = "media";
  };
}
