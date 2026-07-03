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
    pname = "fff-mcp";
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
      install -m755 ${binary} $out/bin/fff-mcp

      runHook postInstall
    '';

    passthru.updateScript = ./update.nu;

    meta = with lib; {
      inherit version;
      description = "MCP server for fff, the fastest fuzzy file finder";
      homepage = "https://github.com/dmtrKovalenko/fff";
      license = licenses.mit;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "fff-mcp";
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    };
  }
