{
  config,
  pkgs,
  lib,
  ...
}: let
  constants = import ./constants.nix;
  databases = import ./databases.nix;
  allDatabases = builtins.concatMap (e: [e.name] ++ (e.extraDatabases or [])) databases;
in {
  sops.secrets."postgres/password" = {
    owner = constants.postgres.user;
  };

  # PgBouncer
  services.pgbouncer = {
    enable = true;
    settings = {
      pgbouncer = {
        listen_port = 5432;
        unix_socket_dir = "/run/pgbouncer";
        unix_socket_mode = "0770";

        auth_type = "hba";
        auth_hba_file = "/etc/pgbouncer/pg_hba.conf";
        auth_file = "/etc/pgbouncer/userlist.txt";

        pool_mode = "transaction";
        max_client_conn = 100;
        default_pool_size = 20;
      };
      databases = builtins.listToAttrs (
        map (dbname: {
          name = dbname;
          value = "host=/run/postgresql dbname=${dbname}";
        })
        allDatabases
      );
    };
  };

  # PgBouncer HBA: allow peer auth on local unix socket connections
  environment.etc."pgbouncer/pg_hba.conf" = {
    text = ''
      local all all peer
    '';
    mode = "0640";
    user = "pgbouncer";
    group = "pgbouncer";
  };

  # Auto-generate userlist.txt for peer auth
  environment.etc."pgbouncer/userlist.txt" = {
    text = lib.concatMapStringsSep "\n" (e: ''"${e.user}" ""'') databases;
    mode = "0640";
    user = "pgbouncer";
    group = "pgbouncer";
  };

  # PgBouncer depends on postgresql-setup (DBs and users must exist first)
  systemd.services.pgbouncer = {
    after = ["postgresql-setup.service"];
    requires = ["postgresql-setup.service"];
  };

  # Add service users to pgbouncer group for socket access
  users.groups.pgbouncer.members = map (e: e.user) databases;

  # PostgreSQL
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    initdbArgs = [
      "--auth-host=scram-sha-256"
      "--pwfile=${config.sops.secrets."postgres/password".path}"
    ];

    extensions = ps: [
      ps.pgvector
      ps.vectorchord
    ];
    settings = {
      shared_preload_libraries = ["vchord.so"];
      search_path = "\"$user\", public, vectors";
    };

    # ident map: allow pgbouncer OS user to connect as each service DB user
    identMap =
      lib.concatMapStringsSep "\n" (e: "pgbouncer_map pgbouncer ${e.user}") databases
      + "\n"
      + lib.concatMapStringsSep "\n" (e: "pgbouncer_map ${e.user} ${e.user}") databases
      + "\npgbouncer_map postgres postgres";

    authentication = pkgs.lib.mkForce ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     peer map=pgbouncer_map
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';

    # Auto-generate from service declarations
    ensureDatabases = allDatabases;
    ensureUsers =
      map (e: {
        name = e.user;
        ensureDBOwnership = true;
      })
      databases;
  };

  # Auto-generate ALTER OWNER for extraDatabases + custom setupScripts
  systemd.services.postgresql-setup.script = let
    ownershipScripts = lib.concatMapStringsSep "\n" (
      e:
        lib.concatMapStringsSep "\n" (db: ''psql -tAc "ALTER DATABASE \"${db}\" OWNER TO ${e.user}"'') (
          e.extraDatabases or []
        )
    ) (builtins.filter (e: (e.extraDatabases or []) != []) databases);
    customScripts = lib.concatMapStringsSep "\n" (e: e.setupScript or "") (
      builtins.filter (e: (e.setupScript or "") != "") databases
    );
  in
    lib.mkAfter (
      lib.concatStringsSep "\n" (
        builtins.filter (s: s != "") [
          ownershipScripts
          customScripts
        ]
      )
    );
}
