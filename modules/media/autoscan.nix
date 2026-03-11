{config, ...}: let
  cfg = config.mediaServer;
in {
  users.users.autoscan.extraGroups = [cfg.libraryOwner.group];

  services.autoscan = {
    enable = true;
    dataDir = cfg.autoscan.dataDir;
    port = cfg.autoscan.port;

    settings = {
      plexUrl = "http://localhost:${toString cfg.plex.port}";
      domain = cfg.network.domain;
      tmdbApiUrl = "https://api.themoviedb.org/3";
      sonarrApiUrl = "http://localhost:${toString cfg.sonarr.port}";
      radarrApiUrl = "http://localhost:${toString cfg.radarr.port}";
      transcodePath = "${cfg.paths.mediaDir}/transcode";
    };
    secrets = {
      plexTokenFile = config.sops.secrets."autoscan/plex_token".path;
      telegramTokenFile = config.sops.secrets."autoscan/telegram_token".path;
      telegramChatIdFile = config.sops.secrets."autoscan/telegram_chat_id".path;
      cloudflareTokenFile = config.sops.secrets."autoscan/cloudflare_token".path;
      tmdbApiTokenFile = config.sops.secrets."autoscan/tmdb_api_token".path;
      sonarrApiKeyFile = config.sops.secrets."autoscan/sonarr_api_key".path;
      radarrApiKeyFile = config.sops.secrets."autoscan/radarr_api_key".path;
      traktClientIdFile = config.sops.secrets."autoscan/trakt_client_id".path;
      traktClientSecretFile = config.sops.secrets."autoscan/trakt_client_secret".path;
    };
  };

  sops.secrets."autoscan/plex_token" = {
    key = "plex_token";
    owner = cfg.autoscan.user;
  };
  sops.secrets."autoscan/telegram_token" = {
    key = "telegram/token";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/telegram_chat_id" = {
    key = "telegram/chat_id";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/cloudflare_token" = {
    key = "cloudflare_token";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/tmdb_api_token" = {
    key = "tmdb_api_token";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/sonarr_api_key" = {
    key = "sonarr_api_key";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/radarr_api_key" = {
    key = "radarr_api_key";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/trakt_client_id" = {
    key = "trakt/client_id";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
  sops.secrets."autoscan/trakt_client_secret" = {
    key = "trakt/client_secret";
    owner = cfg.autoscan.user;
    group = cfg.autoscan.group;
  };
}
