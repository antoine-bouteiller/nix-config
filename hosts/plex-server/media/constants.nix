{
  network = {
    domain = "antoinebouteiller.fr";
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
    user = "autoscan";
    group = "autoscan";
    dataDir = "/var/lib/autoscan";
  };

  bazarr = {
    user = "bazarr";
    group = "media";
    dataDir = "/var/lib/bazarr";
  };

  # The cloudflared tunnel UUID (printed by `cloudflared tunnel create`).
  # The matching credentials JSON is stored in sops as
  # `cloudflared/credentials` and rendered at /run/secrets/.
  cloudflared.tunnelId = "8bf26bb6-b100-4e7f-9016-2d74c6deb378";

  coolercontrol.port = 11987;

  authelia.port = 9091;

  plex = {
    # Upstream services.plex hard-codes this port in its firewall rules but
    # does not expose it as a typed config option.
    port = 32400;
    user = "plex";
    group = "media";
    dataDir = "/var/lib/plex";
  };

  caddy = {
    user = "caddy";
    group = "caddy";
    logDir = "/var/log/caddy";
    port = 2019;
  };

  postgres.user = "postgres";

  prowlarr = {
    user = "prowlarr";
    group = "prowlarr";
    dataDir = "/var/lib/prowlarr";
  };

  radarr = {
    user = "radarr";
    group = "media";
    dataDir = "/var/lib/radarr";
  };

  recyclarr = {
    user = "recyclarr";
    group = "recyclarr";
  };

  seerr = {
    user = "seerr";
    group = "seerr";
    dataDir = "/var/lib/jellyseerr";
  };

  sonarr = {
    user = "sonarr";
    group = "media";
    dataDir = "/var/lib/sonarr";
  };

  transmission = {
    user = "transmission";
    group = "media";
  };
}
