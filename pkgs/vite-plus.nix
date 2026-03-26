{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  nodejs,
}: let
  pname = "vite-plus";
  version = "0.1.14";

  systemMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64-gnu";
    "aarch64-linux" = "linux-arm64-gnu";
  };

  hashMap = {
    "aarch64-darwin" = "sha256-qBsGpfV4SUlWwa3DGU7OPswvL46bJB3uz9sbvl2ilG8=";
    "x86_64-darwin" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    "x86_64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    "aarch64-linux" = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  system = stdenvNoCC.hostPlatform.system;
  platform = systemMap.${system} or (throw "Unsupported system: ${system}");
  hash = hashMap.${system} or (throw "Unsupported system: ${system}");

  cliSrc = fetchurl {
    url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-${platform}/-/vite-plus-cli-${platform}-${version}.tgz";
    inherit hash;
  };

  vitePlusModules = stdenvNoCC.mkDerivation {
    name = "vite-plus-modules-${version}";
    nativeBuildInputs = [nodejs];
    dontUnpack = true;

    buildPhase = ''
      export HOME=$(mktemp -d)

      mkdir -p $out
      cd $out

      cat > package.json <<EOF
      {
        "name": "vp-env",
        "dependencies": {
          "vite-plus": "${version}"
        }
      }
      EOF

      npm install --silent
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-MJC2oYlFw2Bu8rQreG9OsLuH8CzztBS6o4q82aCx4NE=";
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version;
    src = cliSrc;

    nativeBuildInputs = lib.optionals stdenvNoCC.isLinux [
      autoPatchelfHook
    ];

    sourceRoot = "package";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      install -Dm755 vp $out/bin/vp

      ln -s ${vitePlusModules}/node_modules $out/node_modules

      runHook postInstall
    '';

    meta = {
      description = "Vite+ unified web development toolchain CLI";
      homepage = "https://viteplus.dev";
      platforms = builtins.attrNames systemMap;
      mainProgram = "vp";
    };
  }
