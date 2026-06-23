{config, ...}: let
  constants = import ./constants.nix;
  localMedia = config.local.media;
in {
  sops.secrets = {
    "homepage/sonarr_api_key" = {
      key = "sonarr_api_key";
      owner = "homepage-dashboard";
    };
    "homepage/radarr_api_key" = {
      key = "radarr_api_key";
      owner = "homepage-dashboard";
    };
    "homepage/prowlarr_api_key" = {
      key = "prowlarr_api_key";
      owner = "homepage-dashboard";
    };
    "homepage/bazarr_api_key" = {
      key = "bazarr_api_key";
      owner = "homepage-dashboard";
    };
    "homepage/plex_token" = {
      key = "plex_token";
      owner = "homepage-dashboard";
    };
    "homepage/seerr_api_key" = {
      key = "seerr_api_key";
      owner = "homepage-dashboard";
    };
    "homepage/immich_api_key" = {
      key = "immich_api_key";
      owner = "homepage-dashboard";
    };
  };

  users.users.homepage-dashboard = {
    isSystemUser = true;
    group = "homepage-dashboard";
  };
  users.groups.homepage-dashboard = {};

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = localMedia.dashboard.domain;
    settings = {
      title = "Antoine's Dashboard";
      theme = "dark";
      useEqualHeights = true;
      headerStyle = "clean";
      layout = [
        {
          Utilities = {
            header = false;
            style = "row";
            columns = 2;
          };
        }
        {
          Apps = {
            header = false;
            style = "row";
            columns = 2;
          };
        }
        {
          Arr = {
            header = false;
            style = "row";
            columns = 3;
          };
        }
        {
          Infrastructure = {
            header = false;
            style = "row";
            columns = 3;
          };
        }
      ];
    };

    bookmarks = [
      {
        Utilities = [
          {
            Trashguide = [
              {
                icon = "trash-guides.png";
                href = "https://trash-guides.info";
              }
            ];
          }
          {
            Cloudflare = [
              {
                icon = "cloudflare.svg";
                href = "https://dash.cloudflare.com";
              }
            ];
          }
        ];
      }
    ];

    services = [
      {
        Apps = [
          {
            Plex = {
              icon = "plex.svg";
              href = "https://app.plex.tv";
              widget = {
                type = "plex";
                url = "http://localhost:${toString constants.plex.port}";
                key = "{{HOMEPAGE_FILE_PLEX_TOKEN}}";
              };
            };
          }
          {
            Immich = {
              icon = "immich.svg";
              href = "https://${localMedia.immich.domain}";
              widget = {
                type = "immich";
                url = "http://localhost:${toString config.services.immich.port}";
                key = "{{HOMEPAGE_FILE_IMMICH_API_KEY}}";
                version = 2;
              };
            };
          }
        ];
      }
      {
        Arr = [
          {
            Seerr = {
              icon = "seerr.svg";
              href = "https://${localMedia.seerr.domain}";
              widget = {
                type = "seerr";
                url = "http://localhost:${toString config.services.seerr.port}";
                key = "{{HOMEPAGE_FILE_SEERR_API_KEY}}";
              };
            };
          }
          {
            Sonnar = {
              icon = "sonarr.svg";
              href = "https://${localMedia.sonarr.domain}";
              widget = {
                type = "sonarr";
                url = "http://localhost:${toString config.services.sonarr.settings.server.port}";
                key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.svg";
              href = "https://${localMedia.radarr.domain}";
              widget = {
                type = "radarr";
                url = "http://localhost:${toString config.services.radarr.settings.server.port}";
                key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.svg";
              href = "https://${localMedia.prowlarr.domain}";
              widget = {
                type = "prowlarr";
                url = "http://localhost:${toString config.services.prowlarr.settings.server.port}";
                key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
                fields = ["numberOfFailGrabs" "numberOfFailQueries"];
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr.svg";
              href = "https://${localMedia.bazarr.domain}";
              widget = {
                type = "bazarr";
                url = "http://localhost:${toString config.services.bazarr.listenPort}";
                key = "{{HOMEPAGE_FILE_BAZARR_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        Infrastructure = [
          {
            Gluetun = {
              icon = "gluetun.png";
              widget = {
                type = "gluetun";
                url = "http://localhost:8000";
                version = 2;
              };
            };
          }
          {
            AdGuard = {
              icon = "adguard-home.svg";
              href = "https://${localMedia.adguard.domain}";
            };
          }
          {
            Transmission = {
              icon = "transmission.svg";
              href = "https://${localMedia.transmission.domain}";
              widget = {
                type = "transmission";
                url = "http://localhost:${toString config.services.transmission.settings.rpc-port}";
                fields = ["download" "upload"];
              };
            };
          }
          {
            CoolerControl = {
              icon = "coolercontrol.png";
              href = "https://${localMedia.coolercontrol.domain}";
              widget = {
                type = "coolercontrol";
                url = "http://localhost:${toString constants.coolercontrol.port}";
              };
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          label = "System";
          cpu = true;
          memory = true;
        };
      }
      {
        resources = {
          label = "Storage";
          disk = ["/" constants.paths.mediaDir];
        };
      }
    ];
  };

  systemd.services.homepage-dashboard.serviceConfig = {
    User = "homepage-dashboard";
    Group = "homepage-dashboard";
  };

  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_FILE_PLEX_TOKEN = config.sops.secrets."homepage/plex_token".path;
    HOMEPAGE_FILE_SONARR_API_KEY = config.sops.secrets."homepage/sonarr_api_key".path;
    HOMEPAGE_FILE_RADARR_API_KEY = config.sops.secrets."homepage/radarr_api_key".path;
    HOMEPAGE_FILE_PROWLARR_API_KEY = config.sops.secrets."homepage/prowlarr_api_key".path;
    HOMEPAGE_FILE_BAZARR_API_KEY = config.sops.secrets."homepage/bazarr_api_key".path;
    HOMEPAGE_FILE_IMMICH_API_KEY = config.sops.secrets."homepage/immich_api_key".path;
    HOMEPAGE_FILE_SEERR_API_KEY = config.sops.secrets."homepage/seerr_api_key".path;
  };

  local.media.dashboard = {
    port = config.services.homepage-dashboard.listenPort;
    auth = true;
  };
}
