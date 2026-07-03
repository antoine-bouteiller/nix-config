{
  caddy,
  lib,
}: let
  sources = lib.importJSON ./sources.json;
  pkg =
    (caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v${sources.version}"
      ];
      inherit (sources) hash;
    })
    .overrideAttrs (_: {
      doInstallCheck = false;
    });
in
  pkg.overrideAttrs (old: {
    passthru =
      (old.passthru or {})
      // {
        updateScript = ./update.nu;
      };
  })
