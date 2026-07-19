{
  lib,
  appimageTools,
  fetchurl,
  runCommand,
  patchelf,
  stdenv,
}: let
  sourcesData = lib.importJSON ./sources.json;
  inherit (sourcesData) version;

  source =
    sourcesData.platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  pname = "neostation";

  src = fetchurl {
    url = "https://github.com/misobadev/neostation-frontend/releases/download/v${version}/neostation-linux-${source.arch}-${version}.AppImage";
    inherit (source) hash;
  };

  raw = appimageTools.extractType2 {inherit pname version src;};

  # The app stores its data in `$PWD/user-data`, and the stock AppRun cd's to its
  # own (now read-only /nix/store) dir before launching — so first run throws
  # trying to create that directory. Redirect CWD to a writable per-user dir and
  # exec the binary by absolute path (its $ORIGIN/lib RUNPATH is CWD-independent).
  contents =
    runCommand "${pname}-${version}-contents" {nativeBuildInputs = [patchelf];}
    ''
      cp -r ${raw} $out
      chmod -R u+w $out
      substituteInPlace $out/AppRun \
        --replace-fail 'cd "''${HERE}/usr/bin"' \
          '_d="''${XDG_DATA_HOME:-$HOME/.local/share}/neostation"; mkdir -p "$_d"; cd "$_d"' \
        --replace-fail 'exec ./neostation "$@"' \
          'exec "''${HERE}/usr/bin/neostation" "$@"'

      # Every Flutter plugin ships a dead CI-absolute RUNPATH (/home/runner/...),
      # so their bundled deps (sibling plugins, libvorbis, libstdc++) don't
      # resolve. Rewrite each RUNPATH to the real bundle dirs. Doing this here —
      # instead of a global LD_LIBRARY_PATH — is what keeps launched emulators
      # (azahar) from inheriting neostation's older libstdc++/libvorbis and
      # crashing the game on start.
      for so in $out/usr/bin/lib/*.so*; do
        [ -f "$so" ] && [ ! -L "$so" ] && patchelf --set-rpath '$ORIGIN:$ORIGIN/../../lib' "$so"
      done
      for so in $out/usr/lib/*.so*; do
        [ -f "$so" ] && [ ! -L "$so" ] && patchelf --set-rpath '$ORIGIN:$ORIGIN/../bin/lib' "$so"
      done
    '';
in
  # Flutter app shipped as a prebuilt AppImage. wrapAppImage runs it in the
  # standard AppImage FHS sandbox; extraInstallCommands adds the .desktop + icon.
  appimageTools.wrapAppImage {
    inherit pname version;
    src = contents;

    # System libs the FHS sandbox lacks (most others ship bundled in the AppImage).
    extraPkgs = pkgs: with pkgs; [libepoxy lz4];

    extraInstallCommands = ''
      install -Dm444 ${raw}/${pname}.desktop -t $out/share/applications
      install -Dm444 ${raw}/${pname}.png $out/share/icons/hicolor/512x512/apps/${pname}.png
    '';

    passthru.updateScript = ./update.nu;

    meta = {
      description = "Multiplatform retro-emulation frontend (Flutter)";
      homepage = "https://github.com/misobadev/neostation-frontend";
      license = lib.licenses.gpl3Only;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
      platforms = ["x86_64-linux" "aarch64-linux"];
      maintainers = [];
    };
  }
