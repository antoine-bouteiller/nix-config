{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchurl,
}: let
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version;
  sources = sourcesData.platforms;

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  binary = fetchurl {
    inherit (source) url hash;
  };
in
  stdenv.mkDerivation {
    pname = "sonarqube-cli";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      autoPatchelfHook
    ];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      install -m755 ${binary} $out/bin/sonar

      runHook postInstall
    '';

    dontStrip = true;

    passthru.updateScript = ./update.nu;

    meta = with lib; {
      inherit version;
      description = "SonarQube CLI for running local SonarQube scans";
      homepage = "https://docs.sonarsource.com/sonarqube-cli";
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "sonar";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      maintainers = [];
    };
  }
