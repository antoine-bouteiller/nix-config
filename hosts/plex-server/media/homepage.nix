{config, ...}: let
  constants = import ./constants.nix;
  # Internal services are reached over Tailscale and resolved by AdGuard Home.
  localUrl = name: port: "http://${name}.${constants.network.localDomain}:${toString port}";
  plexUrl = "${localUrl "plex" constants.plex.port}/web";
  adguardUrl = localUrl "adguard" config.services.adguardhome.port;
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
    allowedHosts = "dashboard.${constants.network.localDomain}:${toString constants.homepage.port}";
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
              href = plexUrl;
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
              href = "https://photo.${constants.network.domain}";
              widget = {
                type = "immich";
                url = "http://localhost:${toString constants.immich.port}";
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
              href = "https://${constants.network.domain}";
              widget = {
                type = "seerr";
                url = "http://localhost:${toString constants.seerr.port}";
                key = "{{HOMEPAGE_FILE_SEERR_API_KEY}}";
              };
            };
          }
          {
            Sonnar = {
              icon = "sonarr.svg";
              href = localUrl "sonarr" constants.sonarr.port;
              widget = {
                type = "sonarr";
                url = "http://localhost:${toString constants.sonarr.port}";
                key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.svg";
              href = localUrl "radarr" constants.radarr.port;
              widget = {
                type = "radarr";
                url = "http://localhost:${toString constants.radarr.port}";
                key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.svg";
              href = localUrl "prowlarr" constants.prowlarr.port;
              widget = {
                type = "prowlarr";
                url = "http://localhost:${toString constants.prowlarr.port}";
                key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
                fields = ["numberOfFailGrabs" "numberOfFailQueries"];
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr.svg";
              href = localUrl "bazarr" constants.bazarr.port;
              widget = {
                type = "bazarr";
                url = "http://localhost:${toString constants.bazarr.port}";
                key = "{{HOMEPAGE_FILE_BAZARR_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        Infrastructure = [
          {
            AdGuard = {
              icon = "adguard-home.svg";
              href = adguardUrl;
            };
          }
          {
            Transmission = {
              icon = "transmission.svg";
              href = localUrl "transmission" constants.transmission.port;
              widget = {
                type = "transmission";
                url = "http://localhost:${toString constants.transmission.port}";
                fields = ["download" "upload"];
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
}
