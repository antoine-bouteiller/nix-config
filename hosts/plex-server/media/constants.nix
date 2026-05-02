{
  network.domain = "antoinebouteiller.fr";

  paths = {
    app = "/var/lib";
    mediaDir = "/mnt/media";
  };

  libraryOwner = {
    user = "root";
    group = "media";
  };

  authelia = {
    port = 9091;
    dataDir = "/var/lib/authelia-main";
    user = "authelia-main";
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

  caddy = {
    user = "caddy";
    group = "caddy";
    logDir = "/var/log/caddy";
    port = 2019;
  };

  coolercontrol.port = 11987;

  crowdsec = {
    port = 8080;
    appsecPort = 7422;
  };

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
