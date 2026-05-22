{config, ...}: let
  constants = import ./constants.nix;
  # Internal services are reached over Tailscale and resolved by AdGuard Home.
  localUrl = name: port: "http://${name}.${constants.network.localDomain}:${toString port}";
  plexUrl = "${localUrl "plex" constants.plex.port}/web";
  plexWidgetUrl = "http://localhost:${toString constants.plex.port}";
  adguardUrl = localUrl "adguard" config.services.adguardhome.port;
  immichUrl = "http://localhost:${toString config.services.immich.port}";
  seerrUrl = "http://localhost:${toString config.services.seerr.port}";
  sonarrUrl = "http://localhost:${toString config.services.sonarr.settings.server.port}";
  radarrUrl = "http://localhost:${toString config.services.radarr.settings.server.port}";
  prowlarrUrl = "http://localhost:${toString config.services.prowlarr.settings.server.port}";
  bazarrUrl = "http://localhost:${toString config.services.bazarr.listenPort}";
  transmissionUrl = "http://localhost:${toString config.services.transmission.settings.rpc-port}";
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
    allowedHosts = "dashboard.${constants.network.localDomain}:${toString config.services.homepage-dashboard.listenPort}";
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
                url = plexWidgetUrl;
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
                url = immichUrl;
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
                url = seerrUrl;
                key = "{{HOMEPAGE_FILE_SEERR_API_KEY}}";
              };
            };
          }
          {
            Sonnar = {
              icon = "sonarr.svg";
              href = localUrl "sonarr" config.services.sonarr.settings.server.port;
              widget = {
                type = "sonarr";
                url = sonarrUrl;
                key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.svg";
              href = localUrl "radarr" config.services.radarr.settings.server.port;
              widget = {
                type = "radarr";
                url = radarrUrl;
                key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.svg";
              href = localUrl "prowlarr" config.services.prowlarr.settings.server.port;
              widget = {
                type = "prowlarr";
                url = prowlarrUrl;
                key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
                fields = ["numberOfFailGrabs" "numberOfFailQueries"];
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr.svg";
              href = localUrl "bazarr" config.services.bazarr.listenPort;
              widget = {
                type = "bazarr";
                url = bazarrUrl;
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
              href = localUrl "transmission" config.services.transmission.settings.rpc-port;
              widget = {
                type = "transmission";
                url = transmissionUrl;
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
