{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  qt6,
  bluez,
  curl,
  openssl,
  qrencode,
  sdbus-cpp_2,
  systemd,
  nix-update,
  writeShellScript,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "nearby-file-share";
  version = "0.1-beta-3";

  src = fetchurl {
    url = "https://github.com/kidfromjupiter/nearby/releases/download/v${finalAttrs.version}/nearby-file-share-linux-x86_64.tar.gz";
    hash = "sha256-/yjPz0GGkxHlQyvymxfM7jiiC8ZL9KXGQc1jEXsNIDU=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    bluez
    curl
    openssl
    qrencode
    qt6.qtbase
    qt6.qtdeclarative
    sdbus-cpp_2
    systemd
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/nearby_qml_file_tray_app -t $out/bin
    install -Dm755 lib/libnearby_sharing_api_shared.so -t $out/lib
    install -Dm644 include/sharing/linux/nearby_sharing_api.h -t $out/include/sharing/linux
    install -Dm644 share/icons/hicolor/256x256/apps/nearby-file-share.png \
      -t $out/share/icons/hicolor/256x256/apps

    install -Dm644 share/applications/nearby-file-share.desktop \
      $out/share/applications/nearby-file-share.desktop
    substituteInPlace $out/share/applications/nearby-file-share.desktop \
      --replace-fail 'Exec=nearby_qml_file_tray_app' "Exec=$out/bin/nearby_qml_file_tray_app"

    runHook postInstall
  '';

  passthru.updateScript = writeShellScript "${finalAttrs.pname}-update" ''
    exec ${nix-update}/bin/nix-update --flake \
      --version=unstable \
      --version-regex 'v(\d+\.\d+-beta-\d+)'
  '';

  meta = {
    description = "Linux implementation of Google Nearby Connections, Nearby Presence, Fast Pair, and Quick Share";
    homepage = "https://github.com/kidfromjupiter/nearby";
    license = lib.licenses.asl20;
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    mainProgram = "nearby_qml_file_tray_app";
  };
})
