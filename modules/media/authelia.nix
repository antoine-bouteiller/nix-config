{config, ...}: let
  cfg = config.mediaServer;
  user = "authelia-main";
  group = "authelia-main";
in {
  sops.secrets = {
    "authelia/jwt_secret" = {
      owner = user;
      group = group;
    };
    "authelia/storage_encryption_key" = {
      owner = user;
      group = group;
    };
    "authelia/session_secret" = {
      owner = user;
      group = group;
    };
    "authelia/resend_api_key" = {
      owner = user;
      group = group;
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
        path = "${cfg.authelia.dataDir}/users.yml";
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
            domain = "*.${cfg.network.domain}";
            policy = "bypass";
            networks = ["internal"];
          }
          {
            domain = "*.${cfg.network.domain}";
            policy = "one_factor";
          }
        ];
      };

      session.cookies = [
        {
          name = "authelia_session";
          domain = cfg.network.domain;
          authelia_url = "https://auth.${cfg.network.domain}";
        }
      ];

      regulation = {
        max_retries = 3;
        find_time = "2 minutes";
        ban_time = "5 minutes";
      };

      storage.local.path = "${cfg.authelia.dataDir}/db.sqlite3";

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submissions://smtp.resend.com:465";
          username = "resend";
          sender = "authelia@${cfg.network.domain}";
        };
      };
    };
  };

  services.caddy.virtualHosts."auth.${cfg.network.domain}" = {
    extraConfig = "reverse_proxy localhost:${toString cfg.authelia.port}";
  };
}
