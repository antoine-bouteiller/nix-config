{
  pkgs,
  inputs,
  config,
  ...
}: let
  cfg = config.mediaServer;
  ygegePkg = pkgs.rustPlatform.buildRustPackage {
    pname = "ygege";
    version = "unstable-${inputs.ygege.shortRev or "dirty"}";
    src = inputs.ygege;
    cargoLock.lockFile = "${inputs.ygege}/Cargo.lock";

    nativeBuildInputs = with pkgs; [
      pkg-config
      cmake
      perl
    ];

    buildInputs = with pkgs; [
      openssl
    ];

    env.LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
  };

  definitionFile = "${inputs.ygege}/ygege.yml";
  definitionsDir = "${cfg.prowlarr.dataDir}/Definitions/Custom";
in {
  systemd.services.ygege = {
    description = "Ygege indexer proxy";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${ygegePkg}/bin/ygege";
      DynamicUser = true;
      StateDirectory = "ygege";
      WorkingDirectory = "/var/lib/ygege";
      Restart = "on-failure";
      RestartSec = 5;
    };

    environment = {
      BIND_IP = "127.0.0.1";
      BIND_PORT = toString cfg.ygege.port;
      LOG_LEVEL = "info";
    };
  };

  systemd.services.prowlarr = {
    preStart = ''
      mkdir -p ${definitionsDir}
      ln -sf ${definitionFile} ${definitionsDir}/ygege.yml
    '';
  };
}
