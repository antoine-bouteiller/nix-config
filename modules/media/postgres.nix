{
  config,
  pkgs,
  ...
}: let
  user = "postgres";
  group = "postgres";
in {
  sops.secrets."postgres/password" = {
    owner = user;
    group = group;
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    initdbArgs = ["--auth-host=scram-sha-256" "--pwfile=${config.sops.secrets."postgres/password".path}"];

    extensions = ps: [
      ps.pgvector
      ps.vectorchord
    ];
    settings = {
      shared_preload_libraries = ["vchord.so"];
      search_path = "\"$user\", public, vectors";
    };

    authentication = pkgs.lib.mkForce ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     peer
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';
  };
}
