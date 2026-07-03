{
  lib,
  stdenvNoCC,
  whitesur-icon-theme,
  jdupes,
  overlay,
}: let
  base = whitesur-icon-theme.override {alternativeIcons = true;};
in
  stdenvNoCC.mkDerivation {
    pname = "whitesur-icon-theme";
    inherit (base) version;

    dontUnpack = true;
    nativeBuildInputs = [jdupes];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share
      cp -a ${base}/share/icons $out/share/
      chmod -R u+w $out/share/icons/WhiteSur

      (cd ${overlay} && find . -type f -print0) | while IFS= read -r -d "" rel; do
        dst="$out/share/icons/WhiteSur/''${rel#./}"
        mkdir -p "$(dirname "$dst")"
        rm -f "$dst"
        cp "${overlay}/$rel" "$dst"
        chmod u+rw "$dst"
      done

      find $out/share/icons/WhiteSur -xtype l -delete
      jdupes --link-soft --recurse $out/share/icons/WhiteSur

      runHook postInstall
    '';

    dontPatchELF = true;
    dontRewriteSymlinks = true;
    dontDropIconThemeCache = true;

    meta = with lib; {
      description = "WhiteSure-alt icon theme (Vince Liuice) with local overlay";
      homepage = "https://github.com/vinceliuice/WhiteSur-icon-theme";
      license = licenses.gpl3Only;
      platforms = platforms.all;
    };
  }
