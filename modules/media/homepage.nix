{config, ...}: let
  cfg = config.mediaServer;
in {
  sops.secrets = {
    "homepage/sonarr_api_key" = {
      key = "sonarr_api_key";
      owner = "homepage-dashboard";
      group = "homepage-dashboard";
    };
    "homepage/radarr_api_key" = {
      key = "radarr_api_key";
      owner = "homepage-dashboard";
      group = "homepage-dashboard";
    };
    "homepage/prowlarr_api_key" = {
      key = "prowlarr_api_key";
      owner = "homepage-dashboard";
      group = "homepage-dashboard";
    };
    "homepage/bazarr_api_key" = {
      key = "bazarr_api_key";
      owner = "homepage-dashboard";
      group = "homepage-dashboard";
    };
    "homepage/plex_token" = {
      key = "plex_token";
      owner = "homepage-dashboard";
      group = "homepage-dashboard";
    };
  };

  users.users.homepage-dashboard = {
    isSystemUser = true;
    group = "homepage-dashboard";
  };
  users.groups.homepage-dashboard = {};

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "dashboard.${cfg.network.domain}";
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
              href = "https://plex.${cfg.network.domain}";
              widget = {
                type = "plex";
                url = "http://localhost:${toString cfg.plex.port}";
                key = "{{HOMEPAGE_FILE_PLEX_TOKEN}}";
              };
            };
          }
          {
            Jellyseerr = {
              icon = "jellyseerr.svg";
              href = "https://${cfg.network.domain}";
            };
          }
          {
            Sonnar = {
              icon = "sonarr.svg";
              href = "https://sonarr.${cfg.network.domain}";
              widget = {
                type = "sonarr";
                url = "http://localhost:${toString cfg.sonarr.port}";
                key = "{{HOMEPAGE_FILE_SONARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Radarr = {
              icon = "radarr.svg";
              href = "https://radarr.${cfg.network.domain}";
              widget = {
                type = "radarr";
                url = "http://localhost:${toString cfg.radarr.port}";
                key = "{{HOMEPAGE_FILE_RADARR_API_KEY}}";
                fields = ["wanted"];
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr.svg";
              href = "https://prowlarr.${cfg.network.domain}";
              widget = {
                type = "prowlarr";
                url = "http://localhost:${toString cfg.prowlarr.port}";
                key = "{{HOMEPAGE_FILE_PROWLARR_API_KEY}}";
                fields = ["numberOfFailGrabs" "numberOfFailQueries"];
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr.svg";
              href = "https://bazarr.${cfg.network.domain}";
              widget = {
                type = "bazarr";
                url = "http://localhost:${toString cfg.bazarr.port}";
                key = "{{HOMEPAGE_FILE_BAZARR_API_KEY}}";
              };
            };
          }
          {
            Transmission = {
              icon = "transmission.svg";
              href = "https://torrent.${cfg.network.domain}";
              widget = {
                type = "transmission";
                url = "http://localhost:${toString cfg.transmission.port}";
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
          disk = ["/" cfg.paths.mediaDir];
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
  };

  services.caddy.virtualHosts."dashboard.${cfg.network.domain}" = {
    extraConfig = ''
      import auth_proxy
      reverse_proxy localhost:${toString cfg.homepage.port}
    '';
  };
}
