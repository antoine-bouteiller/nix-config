{
  lib,
  retroarch,
  libretro,
  fetchzip,
  autoPatchelfHook,
  stdenv,
}: let
  sources = lib.importJSON ./sources.json;

  # Prebuilt libretro core from Azahar's GitHub release (compiling the 3DS
  # emulator from source is huge; the release ships a ready-made .so).
  azaharCore = libretro.mkLibretroCore {
    core = "azahar";
    inherit (sources) version;

    src = fetchzip {
      url = "https://github.com/azahar-emu/azahar/releases/download/${sources.version}/azahar-libretro-linux-x86_64-${sources.version}.zip";
      inherit (sources) hash;
      stripRoot = false;
    };

    # Release ships the .so directly; just patch it for NixOS and install.
    dontBuild = true;
    extraNativeBuildInputs = [autoPatchelfHook];
    extraBuildInputs = [stdenv.cc.cc.lib];

    meta = {
      description = "Azahar 3DS emulator libretro core (prebuilt release)";
      homepage = "https://github.com/azahar-emu/azahar";
      license = lib.licenses.gpl2Plus;
    };
  };
in
  (retroarch.withCores (_: [azaharCore])).overrideAttrs (old: {
    passthru =
      (old.passthru or {})
      // {
        updateScript = ./update.nu;
      };
  })
