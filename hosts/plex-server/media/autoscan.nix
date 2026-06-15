{config, ...}: let
  constants = import ./constants.nix;
in {
  services.autoscan = {
    enable = true;
    dataDir = constants.autoscan.dataDir;
    port = 3030;
    group = constants.libraryOwner.group;

    settings = {
      plexUrl = "http://localhost:${toString constants.plex.port}";
      domain = constants.network.domain;
      tmdbApiUrl = "https://api.themoviedb.org/3";
      sonarrApiUrl = "http://localhost:${toString config.services.sonarr.settings.server.port}";
      radarrApiUrl = "http://localhost:${toString config.services.radarr.settings.server.port}";
      transcodePath = "${constants.paths.mediaDir}/transcode";
      postgres = {
        host = "/run/pgbouncer";
        port = 5432;
        user = "autoscan";
        database = "autoscan";
      };
    };
    secrets = {
      plexTokenFile = config.sops.secrets."autoscan/plex_token".path;
      telegramTokenFile = config.sops.secrets."autoscan/telegram_token".path;
      telegramChatIdFile = config.sops.secrets."autoscan/telegram_chat_id".path;
      tmdbApiTokenFile = config.sops.secrets."autoscan/tmdb_api_token".path;
      sonarrApiKeyFile = config.sops.secrets."autoscan/sonarr_api_key".path;
      radarrApiKeyFile = config.sops.secrets."autoscan/radarr_api_key".path;
      traktClientIdFile = config.sops.secrets."autoscan/trakt_client_id".path;
      traktClientSecretFile = config.sops.secrets."autoscan/trakt_client_secret".path;
    };
  };

  systemd.services.autoscan = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
  };

  sops.secrets."autoscan/plex_token" = {
    key = "plex_token";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/telegram_token" = {
    key = "telegram/token";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/telegram_chat_id" = {
    key = "telegram/chat_id";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/tmdb_api_token" = {
    key = "tmdb_api_token";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/sonarr_api_key" = {
    key = "sonarr_api_key";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/radarr_api_key" = {
    key = "radarr_api_key";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/trakt_client_id" = {
    key = "trakt/client_id";
    owner = constants.autoscan.user;
  };
  sops.secrets."autoscan/trakt_client_secret" = {
    key = "trakt/client_secret";
    owner = constants.autoscan.user;
  };
}
