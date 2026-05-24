{config, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  sops.secrets = {
    "authelia/jwt_secret" = {
      owner = constants.authelia.user;
    };
    "authelia/storage_encryption_key" = {
      owner = constants.authelia.user;
    };
    "authelia/session_secret" = {
      owner = constants.authelia.user;
    };
    "authelia/resend_api_key" = {
      owner = constants.authelia.user;
    };
  };

  services.authelia.instances.main = {
    enable = true;

    secrets = {
      storageEncryptionKeyFile = config.sops.secrets."authelia/storage_encryption_key".path;
      sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
      jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
    };

    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets."authelia/resend_api_key".path;
    };

    settings = {
      theme = "dark";

      server.endpoints.authz.forward-auth.implementation = "ForwardAuth";

      identity_validation.reset_password = {
        jwt_lifespan = "5 minutes";
        jwt_algorithm = "HS256";
      };

      authentication_backend.file = {
        path = "${constants.authelia.dataDir}/users.yml";
        password.algorithm = "argon2";
      };

      password_policy.zxcvbn = {
        enabled = true;
        min_score = 3;
      };

      access_control = {
        default_policy = "deny";

        networks = [
          {
            name = "internal";
            networks = [
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/18"
            ];
          }
        ];

        rules = [
          {
            domain = "*.${constants.network.domain}";
            policy = "bypass";
            networks = ["internal"];
          }
          {
            domain = "*.${constants.network.domain}";
            policy = "one_factor";
          }
        ];
      };

      session.cookies = [
        {
          name = "authelia_session";
          domain = constants.network.domain;
          authelia_url = "https://auth.${constants.network.domain}";
        }
      ];

      regulation = {
        max_retries = 3;
        find_time = "2 minutes";
        ban_time = "5 minutes";
      };

      log.level = "info";

      storage.local.path = "${constants.authelia.dataDir}/db.sqlite3";

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submissions://smtp.resend.com:465";
          username = "resend";
          sender = "authelia@${constants.network.domain}";
        };
      };
    };
  };

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = "auth.${constants.network.domain}";
    port = constants.authelia.port;
  };
}
