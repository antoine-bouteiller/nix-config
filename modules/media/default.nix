{lib, ...}: let
  inherit (lib) mkOption types;
in {
  imports = [
    ./caddy.nix
    ./authelia.nix
    ./postgres.nix
    ./plex.nix
    ./jellyseerr.nix
    ./sonarr.nix
    ./radarr.nix
    ./prowlarr
    ./bazarr.nix
    ./transmission.nix
    ./recyclarr.nix
    ./homepage.nix
    ./flaresolverr.nix
    ./coolercontrol.nix
    ./autoscan.nix
    ./immich.nix
    ./smartd.nix
  ];

  options.mediaServer = {
    # Host-specific (no defaults)
    network.domain = mkOption {
      type = types.str;
      description = "Domain name for media services";
    };

    paths = {
      app = mkOption {
        type = types.str;
        default = "/var/lib";
        description = "Base directory for application data";
      };
      mediaDir = mkOption {
        type = types.str;
        description = "Path to the media storage directory";
      };
    };

    libraryOwner = {
      user = mkOption {
        type = types.str;
        default = "root";
      };
      group = mkOption {
        type = types.str;
        default = "media";
      };
    };

    # Service configurations with defaults
    authelia = {
      port = mkOption {
        type = types.port;
        default = 9091;
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/authelia-main";
      };
    };

    autoscan = {
      port = mkOption {
        type = types.port;
        default = 3030;
      };
      user = mkOption {
        type = types.str;
        default = "autoscan";
      };
      group = mkOption {
        type = types.str;
        default = "autoscan";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/autoscan";
      };
    };

    bazarr = {
      port = mkOption {
        type = types.port;
        default = 6767;
      };
      user = mkOption {
        type = types.str;
        default = "bazarr";
      };
      group = mkOption {
        type = types.str;
        default = "media";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/bazarr";
      };
    };

    coolercontrol.port = mkOption {
      type = types.port;
      default = 11987;
    };

    flaresolverr.port = mkOption {
      type = types.port;
      default = 8191;
    };

    homepage.port = mkOption {
      type = types.port;
      default = 8082;
    };

    immich.port = mkOption {
      type = types.port;
      default = 2283;
    };

    jellyseerr = {
      port = mkOption {
        type = types.port;
        default = 5055;
      };
      user = mkOption {
        type = types.str;
        default = "jellyseerr";
      };
      group = mkOption {
        type = types.str;
        default = "jellyseerr";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/jellyseerr";
      };
    };

    plex = {
      port = mkOption {
        type = types.port;
        default = 32400;
      };
      user = mkOption {
        type = types.str;
        default = "plex";
      };
      group = mkOption {
        type = types.str;
        default = "media";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/plex";
      };
    };

    prowlarr = {
      port = mkOption {
        type = types.port;
        default = 9696;
      };
      user = mkOption {
        type = types.str;
        default = "prowlarr";
      };
      group = mkOption {
        type = types.str;
        default = "prowlarr";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/prowlarr";
      };
    };

    radarr = {
      port = mkOption {
        type = types.port;
        default = 7878;
      };
      user = mkOption {
        type = types.str;
        default = "radarr";
      };
      group = mkOption {
        type = types.str;
        default = "media";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/radarr";
      };
    };

    recyclarr = {
      user = mkOption {
        type = types.str;
        default = "recyclarr";
      };
      group = mkOption {
        type = types.str;
        default = "recyclarr";
      };
    };

    sonarr = {
      port = mkOption {
        type = types.port;
        default = 8989;
      };
      user = mkOption {
        type = types.str;
        default = "sonarr";
      };
      group = mkOption {
        type = types.str;
        default = "media";
      };
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/sonarr";
      };
    };

    transmission = {
      port = mkOption {
        type = types.port;
        default = 9092;
      };
      peerPort = mkOption {
        type = types.port;
        default = 51413;
      };
      user = mkOption {
        type = types.str;
        default = "transmission";
      };
      group = mkOption {
        type = types.str;
        default = "media";
      };
    };

    ygege.port = mkOption {
      type = types.port;
      default = 8715;
    };
  };
}
